//
//  OrbitCamera.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

// MARK: - Orbit Camera

final class OrbitCamera {
    
    // MARK: - Camera State
    
    /// Spherical orbit angles
    var rotationY: Float = 0.0      // yaw (quay ngang)
    var rotationX: Float = 0.0      // pitch (quay lên/xuống)
    
    /// Distance from target
    var distance: Float = 16.0
    
    /// Clamp configuration
    var minPitch: Float = -Float.pi / 2 + 0.1
    var maxPitch: Float =  Float.pi / 2 - 0.1
    
    var minDistance: Float = CameraDefaults.minDistance
    var maxDistance: Float = CameraDefaults.maxDistance
    
    /// Projection
    var fieldOfView: Float = CameraDefaults.debugFOV
    var nearPlane: Float = 0.1
    var farPlane: Float = 100.0
    
    /// Target + Up vector
    var target: SIMD3<Float> = .init(0, 0, 0)
    var up: SIMD3<Float> = .init(0, 1, 0)
    
    /// Sensitivity
    var rotationSensitivity: Float = 0.01
    var zoomSensitivity: Float = 1.0
    
    
    // MARK: - Camera Controls
    
    /// X/Y drag -> orbit rotation
    func rotate(deltaX: Float, deltaY: Float) {
        rotationY += deltaX * rotationSensitivity
        rotationX += deltaY * rotationSensitivity
        
        // Clamp pitch
        rotationX = max(minPitch, min(maxPitch, rotationX))
    }
    
    /// Pinch gesture or scroll wheel → zoom
    func zoom(delta: Float) {
        distance *= (1.0 / (delta * zoomSensitivity))
        distance = max(minDistance, min(maxDistance, distance))
    }
    
    
    // MARK: - Camera Calculation
    
    /// Convert spherical → world-space camera position
    func position() -> SIMD3<Float> {
        let x = distance * cos(rotationX) * sin(rotationY)
        let y = distance * sin(rotationX)
        let z = distance * cos(rotationX) * cos(rotationY)
        return SIMD3<Float>(x, y, z)
    }
    
    
    /// View matrix
    func viewMatrix() -> matrix_float4x4 {
        let eye = position()
        return matrix_float4x4(eye: eye, center: target, up: up)
    }
    
    
    /// Projection matrix (perspective)
    func projectionMatrix(aspect: Float) -> matrix_float4x4 {
        matrix_float4x4(
            perspectiveDegrees: fieldOfView,
            aspect: aspect,
            near: nearPlane,
            far: farPlane
        )
    }
}
