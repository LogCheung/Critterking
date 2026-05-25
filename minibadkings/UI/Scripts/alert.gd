class_name ColonyAlert
extends Control



enum TYPE {
	NONE, MILITIA, REBELS, STARVING, WAGES
}

@export var type : ColonyAlert.TYPE = TYPE.NONE

@onready var texRect: TextureRect = $TextureRect

static var alertCountDict : Dictionary = {
	TYPE.NONE : 0,
	TYPE.MILITIA : 0,
	TYPE.REBELS : 0,
	TYPE.STARVING : 0,
	TYPE.WAGES : 0,
}

func _ready() -> void:
	match_type()

func match_type() -> void:
	if type == TYPE.NONE : return
	texRect.texture = load("res://UI/Assets/alerts/" + TYPE.keys()[type].to_lower() + ".png")
	pass
