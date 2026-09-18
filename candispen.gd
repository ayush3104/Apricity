extends StaticBody3D

@export var can_scene: PackedScene
@onready var dispense_point: Marker3D = get_node_or_null("DispensePoint")
@onready var bump_zone: Area3D = get_node_or_null("BumpZone")

var can_ready: bool = true

func _ready() -> void:
	if bump_zone:
		bump_zone.body_entered.connect(_on_bump)

func _on_bump(body: Node3D) -> void:
	if not can_ready or not (body is CharacterBody3D):
		return
	can_ready = false
	dispense_can()
	await get_tree().create_timer(1.2).timeout
	can_ready = true

func dispense_can() -> void:
	if not can_scene or not dispense_point:
		return
	var can = can_scene.instantiate() as RigidBody3D
	get_parent().add_child(can)
	can.global_position = dispense_point.global_position
	var shoot_dir = -global_transform.basis.z + Vector3.UP * 0.4
	can.apply_central_impulse(shoot_dir * 4.0)
