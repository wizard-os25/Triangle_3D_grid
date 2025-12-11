//
//  LightNode.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

/// Scene node representing a light in the scene
final class LightNode {
    var light: Light
    var transform: Transform
    
    init(light: Light, transform: Transform = Transform()) {
        self.light = light
        self.transform = transform
    }
    
    /// Get world-space light data (for directional lights, direction is transformed)
    func getWorldLight() -> Light {
        if var dirLight = light as? DirectionalLight {
            // Transform direction by rotation
            let rotatedDir = transform.rotationMatrix * SIMD4<Float>(dirLight.direction, 0.0)
            dirLight.direction = normalize(SIMD3<Float>(rotatedDir.x, rotatedDir.y, rotatedDir.z))
            return dirLight
        } else if var pointLight = light as? PointLight {
            // Transform position
            let worldPos = transform.position
            pointLight.position = worldPos
            return pointLight
        }
        return light
    }
}

