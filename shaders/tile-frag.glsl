#version 460
#pragma shader_stage(fragment)

#include "tile.glslh"

layout(binding = 0) buffer buffer_instances {
    Instance instances[];
};

layout(location = 0) uniform float time;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 proj;
layout(location = 3) uniform float deco_offset;
layout(location = 4) uniform float deco_radius;

const float ISQRT2 = 1.0 / sqrt(2.0);

#define deco_size 0.5

layout(location = 0) in flat int in_instanceId;
layout(location = 1) in vec3 in_position;

layout(location = 0) out vec4 out_color;

float dist2(vec2 a, vec2 b) {
    return dot(a - b, a - b);
}

void main() {
    Instance instance = instances[in_instanceId];

    // TODO: we want some flag appearing animation thingy (at least a flag icon transparently appearing)
    vec3 color = mix(vec3(0.4, 0.4, 0.4), vec3(0.2, 0.7, 0.2), instance.lerp_Flag);
    float alpha = mix(1, 0, instance.lerp_Transparency);


    float bound_NN = -mix(deco_size, deco_offset, instance.lerp_NN);
    float bound_SS =  mix(deco_size, deco_offset, instance.lerp_SS);
    float bound_WW = -mix(deco_size, deco_offset, instance.lerp_WW);
    float bound_EE =  mix(deco_size, deco_offset, instance.lerp_EE);

    if(in_position.y < bound_NN) {
        discard;
    }
    if(in_position.y > bound_SS) {
        discard;
    }
    if(in_position.x < bound_WW) {
        discard;
    }
    if(in_position.x > bound_EE) {
        discard;
    }

#define EVALUATE_CENTER(a, b, as, bs) \
    float radius_##a##b = mix(0, deco_radius, instance.lerp_##a##b); \
    vec2 center_##a##b = vec2(bound_##b##b, bound_##a##a) + vec2(as * radius_##a##b, bs * radius_##a##b);

    EVALUATE_CENTER(N, W, 1, 1);
    EVALUATE_CENTER(N, E, -1, 1);
    EVALUATE_CENTER(S, W, 1, -1);
    EVALUATE_CENTER(S, E, -1, -1);

#define CHECK_RADIUS(a, b, as, bs) \
    dist2(in_position.xy, center_##a##b) > (radius_##a##b * radius_##a##b) && dot(normalize(in_position.xy - center_##a##b), vec2(as * ISQRT2, bs * ISQRT2)) > ISQRT2

    // TODO: this looks like this needs antialiasing - i reckon this is why SDFs are used, look into them
    if(CHECK_RADIUS(N, W, -1, -1)) {
        discard;
    }
    if(CHECK_RADIUS(N, E, 1, -1)) {
        discard;
    }
    if(CHECK_RADIUS(S, W, -1, 1)) {
        discard;
    }
    if(CHECK_RADIUS(S, E, 1, 1)) {
        discard;
    }

#define CHECK_IRADIUS(a, b, as, bs) \
    float iradius_##a##b = mix(0, (deco_size - deco_offset), instance.lerp_##a##b##I); \
    if(dist2(vec2(as * deco_size, bs * deco_size), in_position.xy) < iradius_##a##b * iradius_##a##b) { \
        discard; \
    }

    CHECK_IRADIUS(N, W, -1, -1);
    CHECK_IRADIUS(N, E,  1, -1);
    CHECK_IRADIUS(S, W, -1,  1);
    CHECK_IRADIUS(S, E,  1,  1);



    out_color = vec4(color, alpha);
}
