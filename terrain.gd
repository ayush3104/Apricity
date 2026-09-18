extends MeshInstance3D

@onready var col_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready() -> void:
	var mat = material_override as ShaderMaterial
	if not mat:
		mat = get_active_material(0) as ShaderMaterial
	if not mat:
		return

	var noise_tex = mat.get_shader_parameter("height_noise") as NoiseTexture2D
	var height_scale = mat.get_shader_parameter("height_scale") as float
	
	if not noise_tex:
		return

	# Ensure the noise texture has finished generating on the CPU
	var img = noise_tex.get_image()
	if not img:
		await noise_tex.changed
		img = noise_tex.get_image()
	
	if not img:
		return

	var map_width = 121
	var map_depth = 121
	var heights = PackedFloat32Array()
	heights.resize(map_width * map_depth)

	var img_w = img.get_width()
	var img_h = img.get_height()

	for z in range(map_depth):
		for x in range(map_width):
			# Map sample coordinates exactly to the PlaneMesh UV space
			var px = int(clamp(float(x) / float(map_width - 1) * (img_w - 1), 0, img_w - 1))
			var py = int(clamp(float(z) / float(map_depth - 1) * (img_h - 1), 0, img_h - 1))
			
			var h = img.get_pixel(px, py).r
			
			# Plateau math matching main.gdshader
			if h > 0.45 and h < 0.55:
				h = lerp(h, 0.5, 0.6)
				
			heights[z * map_width + x] = h * height_scale

	var h_shape = HeightMapShape3D.new()
	h_shape.map_width = map_width
	h_shape.map_depth = map_depth
	h_shape.map_data = heights
	
	col_shape.shape = h_shape
	
	# Scale collision bounds to match the 180x180 PlaneMesh
	var scale_factor = 180.0 / float(map_width - 1)
	col_shape.scale = Vector3(scale_factor, 1.0, scale_factor)
	col_shape.position = Vector3.ZERO
	col_shape.rotation = Vector3.ZERO
