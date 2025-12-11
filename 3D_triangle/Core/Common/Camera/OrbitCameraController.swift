//
//  OrbitCameraController.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

// MARK: - OrbitCameraController

/// This layer contains all the **logic** for controlling the camera:
/// - Orbit (yaw / pitch / radius)
/// - Pan (shift target)
/// - Zoom / dolly
/// - Apply limits (minPitch, maxPitch, radius min/max)
/// - Inertia / damping / smoothing
/// - Behavior modes (auto-rotate, snap-to-axis, etc.)
///
/// The controller **reads input** (but does not define it) and **updates the camera state**.
final class OrbitCameraController {
    
    // MARK: - Camera Reference
    
    private(set) var camera: Camera
    
    // MARK: - Limits
    
    var minPitch: Float = -Float.pi / 2 + 0.1
    var maxPitch: Float = Float.pi / 2 - 0.1
    
    var minDistance: Float = CameraDefaults.minDistance
    var maxDistance: Float = CameraDefaults.maxDistance
    
    // MARK: - Sensitivity
    
    /// Sensitivity for rotation (higher = more sensitive)
    /// Default: 0.005 radians per pixel (smooth and natural)
    var rotationSensitivity: Float = 0.005
    
    /// Sensitivity for zoom (higher = more sensitive)
    /// Default: 0.05 (reduced 10x for finer control)
    var zoomSensitivity: Float = 0.05
    
    /// Sensitivity for panning (higher = more sensitive)
    /// Default: 0.002 (smooth pan)
    var panSensitivity: Float = 0.002
    
    // MARK: - Smoothing / Inertia
    
    var enableSmoothing: Bool = false
    var smoothingFactor: Float = 0.1
    
    // Velocity for inertia
    private var yawVelocity: Float = 0.0
    private var pitchVelocity: Float = 0.0
    private var distanceVelocity: Float = 0.0
    
    // MARK: - Initialization
    
    init(camera: Camera) {
        self.camera = camera
    }
    
    // MARK: - Orbit Controls
    
    /// Rotate camera around target (yaw and pitch)
    /// - Parameters:
    ///   - deltaYaw: Horizontal rotation delta (in radians or normalized units)
    ///   - deltaPitch: Vertical rotation delta (in radians or normalized units)
    func orbit(deltaYaw: Float, deltaPitch: Float) {
        if enableSmoothing {
            yawVelocity += deltaYaw * rotationSensitivity
            pitchVelocity += deltaPitch * rotationSensitivity
        } else {
            camera.yaw += deltaYaw * rotationSensitivity
            camera.pitch += deltaPitch * rotationSensitivity
            clampPitch()
        }
    }
    
    /// Zoom / dolly (change distance from target)
    /// - Parameter delta: Zoom delta (positive = zoom in, negative = zoom out)
    ///   Range typically -1.0 to 1.0 from pinch gesture
    func zoom(delta: Float) {
        if enableSmoothing {
            distanceVelocity += delta * zoomSensitivity
        } else {
            // Exponential zoom for natural feel
            // delta > 0 zooms in, delta < 0 zooms out
            let zoomFactor = 1.0 + (delta * zoomSensitivity)
            let newDistance = camera.distance * zoomFactor
            camera.distance = max(minDistance, min(maxDistance, newDistance))
        }
    }
    
    /// Pan (shift target position)
    /// - Parameters:
    ///   - deltaX: Horizontal pan delta
    ///   - deltaY: Vertical pan delta
    func pan(deltaX: Float, deltaY: Float) {
        let right = camera.right()
        let up = camera.up
        let forward = camera.forward()
        
        // Calculate pan movement in world space
        let panRight = right * (deltaX * panSensitivity * camera.distance)
        let panUp = up * (deltaY * panSensitivity * camera.distance)
        
        camera.target += panRight + panUp
    }
    
    // MARK: - Limits
    
    private func clampPitch() {
        camera.pitch = max(minPitch, min(maxPitch, camera.pitch))
    }
    
    private func clampDistance() {
        camera.distance = max(minDistance, min(maxDistance, camera.distance))
    }
    
    // MARK: - Smoothing Update
    
    /// Call this every frame to apply smoothing/inertia
    func update(deltaTime: Float) {
        guard enableSmoothing else { return }
        
        // Apply velocity with damping
        if abs(yawVelocity) > 0.001 {
            camera.yaw += yawVelocity * deltaTime
            yawVelocity *= (1.0 - smoothingFactor)
        } else {
            yawVelocity = 0.0
        }
        
        if abs(pitchVelocity) > 0.001 {
            camera.pitch += pitchVelocity * deltaTime
            pitchVelocity *= (1.0 - smoothingFactor)
            clampPitch()
        } else {
            pitchVelocity = 0.0
        }
        
        if abs(distanceVelocity) > 0.001 {
            let newDistance = camera.distance * (1.0 / (1.0 + distanceVelocity * deltaTime))
            camera.distance = max(minDistance, min(maxDistance, newDistance))
            distanceVelocity *= (1.0 - smoothingFactor)
        } else {
            distanceVelocity = 0.0
        }
    }
    
    // MARK: - Reset
    
    /// Reset camera to default position (showing 2 faces of triangle)
    func reset() {
        camera.yaw = Float.pi / 3.0      // 60 degrees - better angle to see 2 faces
        camera.pitch = Float.pi / 7.0    // ~25.7 degrees - optimal pitch to see 2 faces
        camera.distance = 16.0
        camera.target = SIMD3<Float>(0, 0, 0)
        
        yawVelocity = 0.0
        pitchVelocity = 0.0
        distanceVelocity = 0.0
    }
    
    // MARK: - Convenience Methods
    
    /// Set camera to look at a specific target
    func lookAt(target: SIMD3<Float>) {
        camera.target = target
    }
    
    /// Set camera distance
    func setDistance(_ distance: Float) {
        camera.distance = max(minDistance, min(maxDistance, distance))
    }
}

