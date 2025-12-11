//
//  Mesh.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

/// Mesh data structure containing all vertex attributes
struct Mesh {
    let vertices: [SIMD3<Float>]      // Positions
    let normals: [SIMD3<Float>]       // Normals
    let uvs: [SIMD2<Float>]?          // UV coordinates (optional)
    let indices: [UInt16]             // Face indices
    let edgeIndices: [UInt16]?        // Edge indices for wireframe (optional)
    
    init(vertices: [SIMD3<Float>],
         normals: [SIMD3<Float>],
         uvs: [SIMD2<Float>]? = nil,
         indices: [UInt16],
         edgeIndices: [UInt16]? = nil) {
        self.vertices = vertices
        self.normals = normals
        self.uvs = uvs
        self.indices = indices
        self.edgeIndices = edgeIndices
    }
}

