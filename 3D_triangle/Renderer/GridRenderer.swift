//
//  GridRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import Metal
import simd

class GridRenderer: BaseRenderer {
    var gridVertexBuffer: MTLBuffer!
    var gridUniformBuffer: MTLBuffer!
    var gridPipelineState: MTLRenderPipelineState!
    
    private let gridVertices: [SIMD3<Float>]
    
    init(device: MTLDevice, size: Float = 33.0, spacing: Float = 0.33) {
        self.gridVertices = GridRenderer.generateGridVertices(size: size, spacing: spacing)
        super.init(device: device)
        setupBuffers()
        setupPipeline()
    }
    
    static func generateGridVertices(size: Float, spacing: Float) -> [SIMD3<Float>] {
        var vertices: [SIMD3<Float>] = []
        let halfSize = size / 2.0
        
        // Lines parallel to X axis (along Z)
        var z = -halfSize
        while z <= halfSize {
            vertices.append(SIMD3<Float>(-halfSize, 0, z))
            vertices.append(SIMD3<Float>(halfSize, 0, z))
            z += spacing
        }
        
        // Lines parallel to Z axis (along X)
        var x = -halfSize
        while x <= halfSize {
            vertices.append(SIMD3<Float>(x, 0, -halfSize))
            vertices.append(SIMD3<Float>(x, 0, halfSize))
            x += spacing
        }
        
        return vertices
    }
    
    private func setupBuffers() {
        gridVertexBuffer = device.makeBuffer(bytes: gridVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * gridVertices.count,
                                             options: [])
    }
    
    private func setupPipeline() {
        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = Int(BufferIndexVertices.rawValue)
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Pipeline state
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "grid_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "grid_fragment_main") else {
            fatalError("Failed to find grid shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            gridPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create grid pipeline state: \(error)")
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
            materialAmbient: SIMD3<Float>(0.1, 0.1, 0.1),
            materialDiffuse: SIMD3<Float>(1, 1, 1),
            materialSpecular: SIMD3<Float>(1, 1, 1),
            materialShininess: 32.0,
            cameraPosition: cameraPosition
        )
        
        if gridUniformBuffer == nil {
            gridUniformBuffer = device.makeBuffer(bytes: &u,
                                                 length: MemoryLayout<Uniforms>.stride,
                                                 options: [])
        } else {
            let contents = gridUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard gridUniformBuffer != nil else { return }
        
        encoder.setRenderPipelineState(gridPipelineState)
        encoder.setVertexBuffer(gridVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(gridUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(gridUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: gridVertices.count)
    }
}
