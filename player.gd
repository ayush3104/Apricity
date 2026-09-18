extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const WATER_LEVEL: float = 3.5
const MOUSE_SENSITIVITY: float = 0.003

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	# Lock and hide the mouse cursor for 3D camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Press ESC to release or re-capture the mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotate camera with mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate body left/right (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Tilt spring arm up/down (pitch) with limits
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-65.0), deg_to_rad(45.0))

func _physics_process(delta: float) -> void:
	var in_water = global_position.y < WATER_LEVEL

	if in_water:
		var depth = WATER_LEVEL - global_position.y
		velocity.y = lerp(velocity.y, depth * 6.0, delta * 8.0)
		velocity.x *= 0.88
		velocity.z *= 0.88

		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY * 0.85
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

	# Movement relative to the player's current facing direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = SPEED * (0.65 if in_water else 1.0)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Push RigidBodies (Junk / Cans / Tires)
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			var push_force = 4.0
			c.get_collider().apply_central_impulse(push_dir * push_force)
