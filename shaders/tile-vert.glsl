#version 460
#pragma shader_stage(vertex)

#include "tile.glslh"

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
layout(location = 1) out vec3 out_position;

void main() {
    Instance instance = instances[gl_InstanceID];

    gl_Position = proj * view * instance.model * vec4(in_position * mix(1, 0, instance.lerp_Scale), 1.0);
    out_instanceId = gl_InstanceID;
    out_position = in_position;
}
