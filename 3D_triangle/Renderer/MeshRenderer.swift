//
//  MeshRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import Metal
import simd

/// Handles vertex buffer, index buffer, normals, UVs for a mesh
class MeshRenderer: BaseRenderer {
    var vertexBuffer: MTLBuffer!
    var normalBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var edgeIndexBuffer: MTLBuffer?
    
    private let mesh: Mesh
    
    init(device: MTLDevice, mesh: Mesh) {
        self.mesh = mesh
        super.init(device: device)
        setupBuffers()
    }
    
    private func setupBuffers() {
        // Vertex buffer
        vertexBuffer = device.makeBuffer(bytes: mesh.vertices,
                                        length: MemoryLayout<SIMD3<Float>>.stride * mesh.vertices.count,
                                        options: [])
        
        // Normal buffer
        normalBuffer = device.makeBuffer(bytes: mesh.normals,
                                        length: MemoryLayout<SIMD3<Float>>.stride * mesh.normals.count,
                                        options: [])
        
        // Index buffer
        indexBuffer = device.makeBuffer(bytes: mesh.indices,
                                       length: MemoryLayout<UInt16>.stride * mesh.indices.count,
                                       options: [])
        
        // Edge index buffer (optional)
        if let edgeIndices = mesh.edgeIndices {
            edgeIndexBuffer = device.makeBuffer(bytes: edgeIndices,
                                               length: MemoryLayout<UInt16>.stride * edgeIndices.count,
                                               options: [])
        }
    }
    
    /// Bind vertex and normal buffers to encoder
    func bindBuffers(to encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(normalBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue + 1))
    }
    
    /// Draw the mesh
    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.drawIndexedPrimitives(type: .triangle,
                                     indexCount: mesh.indices.count,
                                     indexType: .uint16,
                                     indexBuffer: indexBuffer,
                                     indexBufferOffset: 0)
    }
    
    /// Draw edges (wireframe)
    func drawEdges(encoder: MTLRenderCommandEncoder) {
        guard let edgeBuffer = edgeIndexBuffer else { return }
        encoder.drawIndexedPrimitives(type: .line,
                                     indexCount: mesh.edgeIndices!.count,
                                     indexType: .uint16,
                                     indexBuffer: edgeBuffer,
                                     indexBufferOffset: 0)
    }
}

