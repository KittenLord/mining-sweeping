#version 460
#pragma shader_stage(vertex)

struct Instance {
    mat4 model;
    vec4 col;
    vec4 padding;
};

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 model;
layout(location = 2) uniform mat4 view;
layout(location = 3) uniform mat4 proj;

layout(location = 0) in vec3 in_position;

layout(location = 0) out int out_instanceId;

void main() {
    Instance instance = instances[gl_InstanceID];

    gl_Position = proj * view * instance.model * vec4(in_position, 1.0);
    out_instanceId = gl_InstanceID;
}
