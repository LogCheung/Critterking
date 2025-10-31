extends Control
class_name Challenge

@export var type : UI.CHALLENGE
@export var enabled : bool

@onready var sprite: Sprite2D = %Sprite2D
@onready var ui : UI = get_tree().get_first_node_in_group("UI")

func _ready() -> void:
	sprite.frame = type - 1

func _process(delta: float) -> void:
	if !ui.ascensions.visible : return
	
	if !enabled:
		sprite.modulate = Color(0.557, 0.557, 0.557, 1.0)
	else:
		sprite.modulate = Color(1,1,1,1)
		
func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		ui.currentChal = type
		enabled = !enabled
		
		var chals = get_tree().get_nodes_in_group("CHAL")
		for c : Challenge in chals:
			if c == self: continue
			c.enabled = false
