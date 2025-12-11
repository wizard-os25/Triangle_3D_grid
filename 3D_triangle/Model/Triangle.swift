//
//  Triangle.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Triangle {
    // Triangular pyramid (tetrahedron) vertices
    // 4 vertices: 1 apex + 3 base vertices
    let vertices: [SIMD3<Float>]
    let normals: [SIMD3<Float>]  // Normal vectors for lighting
    let indices: [UInt16]
    let edgeIndices: [UInt16]
    
    static func createTriangularPyramid(apexAngle: Float = Float.pi / 6.0, // 30 degrees
                                       baseRadius: Float = 1.5,
                                       baseY: Float = 0.0) -> Triangle {
        // 3 base vertices forming equilateral triangle
        var baseVertices: [SIMD3<Float>] = []
        for i in 0..<3 {
            let angle = Float(i) * 2.0 * Float.pi / 3.0
            let x = baseRadius * cos(angle)
            let z = baseRadius * sin(angle)
            baseVertices.append(SIMD3<Float>(x, baseY, z))
        }
        
        // Calculate apex height to ensure apex angle
        let baseEdgeLength = baseRadius * sqrt(3.0)
        let halfEdge = baseEdgeLength / 2.0
        let height = halfEdge / tan(apexAngle / 2.0)
        
        // Apex at center of base, elevated
        let apex = SIMD3<Float>(0, height, 0)
        
        // All vertices: apex + 3 base vertices
        let allVertices = [apex] + baseVertices
        
        // 3 triangular faces (sides of pyramid)
        let faceIndices: [UInt16] = [
            0, 1, 2,  // Face 1: apex + base 0 + base 1
            0, 2, 3,  // Face 2: apex + base 1 + base 2
            0, 3, 1   // Face 3: apex + base 2 + base 0
        ]
        
        // Calculate normals for each face
        func calculateNormal(v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>) -> SIMD3<Float> {
            let edge1 = v1 - v0
            let edge2 = v2 - v0
            return normalize(cross(edge1, edge2))
        }
        
        // Calculate normal for each face
        let normal1 = calculateNormal(v0: allVertices[0], v1: allVertices[1], v2: allVertices[2])
        let normal2 = calculateNormal(v0: allVertices[0], v1: allVertices[2], v2: allVertices[3])
        let normal3 = calculateNormal(v0: allVertices[0], v1: allVertices[3], v2: allVertices[1])
        
        // Assign normals to vertices (each vertex gets the normal of its face)
        // For shared vertices (apex), average the normals
        let apexNormal = normalize((normal1 + normal2 + normal3) / 3.0)
        var normals: [SIMD3<Float>] = []
        normals.append(apexNormal)  // Vertex 0 (apex)
        normals.append(normal1)     // Vertex 1 (base 0)
        normals.append(normal1)     // Vertex 2 (base 1) - shares face 1
        normals.append(normal2)     // Vertex 3 (base 2) - shares face 2
        
        // Edge indices for wireframe
        let edges: [UInt16] = [
            // 3 edges from apex to base vertices
            0, 1,  // apex -> base 1
            0, 2,  // apex -> base 2
            0, 3,  // apex -> base 3
            // 3 edges of base triangle
            1, 2,  // base 1 -> base 2
            2, 3,  // base 2 -> base 3
            3, 1   // base 3 -> base 1
        ]
        
        return Triangle(vertices: allVertices, normals: normals, indices: faceIndices, edgeIndices: edges)
    }
}
