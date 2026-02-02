extends Control
class_name InfoOverlay

@export var assignMode : bool = false

@onready var ui : UI = get_parent()
@onready var assign_toggle_sprite: Sprite2D = %AssignToggleSprite

func _ready() -> void:
	assign_toggle_sprite.frame = 0
	assign_toggle_sprite.modulate.v = 1
	
	var colorMask = get_tree().get_first_node_in_group("COLORMASK")
	colorMask.visible = false

func _on_assign_toggle_gui_input(event: InputEvent) -> void:
	if event.is_action_released("select"):
		assignMode = !assignMode
		assign_toggle_sprite.frame = 1 if assignMode else 0
		assign_toggle_sprite.modulate.v = 1.5 if assignMode else 1
		
		var colorMask = get_tree().get_first_node_in_group("COLORMASK")
		colorMask.visible = assignMode
		
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		for b : Building in buildings:
			b.toggle.visible = assignMode
			ui.hand.visible = !assignMode
