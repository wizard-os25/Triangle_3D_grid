//
//  SphereRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import UIKit
import Metal
import simd

class SphereRenderer: BaseRenderer {
    private let meshRenderer: MeshRenderer
    private let materialRenderer: MaterialRenderer
    
    private let sphere: Sphere
    private let material: Material
    
    var orbitSemiMajorAxis: Float = 8.0
    var orbitSemiMinorAxis: Float = 5.0
    var orbitSpeed: Float = 0.5
    var spinSpeed: Float = 1.5  // Self-rotation speed (radians per second)
    
    private var orbitAngle: Float = 0.0
    private var spinAngle: Float = 0.0
    
    override init(device: MTLDevice) {
        // Higher segments for smoother sphere and better specular highlights
        self.sphere = Sphere.create(radius: 0.3, segments: 32)
        // Optimized material for visible Phong lighting on moving sphere
        // Compared to triangle: balanced ambient/diffuse/specular for clear effect
        self.material = Material(
            ambient: SIMD3<Float>(0.15, 0.15, 0.2),     // Balanced ambient (not too dark)
            diffuse: SIMD3<Float>(0.6, 0.7, 0.95),       // Brighter blue (more visible)
            specular: SIMD3<Float>(1.0, 1.0, 0.9),      // Strong but not clamped specular
            shininess: 128.0                             // Optimal shininess (clear but not too sharp)
        )
        
        let mesh = Mesh(
            vertices: sphere.vertices,
            normals: sphere.normals,
            indices: sphere.indices,
            edgeIndices: nil
        )
        
        self.meshRenderer = MeshRenderer(device: device, mesh: mesh)
        self.materialRenderer = MaterialRenderer(device: device, material: material)
        
        super.init(device: device)
    }
    
    func update(deltaTime: Float) {
        // Update orbit angle (elliptical orbit)
        orbitAngle += orbitSpeed * deltaTime
        if orbitAngle > 2.0 * Float.pi {
            orbitAngle -= 2.0 * Float.pi
        }
        
        // Update spin angle (self-rotation around Y axis)
        spinAngle += spinSpeed * deltaTime
        if spinAngle > 2.0 * Float.pi {
            spinAngle -= 2.0 * Float.pi
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4, cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        // Calculate elliptical orbit position
        let x = orbitSemiMajorAxis * cos(orbitAngle)
        let z = orbitSemiMinorAxis * sin(orbitAngle)
        let y: Float = 2.0
        
        // Build model matrix: translate(pos) * rotateY(spinAngle) * scale
        // As per Phong.md: model = translate(pos) * rotateY(selfAngle) * scale(s)
        let translation = matrix_float4x4(translation: SIMD3<Float>(x, y, z))
        let rotation = matrix_float4x4(rotationY: spinAngle)
        let scale = matrix_float4x4(scale: SIMD3<Float>(1.0, 1.0, 1.0))
        
        // Combine: translation * rotation * scale * baseModel
        let finalModel = translation * rotation * scale * model
        
        materialRenderer.updateUniforms(view: view, proj: proj, model: finalModel, cameraPosition: cameraPosition)
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        materialRenderer.render(encoder: encoder, meshRenderer: meshRenderer)
    }
    
    func getCurrentPosition() -> SIMD3<Float> {
        let x = orbitSemiMajorAxis * cos(orbitAngle)
        let z = orbitSemiMinorAxis * sin(orbitAngle)
        return SIMD3<Float>(x, 2.0, z)
    }
}
