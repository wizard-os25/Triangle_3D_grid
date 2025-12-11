//
//  Light.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

/// Base protocol for all light types
protocol Light {
    var color: SIMD3<Float> { get set }
    var intensity: Float { get set }
}

