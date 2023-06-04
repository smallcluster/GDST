shader_type canvas_item;

void fragment() {
	
	float c = step(0.7, abs(sin(FRAGCOORD.x / 25.0 + FRAGCOORD.y / 37.5)));
	
	COLOR = vec4(c, c/1.25, 0, 1);
}
