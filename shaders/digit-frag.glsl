#version 460
#pragma shader_stage(fragment)

#include "tile.glslh"

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 proj;
layout(location = 3) uniform sampler2D tex;

layout(location = 0) in flat int in_instanceId;
layout(location = 1) in vec2 in_texCoord;

layout(location = 0) out vec4 out_color;

void main() {
    Instance instance = instances[in_instanceId];

    if(instance.opened == 0) {
        discard;
    }

    if(instance.digit == 0) {
        discard;
    }

    vec2 texCoord = vec2(in_texCoord.x * (1.0 / 8.0) + (float(instance.digit - 1) / 8.0), in_texCoord.y);

    vec4 col = texture(tex, texCoord);

    out_color = vec4(col.r, 0, 0, col.a);
}
