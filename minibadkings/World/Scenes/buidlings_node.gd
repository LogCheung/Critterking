extends Node2D
class_name BuildingsNode

@onready var ui : UI = get_tree().get_first_node_in_group("UI")

func _update_traits() -> void:
	ui.culture_trait
	pass
