////
////  sphereDemo.swift
////  MetalGlobe
////
////  Created by Vlad Krupenko on 06.04.17.
////  Copyright © 2017 fixique. All rights reserved.
////
//
//import UIKit
//
//class sphereDemo: ViewController {
//
//    var depthStencilState: MTLDepthStencilState! = nil
//    var vertexBuffer: MTLBuffer! = nil
//    var indexBuffer: MTLBuffer! = nil
//    var uniformBuffer: MTLBuffer! = nil
//    var depthTexture: MTLTexture! = nil
//    var rotationAngle: Float32 = 0
//
//    override func buildPipeLine() {
//
//        let library = device.newDefaultLibrary()!
//        let fragmentFunction = library.makeFunction(name: "fragment_sphere")
//        let vertexFunction = library.makeFunction(name: "vertex_sphere")
//
//        let vertexDescriptor = MTLVertexDescriptor()
//        vertexDescriptor.attributes[0].offset = 0
//        vertexDescriptor.attributes[0].format = .float4
//        vertexDescriptor.attributes[0].bufferIndex = 0
//
//        vertexDescriptor.attributes[1].offset = MemoryLayout<Float32>.size * 4
//        vertexDescriptor.attributes[1].format = .float4
//        vertexDescriptor.attributes[1].bufferIndex = 0
//
//        vertexDescriptor.attributes[2].offset = MemoryLayout<Float32>.size * 8
//        vertexDescriptor.attributes[2].format = .float2
//        vertexDescriptor.attributes[2].bufferIndex = 0
//
//        vertexDescriptor.layouts[0].stepFunction = .perVertex
//        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.size
//
//        let pipelineDescriptor = MTLRenderPipelineDescriptor()
//        pipelineDescriptor.vertexFunction = vertexFunction
//        pipelineDescriptor.vertexDescriptor = vertexDescriptor
//        pipelineDescriptor.fragmentFunction = fragmentFunction
//        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
//
//        let error: NSErrorPointer? = nil
//        pipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
//        if (pipeline == nil) {
//            print("Error occurred when creating pipeline \(error)")
//        }
//
//
//
//        commandQueue = device.makeCommandQueue()
//
//
//    }
//
//    override func buildResources() {
//        let (vertexBuffer, indexBuffer) = SphereGenerator.sphereWithRadius(1, stacks: 30, slices: 30, device: device)
//        self.vertexBuffer = vertexBuffer
//        self.indexBuffer = indexBuffer
//        uniformBuffer = device.makeBuffer(length: MemoryLayout<Matrix4x4>.size * 2, options: [])
//    }
//
//    override func resize() {
//        super.resize()
//
//        let layerSize = metalLayer.drawableSize
//        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
//                                                                              width: Int(layerSize.width),
//                                                                              height: Int(layerSize.height),
//                                                                              mipmapped: false)
//        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
//    }
//
//    override func draw() {
//        if let drawable = metalLayer.nextDrawable() {
//            let yAxis = Vector4(x: 0, y: -1, z: 0, w: 0)
//            var modelViewMatrix = Matrix4x4.rotationAboutAxis(yAxis, byAngle: rotationAngle)
//
//            modelViewMatrix.W.z = -5
//
//            let aspect = Float32(metalLayer.drawableSize.width) / Float32(metalLayer.drawableSize.height)
//
//            let projectionMatrix = Matrix4x4.perspeciveProjection(aspect, fieldOfViewY: 60, near: 0.1, far: 100.0)
//
//            let matrices = [projectionMatrix, modelViewMatrix]
//            memcpy(uniformBuffer.contents(), matrices, MemoryLayout<Matrix4x4>.size * 2)
//
//            let commandBuffer = commandQueue.makeCommandBuffer()
//
//            let passDescriptor = MTLRenderPassDescriptor()
//            passDescriptor.colorAttachments[0].texture = drawable.texture
//            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
//            passDescriptor.colorAttachments[0].loadAction = .clear
//            passDescriptor.colorAttachments[0].storeAction = .store
//
//            passDescriptor.depthAttachment.texture = depthTexture
//            passDescriptor.depthAttachment.clearDepth = 1
//            passDescriptor.depthAttachment.loadAction = .clear
//            passDescriptor.depthAttachment.storeAction = .dontCare
//
//            let indexCount = indexBuffer.length / MemoryLayout<UInt16>.size
//            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
//
//            if userToggle {
//                commandEncoder.setTriangleFillMode(.lines)
//            }
//
//            commandEncoder.setRenderPipelineState(pipeline)
//            commandEncoder.setDepthStencilState(depthStencilState)
//            commandEncoder.setFrontFacing(.counterClockwise)
//            commandEncoder.setCullMode(.back)
//            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
//            commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
//            commandEncoder.drawIndexedPrimitives(type: .triangle,
//                                                 indexCount: indexCount,
//                                                 indexType: .uint16,
//                                                 indexBuffer: indexBuffer,
//                                                 indexBufferOffset: 0)
//            commandEncoder.endEncoding()
//
//            commandBuffer.present(drawable)
//            commandBuffer.commit()
//
//            rotationAngle += 0.01
//
//        }
//    }
//
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
