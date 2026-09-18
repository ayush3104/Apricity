extends StaticBody3D

@export var can_scene: PackedScene
@export var max_cans: int = 5

@onready var interact_zone: Area3D = $InteractZone
@onready var spawn_point: Marker3D = $CanSpawnPoint

var player_nearby: bool = false
var cans_remaining: int

func _ready() -> void:
	cans_remaining = max_cans
	interact_zone.body_entered.connect(_on_body_entered)
	interact_zone.body_exited.connect(_on_body_exited)

func _is_player(body: Node) -> bool:
	if body.is_in_group("player") or body.name == "Player":
		return true
	if body.get_parent() and (body.get_parent().is_in_group("player") or body.get_parent().name == "Player"):
		return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if _is_player(body):
		player_nearby = true

func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		player_nearby = false

func _input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact") and cans_remaining > 0:
		dispense_can()

func dispense_can() -> void:
	if not can_scene:
		push_error("No valid PackedScene assigned to Can Scene!")
		return

	var can = can_scene.instantiate()
	if not can:
		push_error("Failed to instantiate Can Scene!")
		return

	cans_remaining -= 1

	if spawn_point:
		can.position = spawn_point.global_position
	else:
		can.position = global_position + Vector3(0.0, 0.5, 0.0)

	get_tree().current_scene.add_child(can)

	if can is RigidBody3D:
		var eject_dir = -global_transform.basis.z + Vector3(0.0, 0.4, 0.0)
		var jitter = Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
		can.apply_central_impulse((eject_dir + jitter).normalized() * 3.5)
		can.apply_torque_impulse(Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		))
