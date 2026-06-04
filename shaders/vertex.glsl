#version 460
#pragma shader_stage(vertex)

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 model;
layout(location = 2) uniform mat4 view;
layout(location = 3) uniform mat4 proj;

layout(location = 0) in vec3 in_position;

void main() {
    gl_Position = proj * view * model * vec4(in_position, 1.0);
}
