//
//  TriangleRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import UIKit
import Metal
import simd

class TriangleRenderer: BaseRenderer {
    private let meshRenderer: MeshRenderer
    private let materialRenderer: MaterialRenderer
    
    private let triangle: Triangle
    private let material: Material
    
    override init(device: MTLDevice) {
        self.triangle = Triangle.createTriangularPyramid()
        self.material = Material.red
        
        let mesh = Mesh(
            vertices: triangle.vertices,
            normals: triangle.normals,
            indices: triangle.indices,
            edgeIndices: triangle.edgeIndices
        )
        
        self.meshRenderer = MeshRenderer(device: device, mesh: mesh)
        self.materialRenderer = MaterialRenderer(device: device, material: material)
        
        super.init(device: device)
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4, cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        materialRenderer.updateUniforms(view: view, proj: proj, model: model, cameraPosition: cameraPosition)
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        materialRenderer.render(encoder: encoder, meshRenderer: meshRenderer)
        materialRenderer.renderEdges(encoder: encoder, meshRenderer: meshRenderer)
    }
}
