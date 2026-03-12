@tool
extends Label

@export var resourceType : Global.RESOURCETYPE
@export var traitType : Global.TRAITTYPE

@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	if resourceType != Global.RESOURCETYPE.NONE:
		match_sprite_resource()
	else:
		match_sprite_trait()

func match_sprite_resource() -> void:
	match resourceType:
		Global.RESOURCETYPE.SATISFACTION:
			sprite_2d.frame = 8
		Global.RESOURCETYPE.FOOD:
			sprite_2d.frame = 9
		Global.RESOURCETYPE.MONEY:
			sprite_2d.frame = 5
		Global.RESOURCETYPE.CITIZEN:
			sprite_2d.frame = 6
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
	
