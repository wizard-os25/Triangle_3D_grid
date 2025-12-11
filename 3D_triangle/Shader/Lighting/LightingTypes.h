//
//  LightingTypes.h
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

#ifndef LightingTypes_h
#define LightingTypes_h

#include <metal_stdlib>
using namespace metal;

// Maximum number of lights
#define MAX_DIRECTIONAL_LIGHTS 4
#define MAX_POINT_LIGHTS 8

// Directional light structure (like sunlight - infinite distance, parallel rays)
struct DirectionalLight {
    float3 direction;  // Normalized direction vector (from light source)
    float3 color;      // Light color (RGB)
    float intensity;   // Light intensity multiplier
};

// Point light structure (like a lightbulb - emits light in all directions from a position)
struct PointLight {
    float3 position;   // Light position in world space
    float3 color;      // Light color (RGB)
    float intensity;   // Light intensity multiplier
    float radius;      // Maximum distance the light affects
};

// Lighting uniform structure (per-frame lighting data)
struct LightingUniform {
    uint directionalLightCount;  // Number of active directional lights
    uint pointLightCount;        // Number of active point lights
    float3 ambientColor;         // Global ambient light color
};

#endif /* LightingTypes_h */

