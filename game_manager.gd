extends Node

var cans_collected: int = 0
signal can_count_updated(new_count: int)

func add_can() -> void:
	cans_collected += 1
	can_count_updated.emit(cans_collected)
