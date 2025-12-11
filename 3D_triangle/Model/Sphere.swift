//
//  Sphere.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

struct Sphere {
    let vertices: [SIMD3<Float>]
    let normals: [SIMD3<Float>]
    let indices: [UInt16]
    
    static func create(radius: Float = 0.3, segments: Int = 16) -> Sphere {
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt16] = []
        
        // Generate sphere vertices
        for i in 0...segments {
            let theta = Float(i) * Float.pi / Float(segments)  // 0 to π
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            
            for j in 0...segments {
                let phi = Float(j) * 2.0 * Float.pi / Float(segments)  // 0 to 2π
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)
                
                // Position
                let x = radius * sinTheta * cosPhi
                let y = radius * cosTheta
                let z = radius * sinTheta * sinPhi
                
                vertices.append(SIMD3<Float>(x, y, z))
                
                // Normal (same as position normalized, since sphere is centered at origin)
                normals.append(normalize(SIMD3<Float>(x, y, z)))
            }
        }
        
        // Generate indices
        for i in 0..<segments {
            for j in 0..<segments {
                let first = UInt16(i * (segments + 1) + j)
                let second = UInt16(first + UInt16(segments + 1))
                
                // First triangle
                indices.append(first)
                indices.append(second)
                indices.append(first + 1)
                
                // Second triangle
                indices.append(second)
                indices.append(second + 1)
                indices.append(first + 1)
            }
        }
        
        return Sphere(vertices: vertices, normals: normals, indices: indices)
    }
}

