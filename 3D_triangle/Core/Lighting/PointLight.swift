//
//  PointLight.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

/// Point light (like a lightbulb) - emits light in all directions from a position
struct PointLight: Light {
    var position: SIMD3<Float>
    var color: SIMD3<Float>
    var intensity: Float
    var radius: Float  // Maximum distance the light affects
    
    init(position: SIMD3<Float>, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0, radius: Float = 10.0) {
        self.position = position
        self.color = color
        self.intensity = intensity
        self.radius = radius
    }
}

