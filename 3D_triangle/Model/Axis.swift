//
//  Axis.swift
//  3D_triangle
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Axis {
    let xVertices: [SIMD3<Float>]
    let yVertices: [SIMD3<Float>]
    let zVertices: [SIMD3<Float>]
    
    // Quad vertices cho thick lines (mỗi line segment = 1 quad = 2 triangles = 4 vertices)
    let xQuadVertices: [SIMD3<Float>]
    let yQuadVertices: [SIMD3<Float>]
    let zQuadVertices: [SIMD3<Float>]
    
    // Indices cho quads
    let xQuadIndices: [UInt16]
    let yQuadIndices: [UInt16]
    let zQuadIndices: [UInt16]
    
    static func createAxes(size: Float = 33.0, thickness: Float = 0.1) -> Axis {
        // X axis (red) - positive and negative
        let xAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(size, 0, 0),   // Positive X
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(-size, 0, 0)   // Negative X
        ]
        
        // Y axis (green) - positive only
        let yAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, size, 0)    // Positive Y
        ]
        
        // Z axis (blue) - positive and negative
        let zAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, 0, size),    // Positive Z
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, 0, -size)   // Negative Z
        ]
        
        // Tạo quad vertices cho thick lines
        let (xQuads, xIndices) = createThickLineQuads(from: xAxis, thickness: thickness)
        let (yQuads, yIndices) = createThickLineQuads(from: yAxis, thickness: thickness)
        let (zQuads, zIndices) = createThickLineQuads(from: zAxis, thickness: thickness)
        
        return Axis(
            xVertices: xAxis,
            yVertices: yAxis,
            zVertices: zAxis,
            xQuadVertices: xQuads,
            yQuadVertices: yQuads,
            zQuadVertices: zQuads,
            xQuadIndices: xIndices,
            yQuadIndices: yIndices,
            zQuadIndices: zIndices
        )
    }
    
    // Helper function: Tạo quad vertices từ line segment
    // Mỗi line segment (2 points) tạo thành 1 quad (4 vertices) = 2 triangles
    private static func createThickLineQuads(from linePoints: [SIMD3<Float>], thickness: Float) -> ([SIMD3<Float>], [UInt16]) {
        var quadVertices: [SIMD3<Float>] = []
        var quadIndices: [UInt16] = []
        
        // Xử lý từng cặp điểm (mỗi cặp = 1 line segment)
        for i in stride(from: 0, to: linePoints.count, by: 2) {
            guard i + 1 < linePoints.count else { break }
            
            let start = linePoints[i]
            let end = linePoints[i + 1]
            let direction = normalize(end - start)
            
            // Tính toán vector vuông góc với direction và up vector
            // Để tạo quad vuông góc với line
            let up = SIMD3<Float>(0, 1, 0)
            var perpendicular: SIMD3<Float>
            
            // Nếu direction gần như song song với up, dùng vector khác
            if abs(dot(direction, up)) > 0.9 {
                let right = SIMD3<Float>(1, 0, 0)
                perpendicular = normalize(cross(direction, right))
            } else {
                perpendicular = normalize(cross(direction, up))
            }
            
            // Tạo 4 vertices của quad
            let halfThickness = thickness / 2.0
            let offset = perpendicular * halfThickness
            
            let v0 = start - offset  // Bottom-left
            let v1 = start + offset  // Top-left
            let v2 = end - offset    // Bottom-right
            let v3 = end + offset    // Top-right
            
            let baseIndex = UInt16(quadVertices.count)
            quadVertices.append(contentsOf: [v0, v1, v2, v3])
            
            // Tạo 2 triangles: (v0, v1, v2) và (v1, v3, v2)
            quadIndices.append(contentsOf: [
                baseIndex, baseIndex + 1, baseIndex + 2,  // Triangle 1
                baseIndex + 1, baseIndex + 3, baseIndex + 2  // Triangle 2
            ])
        }
        
        return (quadVertices, quadIndices)
    }
}
