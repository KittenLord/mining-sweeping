#version 460
#pragma shader_stage(fragment)

struct Instance {
    mat4 model;
    vec4 col;
    vec4 padding;
};

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) in flat int in_instanceId;

layout(location = 0) out vec4 out_color;

void main() {
    Instance instance = instances[in_instanceId];

    out_color = vec4(instance.col.xyz, 1.0);
}
