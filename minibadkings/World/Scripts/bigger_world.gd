extends Node2D
class_name Big

@export var world : World
@export var ui : UI

func _ready() -> void:
	world = get_tree().get_first_node_in_group("WORLD")
	ui = get_tree().get_first_node_in_group("UI")
