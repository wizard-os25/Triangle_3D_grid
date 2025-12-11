//
//  LightingManager.swift
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

import Foundation
import Metal
import simd

final class LightingManager {
    var directionalLights: [DirectionalLight] = []
    var pointLights: [PointLight] = []
    
    private var directionalLightBuffer: MTLBuffer?
    private var pointLightBuffer: MTLBuffer?
    private var lightingUniformBuffer: MTLBuffer?
    
    private let device: MTLDevice
    private let maxDirectionalLights = 4
    private let maxPointLights = 8
    private var ambientColor: SIMD3<Float> = SIMD3<Float>(0.2, 0.2, 0.2)
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func setAmbientColor(_ color: SIMD3<Float>) {
        ambientColor = color
    }
    
    func addDirectionalLight(_ light: DirectionalLight) {
        directionalLights.append(light)
        if directionalLights.count > maxDirectionalLights {
            directionalLights.removeFirst()
        }
    }
    
    func addPointLight(_ light: PointLight) {
        pointLights.append(light)
        if pointLights.count > maxPointLights {
            pointLights.removeFirst()
        }
    }
    
    func updateBuffers() {
        var dirLightsData: [DirectionalLightData] = []
        for light in directionalLights {
            dirLightsData.append(DirectionalLightData(
                direction: light.direction,
                color: light.color,
                intensity: light.intensity
            ))
        }
        while dirLightsData.count < maxDirectionalLights {
            dirLightsData.append(DirectionalLightData(
                direction: SIMD3<Float>(0, 0, 0),
                color: SIMD3<Float>(0, 0, 0),
                intensity: 0.0
            ))
        }
        
        directionalLightBuffer = device.makeBuffer(bytes: dirLightsData,
                                                   length: MemoryLayout<DirectionalLightData>.stride * maxDirectionalLights,
                                                   options: [])
        
        var pointLightsData: [PointLightData] = []
        for light in pointLights {
            pointLightsData.append(PointLightData(
                position: light.position,
                color: light.color,
                intensity: light.intensity,
                radius: light.radius
            ))
        }
        while pointLightsData.count < maxPointLights {
            pointLightsData.append(PointLightData(
                position: SIMD3<Float>(0, 0, 0),
                color: SIMD3<Float>(0, 0, 0),
                intensity: 0.0,
                radius: 0.0
            ))
        }
        
        pointLightBuffer = device.makeBuffer(bytes: pointLightsData,
                                            length: MemoryLayout<PointLightData>.stride * maxPointLights,
                                            options: [])
        
        var lightingUniform = LightingUniform(
            directionalLightCount: UInt32(directionalLights.count),
            pointLightCount: UInt32(pointLights.count),
            ambientColor: ambientColor
        )
        
        lightingUniformBuffer = device.makeBuffer(bytes: &lightingUniform,
                                                  length: MemoryLayout<LightingUniform>.stride,
                                                  options: [])
    }
    
    func bindToEncoder(_ encoder: MTLRenderCommandEncoder) {
        if let dirBuffer = directionalLightBuffer {
            encoder.setFragmentBuffer(dirBuffer, offset: 0, index: 2)
        }
        if let pointBuffer = pointLightBuffer {
            encoder.setFragmentBuffer(pointBuffer, offset: 0, index: 3)
        }
        if let uniformBuffer = lightingUniformBuffer {
            encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 4)
        }
    }
}

struct DirectionalLightData {
    var direction: SIMD3<Float>
    var color: SIMD3<Float>
    var intensity: Float
}

struct PointLightData {
    var position: SIMD3<Float>
    var color: SIMD3<Float>
    var intensity: Float
    var radius: Float
}

struct LightingUniform {
    var directionalLightCount: UInt32
    var pointLightCount: UInt32
    var ambientColor: SIMD3<Float>
}
