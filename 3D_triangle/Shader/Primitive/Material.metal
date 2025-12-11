//
//  Material.metal
//  3D_triangle
//
//  Created by wizard.os25 on 10/12/25.
//

#include <metal_stdlib>
using namespace metal;

#import "../Types/ShaderTypes.h"
#import "../Lighting/PhongLighting.h"

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float3 viewPosition;
};

vertex VertexOut material_vertex_main(VertexIn v [[stage_in]],
                                      constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    VertexOut out;
    
    float4 worldPos = u.model * float4(v.position, 1.0);
    out.worldPosition = worldPos.xyz;
    
    float4 viewPos = u.view * worldPos;
    out.viewPosition = viewPos.xyz;
    
    float3 worldNormal = normalize((u.normalMatrix * float4(v.normal, 0.0)).xyz);
    out.worldNormal = worldNormal;
    
    out.position = u.proj * viewPos;
    
    return out;
}

fragment float4 material_fragment_main(VertexOut in [[stage_in]],
                                       constant Uniforms& u [[buffer(BufferIndexUniforms)]],
                                       constant DirectionalLight* directionalLights [[buffer(2)]],
                                       constant PointLight* pointLights [[buffer(3)]],
                                       constant LightingUniform& lightingUniform [[buffer(4)]]) {
    float3 normal = normalize(in.worldNormal);
    float3 viewDir = normalize(u.cameraPosition - in.worldPosition);
    
    float3 finalColor = computePhongLighting(
        in.worldPosition,
        normal,
        viewDir,
        u.materialAmbient,
        u.materialDiffuse,
        u.materialSpecular,
        u.materialShininess,
        directionalLights,
        lightingUniform.directionalLightCount,
        pointLights,
        lightingUniform.pointLightCount,
        lightingUniform
    );
    
    return float4(finalColor, 1.0);
}

vertex float4 material_edge_vertex_main(VertexIn v [[stage_in]],
                                        constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

fragment float4 material_edge_fragment_main() {
    return float4(1.0, 1.0, 1.0, 1.0);
}
