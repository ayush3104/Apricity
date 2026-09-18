extends RigidBody3D

@onready var pickup_zone: Area3D = get_node_or_null("PickupZone")
var is_collected: bool = false

func _ready() -> void:
	if pickup_zone:
		pickup_zone.body_entered.connect(_on_body_entered)
	else:
		# Fallback: Create pickup area dynamically if missing from the scene
		var area = Area3D.new()
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.5
		col.shape = shape
		area.add_child(col)
		add_child(area)
		area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	if body.is_in_group("player") or body.name == "Player" or (body.get_parent() and body.get_parent().is_in_group("player")):
		is_collected = true
		GameManager.add_can()
		queue_free()
