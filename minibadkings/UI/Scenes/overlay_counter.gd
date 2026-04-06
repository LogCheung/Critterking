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

func set_value(value : int, showAnim : bool = true) -> void:
	if army or value == int(text): return
	var children = get_children().filter(func(e):return e is Pop)
	if !children.is_empty():
		# first child will be another pop scene
		await get_tree().create_timer(.5).timeout
	# if isn't army counter or value doesn't change then continue
	
	# show change animation
	if value != int(text) and showAnim:
		var pop : Pop = preload("res://UI/Scenes/pop.tscn").instantiate()
		add_child(pop)
		pop.global_position = global_position + Vector2(8,80)
		pop.show_value(value - int(text))
	
	text = str(value)
