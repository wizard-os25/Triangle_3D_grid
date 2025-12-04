//
//  TriangleViewController.swift
//  New_Name
//
//  Created by wizard.os25 on 4/12/25.
//

import UIKit
import MetalKit

class TriangleRenderer {
    var device: MTLDevice!
    var triangleVertexBuffer: MTLBuffer!
    var triangleIndexBuffer: MTLBuffer!
    var triangleEdgeIndexBuffer: MTLBuffer!
    var triangleUniformBuffer: MTLBuffer!
    var trianglePipelineState: MTLRenderPipelineState!
    var triangleEdgePipelineState: MTLRenderPipelineState!
    
    // Hình hộp tam giác vertices (4 điểm: 1 đỉnh trên + 3 đỉnh đáy)
    var triangleVertices: [SIMD3<Float>] = []
    var triangleIndices: [UInt16] = []
    var triangleEdgeIndices: [UInt16] = []
    
    init(device: MTLDevice) {
        self.device = device
        setupTriangularPrism()
        setupPipeline()
    }
    
    func setupTriangularPrism() {
        // Tạo hình hộp tam giác (triangular pyramid) với góc đỉnh 30 độ ở tất cả các mặt
        // Góc đỉnh 30 độ = π/6 radian
        let angle30Deg = Float.pi / 6.0  // 30 độ
        let baseRadius: Float = 1.5       // Bán kính mặt đáy
        let baseY: Float = 0.0           // Độ cao mặt đáy
        
        // 3 đỉnh của mặt đáy tam giác đều, cách đều nhau 120 độ
        var baseVertices: [SIMD3<Float>] = []
        for i in 0..<3 {
            let angle = Float(i) * 2.0 * Float.pi / 3.0
            let x = baseRadius * cos(angle)
            let z = baseRadius * sin(angle)
            baseVertices.append(SIMD3<Float>(x, baseY, z))
        }
        
        // Tính toán độ cao đỉnh trên để đảm bảo góc đỉnh = 30 độ
        // Với tam giác đều, khoảng cách giữa 2 đỉnh đáy = baseRadius * sqrt(3)
        let baseEdgeLength = baseRadius * sqrt(3.0)
        // Để góc đỉnh = 30 độ: tan(15°) = (baseEdgeLength/2) / height
        // height = (baseEdgeLength/2) / tan(15°)
        let halfEdge = baseEdgeLength / 2.0
        let height = halfEdge / tan(angle30Deg / 2.0)  // tan(15°)
        
        // Đỉnh trên (apex) nằm ở trung tâm mặt đáy và cao hơn
        let apex = SIMD3<Float>(0, height, 0)
        
        // Tất cả vertices: đỉnh trên + 3 đỉnh đáy
        triangleVertices = [apex] + baseVertices
        
        // Tạo 3 mặt tam giác (3 mặt bên của hình chóp)
        // Mỗi mặt nối đỉnh trên với 2 đỉnh liên tiếp của mặt đáy
        triangleIndices = [
            // Mặt 1: đỉnh trên + đỉnh đáy 0 + đỉnh đáy 1
            0, 1, 2,
            // Mặt 2: đỉnh trên + đỉnh đáy 1 + đỉnh đáy 2
            0, 2, 3,
            // Mặt 3: đỉnh trên + đỉnh đáy 2 + đỉnh đáy 0
            0, 3, 1
        ]
        
        triangleVertexBuffer = device.makeBuffer(bytes: triangleVertices,
                                                length: MemoryLayout<SIMD3<Float>>.stride * triangleVertices.count,
                                                options: [])
        
        triangleIndexBuffer = device.makeBuffer(bytes: triangleIndices,
                                               length: MemoryLayout<UInt16>.stride * triangleIndices.count,
                                               options: [])
        
        // Tạo edge indices cho viền đen
        // 6 cạnh: 3 cạnh từ đỉnh đến đáy + 3 cạnh của mặt đáy
        triangleEdgeIndices = [
            // 3 cạnh từ đỉnh (0) đến các đỉnh đáy
            0, 1,  // đỉnh -> đỉnh đáy 1
            0, 2,  // đỉnh -> đỉnh đáy 2
            0, 3,  // đỉnh -> đỉnh đáy 3
            // 3 cạnh của mặt đáy tam giác
            1, 2,  // đỉnh đáy 1 -> đỉnh đáy 2
            2, 3,  // đỉnh đáy 2 -> đỉnh đáy 3
            3, 1   // đỉnh đáy 3 -> đỉnh đáy 1
        ]
        
        triangleEdgeIndexBuffer = device.makeBuffer(bytes: triangleEdgeIndices,
                                                    length: MemoryLayout<UInt16>.stride * triangleEdgeIndices.count,
                                                    options: [])
    }
    
    func setupPipeline() {
        let library = device.makeDefaultLibrary()
        
        // Setup vertex descriptor cho tam giác
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        descriptor.fragmentFunction = library?.makeFunction(name: "triangle_fragment_main")
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        trianglePipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
        
        // Setup pipeline state cho viền đen
        let edgeDescriptor = MTLRenderPipelineDescriptor()
        edgeDescriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        edgeDescriptor.fragmentFunction = library?.makeFunction(name: "triangle_edge_fragment_main")
        edgeDescriptor.vertexDescriptor = vertexDescriptor
        edgeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        edgeDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        triangleEdgePipelineState = try! device.makeRenderPipelineState(descriptor: edgeDescriptor)
    }
    
    func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4? = nil) {
        let modelMatrix = model ?? simd_float4x4(1) // Identity matrix
        var u = Uniforms(
            model: modelMatrix,
            view: view,
            proj: proj,
            isAxis: 0
        )
        
        if triangleUniformBuffer == nil {
            triangleUniformBuffer = device.makeBuffer(bytes: &u,
                                                      length: MemoryLayout<Uniforms>.stride,
                                                      options: [])
        } else {
            let contents = triangleUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        // Vẽ tam giác đỏ (filled)
        encoder.setRenderPipelineState(trianglePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: 1)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: triangleIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleIndexBuffer,
                                      indexBufferOffset: 0)
        
        // Vẽ viền đen (wireframe)
        encoder.setRenderPipelineState(triangleEdgePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: 1)
        
        encoder.drawIndexedPrimitives(type: .line,
                                      indexCount: triangleEdgeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleEdgeIndexBuffer,
                                      indexBufferOffset: 0)
    }
    
    // Hàm để thay đổi vị trí hình hộp tam giác
    func setTriangularPrismPosition(apex: SIMD3<Float>, baseVertices: [SIMD3<Float>]) {
        guard baseVertices.count == 3 else { return }
        triangleVertices = [apex] + baseVertices
        triangleVertexBuffer = device.makeBuffer(bytes: triangleVertices,
                                                length: MemoryLayout<SIMD3<Float>>.stride * triangleVertices.count,
                                                options: [])
        
        // Edge indices không thay đổi vì cấu trúc vẫn giữ nguyên
        // (đỉnh 0 + 3 đỉnh đáy 1, 2, 3)
    }
}
