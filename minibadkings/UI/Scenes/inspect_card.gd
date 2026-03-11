extends Control

@onready var ui : UI = get_tree().get_first_node_in_group("UI")


func _input(event: InputEvent) -> void:
	if event.is_action("pause"):
		self.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("select"):
		self.visible = false
