@tool
class_name OverlayCounter
extends Label

@export var resourceType : Global.RESOURCETYPE
@export var army : bool = false
@export var traitType : Global.TRAITTYPE

@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	if resourceType != Global.RESOURCETYPE.NONE:
		match_sprite_resource()
	else:
		match_sprite_trait()
		
	if army:
		sprite_2d.frame = 7

func match_sprite_resource() -> void:
	match resourceType:
		Global.RESOURCETYPE.SATISFACTION:
			sprite_2d.frame = 8
		Global.RESOURCETYPE.FOOD:
			sprite_2d.frame = 9
		Global.RESOURCETYPE.MONEY:
			sprite_2d.frame = 10
		Global.RESOURCETYPE.CITIZEN:
			sprite_2d.frame = 6
		Global.RESOURCETYPE.HOUSE:
			sprite_2d.frame = 4
func match_sprite_trait() -> void:
	match traitType:
		Global.TRAITTYPE.FAME:
			sprite_2d.frame = 0
		Global.TRAITTYPE.CULTURE:
			sprite_2d.frame = 1
		Global.TRAITTYPE.PRODUCTIVITY:
			sprite_2d.frame = 2
		Global.TRAITTYPE.COMMERCE:
			sprite_2d.frame = 3
	
func set_value(value : int) -> void:
	if army or value == int(text): return
	# if isn't army counter or value doesn't change then continue
	
	if value != int(text):
		print("wow")
		var pop : Pop = preload("res://UI/Scenes/pop.tscn").instantiate()
		add_child(pop)
		pop.global_position = global_position + Vector2(0,80)
		pop.show_value(value - int(text),false)
	
	text = str(value)
	pass
