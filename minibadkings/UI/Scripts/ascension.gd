extends Control
class_name Ascension

@export var number : int 
@export var enabled : bool 
@export var unlocked : bool

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var sprite: Sprite2D = %Sprite2D

func _ready() -> void:
	sprite.frame = number - 1

func _process(delta: float) -> void:
	if !ui.ascensions.visible : return
	unlocked = Global.maxAscension >= number
	
	if !unlocked:
		sprite.frame = 10
	elif !enabled:
		sprite.modulate = Color(0.557, 0.557, 0.557, 1.0)
	else:
		sprite.modulate = Color(1,1,1,1)

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		enabled = !enabled
		
		var ascens = get_tree().get_nodes_in_group("ASCEN")
		if enabled:
			ascens = ascens.filter(func(a):return a.number < number)
			ui.currentAscn = number
		else:
			ascens = ascens.filter(func(a):return a.number > number)
			ui.currentAscn = number - 1
		for a : Ascension in ascens:
			a.enabled = enabled
