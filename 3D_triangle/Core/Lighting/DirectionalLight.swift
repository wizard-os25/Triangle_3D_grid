//
//  DirectionalLight.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

/// Directional light (like sunlight) - infinite distance, parallel rays
struct DirectionalLight: Light {
    var direction: SIMD3<Float>  // Normalized direction vector
    var color: SIMD3<Float>
    var intensity: Float
    
    init(direction: SIMD3<Float>, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0) {
        self.direction = normalize(direction)
        self.color = color
        self.intensity = intensity
    }
}

