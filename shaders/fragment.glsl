#version 460
#pragma shader_stage(fragment)

layout(location = 0) out vec4 out_color;

void main() {
    out_color = vec4(0.5, 0.1, 0.1, 1.0);
}
