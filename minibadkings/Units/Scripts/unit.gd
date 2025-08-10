extends CharacterBody2D
class_name Unit

const HIGHLIGHT = preload("res://Units/Shaders/unitHighlight.tres")
@export var formation_position : Node2D 

@onready var sprite_2d: Sprite2D = $Sprite2D

signal selected
signal unselected

func _ready() -> void:
	selected.connect(on_selected)
	unselected.connect(on_unselected)
	
func on_selected() -> void:
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null
