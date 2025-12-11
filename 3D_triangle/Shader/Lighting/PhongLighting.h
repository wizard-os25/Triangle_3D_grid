//
//  PhongLighting.h
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

#ifndef PhongLighting_h
#define PhongLighting_h

#include <metal_stdlib>
#include "LightingTypes.h"
#include "LightingFunctions.h"
using namespace metal;

/// Blinn-Phong lighting model (as per Phong.md specification)
/// 
/// Phong lighting consists of three components:
/// 1. Ambient: Base light level (like starlight in space) - I_ambient = k_a * LightColor
/// 2. Diffuse: Scattered light (like bright side of planet) - I_diffuse = k_d * LightColor * max(dot(N, L), 0)
/// 3. Specular: Reflected highlight (like sun reflection) - I_specular = k_s * LightColor * (max(dot(N, H), 0))^shininess
///
/// - Parameters:
///   - position: Surface position in world space (for point lights)
///   - normal: Surface normal (normalized, in world space)
///   - viewDir: View direction (normalized, from surface to camera)
///   - materialAmbient: Material ambient color (k_a) - base color in shadow
///   - materialDiffuse: Material diffuse color (k_d) - how much light is scattered
///   - materialSpecular: Material specular color (k_s) - how much light is reflected
///   - shininess: Material shininess factor (higher = sharper highlight)
///   - directionalLights: Array of directional lights (like sunlight)
///   - directionalLightCount: Number of active directional lights
///   - pointLights: Array of point lights (like lightbulbs)
///   - pointLightCount: Number of active point lights
///   - lightingUniform: Lighting uniform data (ambient color, light counts)
/// - Returns: Final lit color (RGB) = ambient + sum of all light contributions
float3 computePhongLighting(float3 position,
                            float3 normal,
                            float3 viewDir,
                            float3 materialAmbient,
                            float3 materialDiffuse,
                            float3 materialSpecular,
                            float shininess,
                            constant DirectionalLight* directionalLights,
                            uint directionalLightCount,
                            constant PointLight* pointLights,
                            uint pointLightCount,
                            constant LightingUniform& lightingUniform) {
    // Ambient component: I_ambient = k_a * LightColor
    // Like starlight in space - always present, even in shadow
    float3 ambient = materialAmbient * lightingUniform.ambientColor;
    
    // Accumulate lighting from all light sources
    float3 lighting = float3(0.0);
    
    // Process directional lights (like sunlight)
    uint dirLightCount = min(directionalLightCount, uint(MAX_DIRECTIONAL_LIGHTS));
    for (uint i = 0; i < dirLightCount; i++) {
        lighting += computeDirectionalLight(normal, viewDir, directionalLights[i],
                                            materialDiffuse, materialSpecular, shininess);
    }
    
    // Process point lights (like lightbulbs)
    uint ptLightCount = min(pointLightCount, uint(MAX_POINT_LIGHTS));
    for (uint i = 0; i < ptLightCount; i++) {
        lighting += computePointLight(position, normal, viewDir, pointLights[i],
                                     materialDiffuse, materialSpecular, shininess);
    }
    
    // Final color = ambient + all light contributions
    float3 finalColor = ambient + lighting;
    
    // Clamp to valid color range [0, 1]
    return clamp(finalColor, 0.0, 1.0);
}

#endif /* PhongLighting_h */
