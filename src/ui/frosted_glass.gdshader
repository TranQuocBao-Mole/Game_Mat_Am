shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform vec4 tint_color : source_color = vec4(0.05, 0.05, 0.05, 0.6);

void fragment() {
    vec4 blurred_color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    vec4 final_color = mix(blurred_color, tint_color, tint_color.a);
    
    // Add subtle scanlines or noise for "dark horror" feel
    float scanline = sin(UV.y * 400.0) * 0.02;
    final_color.rgb += scanline;
    
    COLOR = final_color;
}
