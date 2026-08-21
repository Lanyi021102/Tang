shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float focus_y : hint_range(0.0, 1.0) = 0.5;
uniform float band_width : hint_range(0.0, 1.0) = 0.3;
uniform float blur_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 c = vec2(0.5, focus_y);
	float d = distance(UV, c);
	float f = smoothstep(band_width, band_width + 0.5, d);
	float r = f * blur_strength * 0.03;

	// 17-tap separable cross gaussian (horizontal + vertical)
	vec4 col = texture(screen_tex, UV) * 0.227027;
	col += texture(screen_tex, UV + vec2(r, 0.0)) * 0.194595;
	col += texture(screen_tex, UV - vec2(r, 0.0)) * 0.194595;
	col += texture(screen_tex, UV + vec2(0.0, r)) * 0.194595;
	col += texture(screen_tex, UV - vec2(0.0, r)) * 0.194595;
	col += texture(screen_tex, UV + vec2(r * 2.0, 0.0)) * 0.121622;
	col += texture(screen_tex, UV - vec2(r * 2.0, 0.0)) * 0.121622;
	col += texture(screen_tex, UV + vec2(0.0, r * 2.0)) * 0.121622;
	col += texture(screen_tex, UV - vec2(0.0, r * 2.0)) * 0.121622;
	col += texture(screen_tex, UV + vec2(r * 3.0, 0.0)) * 0.054054;
	col += texture(screen_tex, UV - vec2(r * 3.0, 0.0)) * 0.054054;
	col += texture(screen_tex, UV + vec2(0.0, r * 3.0)) * 0.054054;
	col += texture(screen_tex, UV - vec2(0.0, r * 3.0)) * 0.054054;
	col += texture(screen_tex, UV + vec2(r * 4.0, 0.0)) * 0.016216;
	col += texture(screen_tex, UV - vec2(r * 4.0, 0.0)) * 0.016216;
	col += texture(screen_tex, UV + vec2(0.0, r * 4.0)) * 0.016216;
	col += texture(screen_tex, UV - vec2(0.0, r * 4.0)) * 0.016216;
	COLOR = col;
}
