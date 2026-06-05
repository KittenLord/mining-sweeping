#version 460
#pragma shader_stage(fragment)

#include "tile.glslh"

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 proj;

layout(location = 0) in flat int in_instanceId;

layout(location = 0) out vec4 out_color;

void main() {
    Instance instance = instances[in_instanceId];

    out_color = vec4(1.0, 1.0, 1.0, 1.0);
}
