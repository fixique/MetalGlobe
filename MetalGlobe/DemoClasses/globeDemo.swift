//
//  globeDemo.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 06.04.17.
//  Copyright © 2017 fixique. All rights reserved.
//

import UIKit
import Metal

class globeDemo: ViewController {
    var depthStencilState: MTLDepthStencilState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var indexBuffer: MTLBuffer! = nil
    var uniformBuffer: MTLBuffer! = nil
    var depthTexture: MTLTexture! = nil
    
    var diffuseTexture: MTLTexture! = nil
    var samplerState: MTLSamplerState! = nil
    var rotationAngle: Float32 = 0
    
    func textureForImage(_ image:UIImage, device:MTLDevice) -> MTLTexture? {
        let imageRef = image.cgImage!
        
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
        
        texture.replace(region: region,
                        mipmapLevel: 0,
                        slice: 0,
                        withBytes: rawData!,
                        bytesPerRow: bytesPerRow,
                        bytesPerImage: bytesPerRow * height)
        
        free(rawData)
        
        return texture
    }
    
    override func buildPipeLine() {
        let library = device.newDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_globe")
        let fragmentFunction = library.makeFunction(name: "fragment_globe")
        
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
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let error: NSErrorPointer? = nil
        pipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        if (pipeline == nil) {
            print("Error occurred when creating pipeline \(error)")
        }
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        commandQueue = device.makeCommandQueue()
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    override func buildResources() {
        let (vertexBuffer, indexBuffer) = SphereGenerator.sphereWithRadius(1, stacks: 30, slices: 30, device: device)
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Matrix4x4>.size * 2, options: [])
        
        diffuseTexture = self.textureForImage(UIImage(named: "earth")!, device: device)
    }
    
    override func resize() {
        super.resize()
        
        let layerSize = metalLayer.drawableSize
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                              width: Int(layerSize.width),
                                                                              height: Int(layerSize.height),
                                                                              mipmapped: false)
        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
    }
    
    override func draw() {
        if let drawable = metalLayer.nextDrawable() {
            let yAxis = Vector4(x: 0, y: -1, z: 0, w: 0)
            var modelViewMatrix = Matrix4x4.rotationAboutAxis(yAxis, byAngle: rotationAngle)
            
            modelViewMatrix.W.z = -3
            
            let aspect = Float32(metalLayer.drawableSize.width) / Float32(metalLayer.drawableSize.height)
            
            let projectionMatrix = Matrix4x4.perspeciveProjection(aspect, fieldOfViewY: 60, near: 0.1, far: 100.0)
            
            let matrices = [projectionMatrix, modelViewMatrix]
            memcpy(uniformBuffer.contents(), matrices, Int(MemoryLayout<Matrix4x4>.size * 2))
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
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
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
            if userToggle {
                commandEncoder.setTriangleFillMode(.lines)
            }
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setDepthStencilState(depthStencilState)
            commandEncoder.setFrontFacing(.counterClockwise)
            commandEncoder.setCullMode(.back)
            commandEncoder.setVertexBuffer(vertexBuffer, offset:0, at:0)
            commandEncoder.setVertexBuffer(uniformBuffer, offset:0, at:1)
            commandEncoder.setFragmentTexture(diffuseTexture, at: 0)
            commandEncoder.setFragmentSamplerState(samplerState, at: 0)
            
            commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                 indexCount:indexCount,
                                                 indexType:.uint16,
                                                 indexBuffer:indexBuffer,
                                                 indexBufferOffset: 0)
            
            commandEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
            rotationAngle += 0.01
        }
    }
}
