shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float vignette_intensity = 0.4;
uniform float vignette_opacity = 0.8;
uniform vec4 smoke_color : source_color = vec4(0.1, 0.0, 0.0, 0.2);
uniform float smoke_speed = 0.1;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    // Vignette
    float uv_dist = distance(UV, vec2(0.5));
    float vignette = smoothstep(0.0, vignette_intensity, uv_dist);
    vec4 final_color = mix(COLOR, vignette_color, vignette * vignette_opacity);
    
    // Smoke
    vec2 smoke_uv = UV * 4.0;
    smoke_uv.y -= TIME * smoke_speed;
    smoke_uv.x += sin(TIME * 0.5) * 0.2;
    float n = noise(smoke_uv);
    
    vec4 smoke = smoke_color * n * (1.0 - uv_dist);
    
    COLOR = final_color + smoke;
}
