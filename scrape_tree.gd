extends StaticBody3D

@onready var branches: Node3D = get_node_or_null("Branches")
@onready var trunk: MeshInstance3D = get_node_or_null("Trunk")

func _ready() -> void:
	randomize_tree()

func randomize_tree() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Slight overall tree scale variation (0.85x to 1.25x)
	var tree_scale = rng.randf_range(0.85, 1.25)
	scale = Vector3.ONE * tree_scale

	# If there are no branch nodes set up yet, stop here without crashing
	if not branches:
		return

	var branch_list = branches.get_children()
	if branch_list.is_empty():
		return

	var step = 1.6 / float(branch_list.size())

	for i in range(branch_list.size()):
		var branch = branch_list[i] as Node3D
		if not branch:
			continue

		# 1. Height variation
		var base_height = 1.2 + (i * step)
		var height_offset = rng.randf_range(-0.25, 0.25)
		branch.position.y = base_height + height_offset

		# 2. Angle variation
		var base_angle = (TAU / branch_list.size()) * i
		var angle_jitter = rng.randf_range(-0.4, 0.4)
		branch.rotation.y = base_angle + angle_jitter

		# 3. Branch size variation
		var b_scale = rng.randf_range(0.75, 1.15)
		branch.scale = Vector3.ONE * b_scale
