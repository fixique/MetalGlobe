//
//  SphereViewController.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 10.09.2018.
//  Copyright © 2018 fixique. All rights reserved.
//

import UIKit

final class SphereViewController: MainSceneViewController {

    // MARK: - Constants

    private struct Constants {
        static let fragmentSphereName = "fragment_sphere"
        static let vertexSphereName = "vertex_sphere"
    }

    // MARK: - Private Properties

    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var depthTexture: MTLTexture?
    private var rotationAngle: Float32 = 0.0

    // MARK: - MainScreenViewController

    override func buildPipeLine() {
        let library = device?.makeDefaultLibrary()
        let fragmentFunction = library?.makeFunction(name: Constants.fragmentSphereName)
        let vertexFunction = library?.makeFunction(name: Constants.vertexSphereName)
        let vertexDescriptor = getVertexDescriptor()

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

        commandQueue = device?.makeCommandQueue()
    }

    override func buildResources() {
        guard let device = device else { return }
        let (vertexBuffer, indexBuffer) = SphereGenerator.sphereWithRadius(1, stacks: 30, slices: 30, device: device)
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Matrix4x4>.size * 2, options: [])
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

        modelViewMatrix.W.z = -5

        let aspect = Float32(drawableSize.width) / Float32(drawableSize.height)

        let projectionMatrix = Matrix4x4.perspeciveProjection(aspect, fieldOfViewY: 60, near: 0.1, far: 100.0)

        let matrices = [projectionMatrix, modelViewMatrix]
        memcpy(uniformBuffer?.contents(), matrices, MemoryLayout<Matrix4x4>.size * 2)

        let commandBuffer = commandQueue?.makeCommandBuffer()

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
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
        commandEncoder?.setDepthStencilState(makeDepthStencilState())
        commandEncoder?.setFrontFacing(.counterClockwise)
        commandEncoder?.setCullMode(.back)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        commandEncoder?.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indexCount,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
        commandEncoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()

        rotationAngle += 0.01
    }
}
