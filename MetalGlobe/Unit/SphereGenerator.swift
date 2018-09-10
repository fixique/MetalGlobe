//
//  SphereGenerator.swift
//  MetalGlobe
//
//  Created by Vlad Krupenko on 06.04.17.
//  Copyright © 2017 fixique. All rights reserved.
//

import Metal

struct SphereGenerator {
    static func sphereWithRadius(_ radius: Float32, stacks: Int, slices: Int, device: MTLDevice) -> (MTLBuffer, MTLBuffer) {
        let pi = Float32(Float32.pi)
        let twoPi = pi * 2
        let deltaPhi = pi / Float32(stacks)
        let deltaTheta = twoPi / Float32(slices)
        
        var vertices = [Vertex]()
        var indices = [UInt16]()
        
        var phi = Float32(-Float32.pi / 2)
        for _ in 0...stacks {
            
            var theta:Float32 = 0
            
            for slice in 0...slices {
                let x = cos(theta) * cos(phi)
                let y = sin(phi)
                let z = sin(theta) * cos(phi)
                
                let position = Vector4(x: radius * x, y: radius * y, z: radius * z, w: 1)
                let normal = Vector4(x: x, y: y, z: z, w: 0)
                let texCoords = TexCoords(u: 1 - Float32(slice) / Float32(slices), v: 1 - (sin(phi) + 1) * 0.5)
                
                let vertex = Vertex(position: position, normal: normal, texCoords: texCoords)
                
                vertices.append(vertex)
                
                theta += deltaTheta
            }
            
            phi += deltaPhi
        }
        
        for stack in 0..<stacks {
            
            for slice in 0..<slices {
                
                let i0 = UInt16(slice + stack * slices)
                let i1 = i0 + 1
                let i2 = i0 + UInt16(slices)
                let i3 = i2 + 1
                
                indices.append(i0)
                indices.append(i2)
                indices.append(i3)
                
                indices.append(i0)
                indices.append(i3)
                indices.append(i1)
            }
        }
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length:MemoryLayout<Vertex>.size * vertices.count, options:[])
        
        let indexBuffer = device.makeBuffer(bytes: indices, length:MemoryLayout<UInt16>.size * indices.count, options:[])
        
        return (vertexBuffer!, indexBuffer!)
    }
}
