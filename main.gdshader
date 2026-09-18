shader_type spatial;

uniform sampler2D height_noise;
uniform float height_scale = 18.0;
uniform vec4 ground_color : source_color = vec4(0.85, 0.78, 0.72, 1.0);

void vertex() {
	// Sample the noise texture to get the height for this vertex
	float h = texture(height_noise, UV).r;
	// Move the vertex upwards on the Y axis
	VERTEX.y += h * height_scale;
}

void fragment() {
	ALBEDO = ground_color.rgb;
	ROUGHNESS = 0.8;
}
