//
//  ViewController.swift
//  appDelegateTesst
//
//  Created by wizard.os25 on 4/12/25.
//

import UIKit
import MetalKit

final class ViewController: UIViewController, MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Update projection matrix when view size changes
        updateUniforms()
    }
    
    
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    var depthStencilState: MTLDepthStencilState!
    
    // Triangle renderer
    var triangleRenderer: TriangleRenderer!
    
    // Camera rotation
    var cameraRotationY: Float = 0.0  // Yaw (quay quanh trục Y)
    var cameraRotationX: Float = 0.0  // Pitch (quay lên/xuống)
    var cameraDistance: Float = 8.0    // Khoảng cách từ camera đến gốc tọa độ
    
    // Buffers
    var gridVertexBuffer: MTLBuffer!
    var axisXVertexBuffer: MTLBuffer!
    var axisYVertexBuffer: MTLBuffer!
    var axisZVertexBuffer: MTLBuffer!
    var gridUniformBuffer: MTLBuffer!
    var axisUniformBuffer: MTLBuffer!
    
    // Grid parameters
    let gridSize: Float = 33.0  // Kích thước grid (từ -gridSize đến +gridSize)
    let gridSpacing: Float = 0.33  // Khoảng cách giữa các đường
    
    var gridVertices: [SIMD3<Float>] = []
    var axisXVertices: [SIMD3<Float>] = []
    var axisYVertices: [SIMD3<Float>] = []
    var axisZVertices: [SIMD3<Float>] = []
    
    func generateGridVertices() {
        gridVertices.removeAll()
        axisXVertices.removeAll()
        axisYVertices.removeAll()
        axisZVertices.removeAll()
        
        // Tạo các đường song song với trục X (theo chiều Z)
        let halfSize = gridSize / 2.0
        var z = -halfSize
        while z <= halfSize {
            gridVertices.append(SIMD3<Float>(-halfSize, 0, z))
            gridVertices.append(SIMD3<Float>(halfSize, 0, z))
            z += gridSpacing
        }
        
        // Tạo các đường song song với trục Z (theo chiều X)
        var x = -halfSize
        while x <= halfSize {
            gridVertices.append(SIMD3<Float>(x, 0, -halfSize))
            gridVertices.append(SIMD3<Float>(x, 0, halfSize))
            x += gridSpacing
        }
        
        // Tạo các trục tọa độ riêng biệt (sẽ render đậm hơn)
        // Trục X - từ gốc đến +X
        axisXVertices.append(SIMD3<Float>(0, 0, 0))
        axisXVertices.append(SIMD3<Float>(gridSize, 0, 0))
        // Trục X - từ gốc đến -X
        axisXVertices.append(SIMD3<Float>(0, 0, 0))
        axisXVertices.append(SIMD3<Float>(-gridSize, 0, 0))
        
        // Trục Z - từ gốc đến +Z
        axisZVertices.append(SIMD3<Float>(0, 0, 0))
        axisZVertices.append(SIMD3<Float>(0, 0, gridSize))
        // Trục Z - từ gốc đến -Z
        axisZVertices.append(SIMD3<Float>(0, 0, 0))
        axisZVertices.append(SIMD3<Float>(0, 0, -gridSize))
        
        // Trục Y - từ gốc đến +Y
        axisYVertices.append(SIMD3<Float>(0, 0, 0))
        axisYVertices.append(SIMD3<Float>(0, gridSize, 0))
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateGridVertices()
        setupMetal()
        setupPipeline()
        setupGestures()
    }
    
    func setupGestures() {
        // Thêm pan gesture để quay camera
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        // Thêm pinch gesture để zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        metalView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: metalView)
        
        // Tính toán góc quay dựa trên movement
        let sensitivity: Float = 0.01
        cameraRotationY += Float(translation.x) * sensitivity
        cameraRotationX += Float(translation.y) * sensitivity
        
        // Giới hạn pitch để tránh quay quá mức
        cameraRotationX = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, cameraRotationX))
        
        // Reset translation để tính relative movement
        gesture.setTranslation(.zero, in: metalView)
        
        // Cập nhật view
        updateUniforms()
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // Thay đổi khoảng cách camera
            let scale = Float(gesture.scale)
            cameraDistance *= (1.0 / scale)
            cameraDistance = max(2.0, min(20.0, cameraDistance))  // Giới hạn khoảng cách
            
            gesture.scale = 1.0  // Reset scale
            updateUniforms()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        metalView.frame = view.bounds
        setupBuffers()
    }
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.delegate = self
        metalView.clearColor = MTLClearColorMake(0.1, 0.1, 0.12, 1.0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.preferredFramesPerSecond = 60
        metalView.isUserInteractionEnabled = true  // Enable để nhận gesture
        view.addSubview(metalView)
        
        // Khởi tạo triangle renderer
        triangleRenderer = TriangleRenderer(device: device)
    }

    func setupPipeline() {
        let library = device.makeDefaultLibrary()
        
        // Setup vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = library?.makeFunction(name: "vertex_main")
        descriptor.fragmentFunction = library?.makeFunction(name: "fragment_main")
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }

    func setupBuffers() {
        gridVertexBuffer = device.makeBuffer(bytes: gridVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * gridVertices.count,
                                             options: [])
        
        axisXVertexBuffer = device.makeBuffer(bytes: axisXVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisXVertices.count,
                                             options: [])
        
        axisYVertexBuffer = device.makeBuffer(bytes: axisYVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisYVertices.count,
                                             options: [])
        
        axisZVertexBuffer = device.makeBuffer(bytes: axisZVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisZVertices.count,
                                             options: [])
        
        updateUniforms()
    }
    
    func updateUniforms() {
        let aspect = Float(metalView.bounds.width / max(metalView.bounds.height, 1.0))
        
        // Tính toán vị trí camera dựa trên rotation
        let eyeX = cameraDistance * cos(cameraRotationX) * sin(cameraRotationY)
        let eyeY = cameraDistance * sin(cameraRotationX)
        let eyeZ = cameraDistance * cos(cameraRotationX) * cos(cameraRotationY)
        
        let eye = SIMD3<Float>(eyeX, eyeY, eyeZ)
        let center = SIMD3<Float>(0, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        
        // Camera nhìn từ vị trí được tính toán
        let viewMatrix = matrix_float4x4(eye: eye, center: center, up: up)
        let projMatrix = matrix_float4x4(perspectiveDegrees: 60,
                                         aspect: aspect,
                                         near: 0.1, far: 100)
        
        var gridU = Uniforms(
            model: matrix_float4x4(rotationY: 0),
            view: viewMatrix,
            proj: projMatrix,
            isAxis: 0
        )
        
        var axisU = gridU
        axisU.isAxis = 1
        
        // Update uniform buffers
        if gridUniformBuffer == nil {
            gridUniformBuffer = device.makeBuffer(bytes: &gridU,
                                                  length: MemoryLayout<Uniforms>.stride,
                                                  options: [])
            axisUniformBuffer = device.makeBuffer(bytes: &axisU,
                                                 length: MemoryLayout<Uniforms>.stride,
                                                 options: [])
        } else {
            let gridContents = gridUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            gridContents.pointee = gridU
            let axisContents = axisUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            axisContents.pointee = axisU
        }
        
        // Update triangle uniforms
        triangleRenderer.updateUniforms(view: viewMatrix, proj: projMatrix)
    }
    
    // Helper functions for matrix operations
    func matrix_float4x4(rotationY angle: Float) -> matrix_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return simd.matrix_float4x4(
            SIMD4<Float>(c, 0, s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(-s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    func matrix_float4x4(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        // Calculate forward, right, and up vectors
        let forward = normalize(center - eye)
        let right = normalize(cross(forward, up))
        let upCorrected = cross(right, forward)
        
        // Look-at matrix (right-handed coordinate system for Metal)
        // Column-major order
        return simd.matrix_float4x4(
            SIMD4<Float>(right.x, upCorrected.x, -forward.x, 0),
            SIMD4<Float>(right.y, upCorrected.y, -forward.y, 0),
            SIMD4<Float>(right.z, upCorrected.z, -forward.z, 0),
            SIMD4<Float>(-dot(right, eye), -dot(upCorrected, eye), dot(forward, eye), 1)
        )
    }
    
    func matrix_float4x4(perspectiveDegrees fov: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let f = 1.0 / tan(fov * .pi / 180.0 / 2.0)
        let range = far - near
        
        return simd.matrix_float4x4(
            SIMD4<Float>(f / aspect, 0, 0, 0),
            SIMD4<Float>(0, f, 0, 0),
            SIMD4<Float>(0, 0, -(far + near) / range, -1),
            SIMD4<Float>(0, 0, -(2 * far * near) / range, 0)
        )
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        
        // Vẽ grid thông thường (màu xanh lá đậm)
        encoder.setVertexBuffer(gridVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(gridUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(gridUniformBuffer, offset: 0, index: 1)
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: gridVertices.count)
        
        // Vẽ các trục với màu sáng hơn (đậm hơn)
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: 1)
        
        // Trục X - render nhiều lần để đậm hơn (5 lần vì nằm trên grid)
        encoder.setVertexBuffer(axisXVertexBuffer, offset: 0, index: 0)
        for _ in 0..<5 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisXVertices.count)
        }
        
        // Trục Z - render nhiều lần để đậm hơn (5 lần vì nằm trên grid)
        encoder.setVertexBuffer(axisZVertexBuffer, offset: 0, index: 0)
        for _ in 0..<5 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisZVertices.count)
        }
        
        // Trục Y - render 3 lần (đã đủ đậm vì không bị che)
        encoder.setVertexBuffer(axisYVertexBuffer, offset: 0, index: 0)
        for _ in 0..<3 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisYVertices.count)
        }
        
        // Vẽ tam giác
        triangleRenderer.render(encoder: encoder)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


