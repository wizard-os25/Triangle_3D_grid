//
//  Material.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import simd

struct Material {
    var ambient: SIMD3<Float>     // Ambient color (k_a)
    var diffuse: SIMD3<Float>     // Diffuse color (k_d)
    var specular: SIMD3<Float>    // Specular color (k_s)
    var shininess: Float          // Specular shininess (typical range: 1-128)
    
    init(ambient: SIMD3<Float> = SIMD3<Float>(0.1, 0.1, 0.1),
         diffuse: SIMD3<Float> = SIMD3<Float>(1, 0, 0),
         specular: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
         shininess: Float = 32.0) {
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
    }
    
    static let red = Material(
        ambient: SIMD3<Float>(0.1, 0.0, 0.0),
        diffuse: SIMD3<Float>(1, 0, 0),
        specular: SIMD3<Float>(1, 1, 1),
        shininess: 32.0
    )
}
