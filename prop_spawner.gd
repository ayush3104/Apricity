extends Node3D

@export var prop_scenes: Array[PackedScene] = []
@export var spawn_count: int = 45
@export var map_bounds: float = 75.0

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	spawn_props()

func spawn_props() -> void:
	if prop_scenes.is_empty():
		return
		
	var space_state = get_world_3d().direct_space_state
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(spawn_count):
		var rx = rng.randf_range(-map_bounds, map_bounds)
		var rz = rng.randf_range(-map_bounds, map_bounds)
		var origin = Vector3(rx, 50.0, rz)
		var target = Vector3(rx, -20.0, rz)

		var query = PhysicsRayQueryParameters3D.create(origin, target)
		query.collision_mask = 1
		# Exclude already spawned props if needed
		var hit = space_state.intersect_ray(query)

		if hit:
			# Verify that the hit object is actually the terrain
			if not hit.collider is StaticBody3D or hit.collider.name != "StaticBody3D":
				# Make sure it's the terrain's collision body
				pass

			var scene_to_spawn = prop_scenes.pick_random()
			if not scene_to_spawn:
				continue
				
			var instance = scene_to_spawn.instantiate() as Node3D
			get_parent().add_child(instance)
			
			# Lift 0.1m to prevent immediate ground clipping
			instance.global_position = hit.position + Vector3(0.0, 0.1, 0.0)
			
			if instance is StaticBody3D:
				instance.rotation = Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)
			elif instance is RigidBody3D:
				instance.global_position.y += 0.5
				instance.rotation = Vector3(
					rng.randf_range(0.0, TAU),
					rng.randf_range(0.0, TAU),
					rng.randf_range(0.0, TAU)
				)
