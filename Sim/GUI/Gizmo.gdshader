shader_type canvas_item;

uniform float opacity = 0.25;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float alpha = (1.0 - step(0.5, d))*opacity;
	COLOR = vec4(vec3(0), alpha);
}
