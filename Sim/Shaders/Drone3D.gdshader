shader_type spatial;

instance uniform vec3 color = vec3(0.02);

void fragment() {
	ALBEDO = color;
}
