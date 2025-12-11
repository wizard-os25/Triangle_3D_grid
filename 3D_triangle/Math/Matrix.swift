//
//  Matrix.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

extension matrix_float4x4 {
    // Identity matrix
    init(_ value: Float) {
        self = simd_float4x4(
            SIMD4<Float>(value, 0, 0, 0),
            SIMD4<Float>(0, value, 0, 0),
            SIMD4<Float>(0, 0, value, 0),
            SIMD4<Float>(0, 0, 0, value)
        )
    }
    
    // Rotation around X axis
    init(rotationX angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, c, -s, 0),
            SIMD4<Float>(0, s, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    // Rotation around Y axis
    init(rotationY angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = simd_float4x4(
            SIMD4<Float>(c, 0, s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(-s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    // Rotation around Z axis
    init(rotationZ angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        self = simd_float4x4(
            SIMD4<Float>(c, -s, 0, 0),
            SIMD4<Float>(s, c, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    // Scale matrix
    init(scale: SIMD3<Float>) {
        self = simd_float4x4(
            SIMD4<Float>(scale.x, 0, 0, 0),
            SIMD4<Float>(0, scale.y, 0, 0),
            SIMD4<Float>(0, 0, scale.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    // Translation matrix
    init(translation: SIMD3<Float>) {
        self = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }
    
    // Look-at matrix (view matrix)
    init(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) {
        let forward = normalize(center - eye)
        
        // Handle edge case when forward and up are parallel
        let right = normalize(cross(forward, up))
        let upCorrected = normalize(cross(right, forward))
        
        // Ensure vectors are normalized and orthogonal
        let rightNormalized = normalize(right)
        let upNormalized = normalize(upCorrected)
        let forwardNormalized = normalize(forward)
        
        self = simd_float4x4(
            SIMD4<Float>(rightNormalized.x, upNormalized.x, -forwardNormalized.x, 0),
            SIMD4<Float>(rightNormalized.y, upNormalized.y, -forwardNormalized.y, 0),
            SIMD4<Float>(rightNormalized.z, upNormalized.z, -forwardNormalized.z, 0),
            SIMD4<Float>(-dot(rightNormalized, eye), -dot(upNormalized, eye), dot(forwardNormalized, eye), 1)
        )
    }
    
    // Perspective projection matrix
    init(perspectiveDegrees fov: Float, aspect: Float, near: Float, far: Float) {
        let f = 1.0 / tan(fov * .pi / 180.0 / 2.0)
        let range = far - near
        
        self = simd_float4x4(
            SIMD4<Float>(f / aspect, 0, 0, 0),
            SIMD4<Float>(0, f, 0, 0),
            SIMD4<Float>(0, 0, -(far + near) / range, -1),
            SIMD4<Float>(0, 0, -(2 * far * near) / range, 0)
        )
    }
    
    // Normal matrix (inverse transpose of upper-left 3x3 of model matrix)
    func normalMatrix() -> matrix_float4x4 {
        let upperLeft3x3 = simd_float3x3(
            SIMD3<Float>(self.columns.0.x, self.columns.0.y, self.columns.0.z),
            SIMD3<Float>(self.columns.1.x, self.columns.1.y, self.columns.1.z),
            SIMD3<Float>(self.columns.2.x, self.columns.2.y, self.columns.2.z)
        )
        let invTranspose = upperLeft3x3.inverse.transpose
        return simd_float4x4(
            SIMD4<Float>(invTranspose.columns.0.x, invTranspose.columns.0.y, invTranspose.columns.0.z, 0),
            SIMD4<Float>(invTranspose.columns.1.x, invTranspose.columns.1.y, invTranspose.columns.1.z, 0),
            SIMD4<Float>(invTranspose.columns.2.x, invTranspose.columns.2.y, invTranspose.columns.2.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
}
