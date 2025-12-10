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
    int isAxis;
} Uniforms;
