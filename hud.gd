extends Control

@onready var can_label: Label = $CanLabel

func _ready() -> void:
	GameManager.can_count_updated.connect(_update_ui)
	_update_ui(GameManager.cans_collected)

func _update_ui(count: int) -> void:
	can_label.text = "Cans: %d" % count
