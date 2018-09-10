//
//  GlobeViewController.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 10.09.2018.
//  Copyright © 2018 fixique. All rights reserved.
//

import UIKit
import Metal

final class GlobeViewController: MainSceneViewController {

    // MARK: - Constants

    private struct Constants {
        static let vertexGlobeName = "vertex_globe"
        static let fragmentGlobeName = "fragment_globe"
    }

    // MARK: - Private properties

    private var depthStencilState: MTLDepthStencilState?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var depthTexture: MTLTexture?

    private var diffuseTexture: MTLTexture?
    private var samplerState: MTLSamplerState?
    private var rotationAngle: Float32 = 0

    // MARK: - MainSceneViewController

    override func buildPipeLine() {
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: Constants.vertexGlobeName)
        let fragmentFunction = library?.makeFunction(name: Constants.fragmentGlobeName)
        let vertexDescriptor = makeVertexDescriptor()

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        guard let internalPipeline = try? device?.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            print("Error occurred when creating pipeline")
            return
        }
        pipeline = internalPipeline
        makeDepthStencilDescriptor()
        commandQueue = device?.makeCommandQueue()
        makeSemplerDescriptor()
    }

    override func buildResources() {
        guard let device = device, let earthTexture = UIImage(named: "earth") else { return }
        let (vertexBuffer, indexBuffer) = SphereGenerator.sphereWithRadius(1, stacks: 30, slices: 30, device: device)
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer

        uniformBuffer = device.makeBuffer(length: MemoryLayout<Matrix4x4>.size * 2, options: [])
        diffuseTexture = textureForImage(earthTexture, device: device)
    }

    override func resize() {
        super.resize()
        guard let layerSize = metalLayer?.drawableSize else { return }
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                              width: Int(layerSize.width),
                                                                              height: Int(layerSize.height),
                                                                              mipmapped: false)
        depthTextureDescriptor.usage = MTLTextureUsage.renderTarget
        depthTexture = device?.makeTexture(descriptor: depthTextureDescriptor)
    }

    override func draw() {
        guard let drawable = metalLayer?.nextDrawable(),
            let drawableSize = metalLayer?.drawableSize,
            let indexBuffer = indexBuffer,
            let pipeline = pipeline else { return }

        let yAxis = Vector4(x: 0, y: -1, z: 0, w: 0)
        var modelViewMatrix = Matrix4x4.rotationAboutAxis(yAxis, byAngle: rotationAngle)
        modelViewMatrix.W.z = -3

        let aspect = Float32(drawableSize.width) / Float32(drawableSize.height)

        let projectionMatrix = Matrix4x4.perspeciveProjection(aspect, fieldOfViewY: 60, near: 0.1, far: 100.0)

        let matrices = [projectionMatrix, modelViewMatrix]
        memcpy(uniformBuffer?.contents(), matrices, Int(MemoryLayout<Matrix4x4>.size * 2))

        let commandBuffer = commandQueue?.makeCommandBuffer()

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.05, 0.05, 0.05, 1)
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store

        passDescriptor.depthAttachment.texture = depthTexture
        passDescriptor.depthAttachment.clearDepth = 1
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .dontCare

        let indexCount = indexBuffer.length / MemoryLayout<UInt16>.size
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        if userToggle {
            commandEncoder?.setTriangleFillMode(.lines)
        }
        commandEncoder?.setRenderPipelineState(pipeline)
        commandEncoder?.setDepthStencilState(depthStencilState)
        commandEncoder?.setFrontFacing(.counterClockwise)
        commandEncoder?.setCullMode(.back)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset:0, index:0)
        commandEncoder?.setVertexBuffer(uniformBuffer, offset:0, index:1)
        commandEncoder?.setFragmentTexture(diffuseTexture, index: 0)
        commandEncoder?.setFragmentSamplerState(samplerState, index: 0)

        commandEncoder?.drawIndexedPrimitives(type: .triangle,
                                             indexCount:indexCount,
                                             indexType:.uint16,
                                             indexBuffer:indexBuffer,
                                             indexBufferOffset: 0)

        commandEncoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()

        rotationAngle += 0.01
    }
}

// MARK: - Help Methods

private extension GlobeViewController {

    func textureForImage(_ image:UIImage, device:MTLDevice) -> MTLTexture? {
        guard let imageRef = image.cgImage else { return nil }

        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.size)

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let options = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let context = CGContext(data: rawData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: options)

        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: Int(width),
                                                                         height: Int(height),
                                                                         mipmapped: true)
        let texture = device.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake2D(0, 0, Int(width), Int(height))

        texture?.replace(region: region,
                        mipmapLevel: 0,
                        slice: 0,
                        withBytes: rawData!,
                        bytesPerRow: bytesPerRow,
                        bytesPerImage: bytesPerRow * height)

        free(rawData)

        return texture
    }

    func makeVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].offset = MemoryLayout<Float32>.size * 4
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].offset = MemoryLayout<Float32>.size * 8
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.size
        return vertexDescriptor
    }

    func makeDepthStencilDescriptor() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device?.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }

    func makeSemplerDescriptor() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerState = device?.makeSamplerState(descriptor: samplerDescriptor)
    }

}
