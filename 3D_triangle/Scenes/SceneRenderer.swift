//
//  SceneRenderer.swift
//  3D_triangle
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

class SceneRenderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var depthStencilState: MTLDepthStencilState!
    
    var gridRenderer: GridRenderer!
    var axisRenderer: AxisRenderer!
    var triangleRenderer: TriangleRenderer!
    var sphereRenderer: SphereRenderer!
    
    private var lastUpdateTime: CFTimeInterval = 0
    
    let camera: Camera
    let cameraController: OrbitCameraController
    let lightingManager: LightingManager
    
    var viewSize: CGSize = CGSize(width: 0, height: 0)
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        camera = Camera()
        cameraController = OrbitCameraController(camera: camera)
        lightingManager = LightingManager(device: device)
        
        // Sun-like directional light (from upper right, simulating sunlight)
        let sunLight = DirectionalLight(
            direction: SIMD3<Float>(0.3, 1.0, -0.5),  // From upper right-front
            color: SIMD3<Float>(1.0, 0.95, 0.8),      // Warm white/yellow sunlight
            intensity: 3.5                            // Strong intensity for clear lighting
        )
        lightingManager.addDirectionalLight(sunLight)
        // Balanced ambient - enough to see sphere but maintain contrast
        lightingManager.setAmbientColor(SIMD3<Float>(0.1, 0.1, 0.15))
        lightingManager.updateBuffers()
        
        gridRenderer = GridRenderer(device: device)
        axisRenderer = AxisRenderer(device: device)
        triangleRenderer = TriangleRenderer(device: device)
        sphereRenderer = SphereRenderer(device: device)
        
        setupDepthStencil()
    }
    
    func setViewSize(_ size: CGSize) {
        viewSize = size
        updateUniforms()
    }
    
    private func setupDepthStencil() {
        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }
    
    func updateUniforms() {
        guard viewSize.width > 0 && viewSize.height > 0 else { return }
        
        let aspect = Float(viewSize.width / max(viewSize.height, 1.0))
        
        let viewMatrix = camera.viewMatrix()
        let projMatrix = camera.projectionMatrix(aspect: aspect)
        let cameraPosition = camera.position()
        
        let currentTime = CACurrentMediaTime()
        if lastUpdateTime > 0 {
            let deltaTime = Float(currentTime - lastUpdateTime)
            sphereRenderer.update(deltaTime: deltaTime)
        }
        lastUpdateTime = currentTime
        
        let modelMatrix = matrix_float4x4(1)
        gridRenderer.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix, cameraPosition: cameraPosition)
        axisRenderer.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix, cameraPosition: cameraPosition)
        triangleRenderer.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix, cameraPosition: cameraPosition)
        sphereRenderer.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix, cameraPosition: cameraPosition)
    }
    
    func render(descriptor: MTLRenderPassDescriptor, drawable: CAMetalDrawable) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        updateUniforms()
        
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setDepthStencilState(depthStencilState)
        
        lightingManager.updateBuffers()
        lightingManager.bindToEncoder(encoder)
        
        gridRenderer.render(encoder: encoder)
        triangleRenderer.render(encoder: encoder)
        sphereRenderer.render(encoder: encoder)
        axisRenderer.render(encoder: encoder)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    var controller: OrbitCameraController {
        return cameraController
    }
}
