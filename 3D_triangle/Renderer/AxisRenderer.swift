//
//  AxisRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import UIKit
import Metal
import simd

class AxisRenderer: BaseRenderer {
    // Quad buffers (thick lines)
    var axisXVertexBuffer: MTLBuffer!
    var axisYVertexBuffer: MTLBuffer!
    var axisZVertexBuffer: MTLBuffer!
    var axisXIndexBuffer: MTLBuffer!
    var axisYIndexBuffer: MTLBuffer!
    var axisZIndexBuffer: MTLBuffer!
    var axisUniformBuffer: MTLBuffer!
    var axisPipelineState: MTLRenderPipelineState!
    var axisDepthStencilState: MTLDepthStencilState!
    
    private let axis: Axis
    
    init(device: MTLDevice, size: Float = 33.0, thickness: Float = 0.03) {
        self.axis = Axis.createAxes(size: size, thickness: thickness)
        super.init(device: device)
        setupBuffers()
        setupPipeline()
    }
    
    private func setupBuffers() {
        // Quad vertex buffers
        axisXVertexBuffer = device.makeBuffer(bytes: axis.xQuadVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.xQuadVertices.count,
                                              options: [])
        
        axisYVertexBuffer = device.makeBuffer(bytes: axis.yQuadVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.yQuadVertices.count,
                                              options: [])
        
        axisZVertexBuffer = device.makeBuffer(bytes: axis.zQuadVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.zQuadVertices.count,
                                              options: [])
        
        // Quad index buffers
        axisXIndexBuffer = device.makeBuffer(bytes: axis.xQuadIndices,
                                            length: MemoryLayout<UInt16>.stride * axis.xQuadIndices.count,
                                            options: [])
        
        axisYIndexBuffer = device.makeBuffer(bytes: axis.yQuadIndices,
                                            length: MemoryLayout<UInt16>.stride * axis.yQuadIndices.count,
                                            options: [])
        
        axisZIndexBuffer = device.makeBuffer(bytes: axis.zQuadIndices,
                                            length: MemoryLayout<UInt16>.stride * axis.zQuadIndices.count,
                                            options: [])
    }
    
    private func setupPipeline() {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = Int(BufferIndexVertices.rawValue)
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "axis_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "axis_fragment_main") else {
            fatalError("Failed to find axis shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            axisPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create axis pipeline state: \(error)")
        }
        
        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .lessEqual
        depthDesc.isDepthWriteEnabled = false
        axisDepthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }
    
    private var baseUniforms: Uniforms?
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4, cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        let normalMat = model.normalMatrix()
        var u = Uniforms(
            model: model,
            view: view,
            proj: proj,
            normalMatrix: normalMat,
            isAxis: 1,
            axisColor: SIMD4<Float>(0, 0, 0, 1),
            materialAmbient: SIMD3<Float>(0.1, 0.1, 0.1),
            materialDiffuse: SIMD3<Float>(1, 1, 1),
            materialSpecular: SIMD3<Float>(1, 1, 1),
            materialShininess: 32.0,
            cameraPosition: cameraPosition
        )
        
        baseUniforms = u
        
        if axisUniformBuffer == nil {
            axisUniformBuffer = device.makeBuffer(bytes: &u,
                                                 length: MemoryLayout<Uniforms>.stride,
                                                 options: [])
        }
    }
    
    private func updateUniformBufferWithColor(_ color: SIMD4<Float>) {
        guard var u = baseUniforms else { return }
        u.axisColor = color
        
        let contents = axisUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        contents.pointee = u
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard axisUniformBuffer != nil, baseUniforms != nil else { return }
        
        encoder.setRenderPipelineState(axisPipelineState)
        encoder.setDepthStencilState(axisDepthStencilState)
        encoder.setDepthBias(-0.0001, slopeScale: 0.0, clamp: 0.0)
        
        updateUniformBufferWithColor(SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisXVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: axis.xQuadIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: axisXIndexBuffer,
                                      indexBufferOffset: 0)
        
        updateUniformBufferWithColor(SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisYVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: axis.yQuadIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: axisYIndexBuffer,
                                      indexBufferOffset: 0)
        
        updateUniformBufferWithColor(SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisZVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: axis.zQuadIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: axisZIndexBuffer,
                                      indexBufferOffset: 0)
    }
}
