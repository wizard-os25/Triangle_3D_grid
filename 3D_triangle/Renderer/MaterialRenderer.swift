//
//  MaterialRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import Metal
import simd

class MaterialRenderer: BaseRenderer {
    var uniformBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var edgePipelineState: MTLRenderPipelineState!
    
    private let material: Material
    private var baseUniforms: Uniforms?
    
    init(device: MTLDevice, material: Material) {
        self.material = material
        super.init(device: device)
        setupPipeline()
    }
    
    private func setupPipeline() {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = Int(BufferIndexVertices.rawValue)
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = Int(BufferIndexVertices.rawValue + 1)
        vertexDescriptor.layouts[1].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[1].stepRate = 1
        vertexDescriptor.layouts[1].stepFunction = .perVertex
        
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "material_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "material_fragment_main") else {
            fatalError("Failed to find material shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create material pipeline state: \(error)")
        }
        
        let edgeVertexDescriptor = MTLVertexDescriptor()
        edgeVertexDescriptor.attributes[0].format = .float3
        edgeVertexDescriptor.attributes[0].offset = 0
        edgeVertexDescriptor.attributes[0].bufferIndex = Int(BufferIndexVertices.rawValue)
        edgeVertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        edgeVertexDescriptor.layouts[0].stepRate = 1
        edgeVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let edgeDescriptor = MTLRenderPipelineDescriptor()
        edgeDescriptor.vertexFunction = library.makeFunction(name: "material_edge_vertex_main")
        edgeDescriptor.fragmentFunction = library.makeFunction(name: "material_edge_fragment_main")
        edgeDescriptor.vertexDescriptor = edgeVertexDescriptor
        edgeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        edgeDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            edgePipelineState = try device.makeRenderPipelineState(descriptor: edgeDescriptor)
        } catch {
            fatalError("Failed to create material edge pipeline state: \(error)")
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4, cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        let normalMat = model.normalMatrix()
        var u = Uniforms(
            model: model,
            view: view,
            proj: proj,
            normalMatrix: normalMat,
            isAxis: 0,
            axisColor: SIMD4<Float>(0, 0, 0, 1),
            materialAmbient: material.ambient,
            materialDiffuse: material.diffuse,
            materialSpecular: material.specular,
            materialShininess: material.shininess,
            cameraPosition: cameraPosition
        )
        
        baseUniforms = u
        
        if uniformBuffer == nil {
            uniformBuffer = device.makeBuffer(bytes: &u,
                                             length: MemoryLayout<Uniforms>.stride,
                                             options: [])
        } else {
            let contents = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    func render(encoder: MTLRenderCommandEncoder, meshRenderer: MeshRenderer) {
        guard uniformBuffer != nil else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        meshRenderer.bindBuffers(to: encoder)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        meshRenderer.draw(encoder: encoder)
    }
    
    func renderEdges(encoder: MTLRenderCommandEncoder, meshRenderer: MeshRenderer) {
        guard uniformBuffer != nil else { return }
        
        encoder.setRenderPipelineState(edgePipelineState)
        encoder.setVertexBuffer(meshRenderer.vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        meshRenderer.drawEdges(encoder: encoder)
    }
}
