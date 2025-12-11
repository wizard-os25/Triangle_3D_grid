//
//  ShaderTypes.h
//  New_Name
//
//  Created by wizard.os25 on 4/12/25.
//

#pragma once
#include <simd/simd.h>

typedef enum BufferIndex {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1
} BufferIndex;

typedef struct {
    matrix_float4x4 model;
    matrix_float4x4 view;
    matrix_float4x4 proj;
    matrix_float4x4 normalMatrix;
    int isAxis;
    vector_float4 axisColor;
    // Material properties for Phong lighting
    vector_float3 materialAmbient;
    vector_float3 materialDiffuse;
    vector_float3 materialSpecular;
    float materialShininess;
    // Camera position in world space (for view direction calculation)
    vector_float3 cameraPosition;
} Uniforms;
