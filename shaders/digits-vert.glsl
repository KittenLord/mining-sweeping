#version 460
#pragma shader_stage(vertex)

struct Instance {
    mat4 model;

    float lerp_NW;
    float lerp_NN;
    float lerp_NE;
    float lerp_EE;
    float lerp_SE;
    float lerp_SS;
    float lerp_SW;
    float lerp_WW;
    float lerp_NWI;
    float lerp_NEI;
    float lerp_SWI;
    float lerp_SEI;
    float lerp_Transparency;
    float lerp_Scale;

    uint opened;

    uint paddingA[1];
    // uint paddingB[0];
};

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 proj;
layout(location = 3) uniform float deco_offset;
layout(location = 4) uniform float deco_radius;

layout(location = 0) in vec3 in_position;

layout(location = 0) out int out_instanceId;

void main() {
    Instance instance = instances[gl_InstanceID];

    gl_Position = proj * view * vec4(in_position, 1.0);
    out_instanceId = gl_InstanceID;
}
