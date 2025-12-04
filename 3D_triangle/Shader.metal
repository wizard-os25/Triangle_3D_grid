//
//  Shader.metal
//  New_Name
//
//  Created by wizard.os25 on 4/12/25.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"

struct VertexIn {
    float3 position [[attribute(0)]];
};

vertex float4 vertex_main(VertexIn v [[stage_in]],
                          constant Uniforms& u [[buffer(BufferIndexUniforms)]])
{
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

fragment float4 fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]])
{
    if (u.isAxis == 1) {
        return float4(0.0, 1.0, 0.0, 1.0);
        ///                           Red, Green, Blue
    } else {
        return float4(0.0, 0.7, 0.0, 1.0);
    }
}

fragment float4 triangle_fragment_main()
{
    return float4(1.0, 0.0, 0.0, 1.0);
}

fragment float4 triangle_edge_fragment_main()
{
    return float4(1.0, 1.0, 1.0, 1.0);
}
