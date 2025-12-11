//
//  LightingFunctions.h
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

#ifndef LightingFunctions_h
#define LightingFunctions_h

#include <metal_stdlib>
#include "LightingTypes.h"
using namespace metal;

/// Compute directional light contribution with Blinn-Phong lighting
/// Directional light: like sunlight - parallel rays from infinite distance
/// - Parameters:
///   - normal: Surface normal (normalized, in world space)
///   - viewDir: View direction (normalized, from surface to camera)
///   - light: Directional light
///   - materialDiffuse: Material diffuse color (k_d) - how much light is scattered
///   - materialSpecular: Material specular color (k_s) - how much light is reflected
///   - shininess: Material shininess factor (higher = sharper, smaller highlight)
/// - Returns: Light contribution (RGB) = diffuse + specular
float3 computeDirectionalLight(float3 normal, float3 viewDir, DirectionalLight light,
                               float3 materialDiffuse, float3 materialSpecular, float shininess) {
    // Light direction: normalize and invert (light direction points FROM light, we need TO light)
    float3 lightDir = normalize(-light.direction);
    
    // Diffuse (Lambertian) - I_diffuse = k_d * LightColor * max(dot(N, L), 0)
    // Represents how much light is scattered in all directions
    // Like the bright side of a planet facing the sun
    float diff = max(dot(normal, lightDir), 0.0);
    float3 diffuse = diff * materialDiffuse * light.color * light.intensity;
    
    // Specular (Blinn-Phong) - faster than Phong original
    // H = half-vector between light and view direction
    // I_specular = k_s * LightColor * (max(dot(N, H), 0))^shininess
    // Represents the bright highlight spot (like sun reflection on planet surface)
    float3 H = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, H), 0.0), shininess);
    float3 specular = spec * materialSpecular * light.color * light.intensity * 1.2;
    
    return diffuse + specular;
}

/// Compute point light contribution with Blinn-Phong lighting
/// Point light: like a lightbulb - emits light in all directions from a position
/// - Parameters:
///   - position: Surface position in world space (for distance calculation)
///   - normal: Surface normal (normalized, in world space)
///   - viewDir: View direction (normalized, from surface to camera)
///   - light: Point light
///   - materialDiffuse: Material diffuse color (k_d)
///   - materialSpecular: Material specular color (k_s)
///   - shininess: Material shininess factor
/// - Returns: Light contribution (RGB) = diffuse + specular (with attenuation)
float3 computePointLight(float3 position, float3 normal, float3 viewDir, PointLight light,
                         float3 materialDiffuse, float3 materialSpecular, float shininess) {
    // Vector from surface to light
    float3 lightVec = light.position - position;
    float distance = length(lightVec);
    
    // Early exit if beyond light radius
    if (distance > light.radius) {
        return float3(0.0);
    }
    
    float3 lightDir = normalize(lightVec);
    
    // Attenuation: light gets weaker with distance
    // Inverse square falloff with radius limit
    float attenuation = 1.0 / (1.0 + (distance / light.radius) * (distance / light.radius));
    
    // Diffuse (Lambertian)
    float diff = max(dot(normal, lightDir), 0.0);
    float3 diffuse = diff * materialDiffuse * light.color * light.intensity * attenuation;
    
    // Specular (Blinn-Phong)
    float3 H = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, H), 0.0), shininess);
    float3 specular = spec * materialSpecular * light.color * light.intensity * attenuation;
    
    return diffuse + specular;
}

#endif /* LightingFunctions_h */

