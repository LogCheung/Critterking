@tool
extends CharacterBody2D
class_name UnitGroup

const UNIT = preload("res://Units/Scenes/unit.tscn")

@export var size : int = 9
@export var max_size : int
@export var type : int

var x_sep : int = 15 # distance horizontally between units in group
var y_sep : int = 15# distance between horizontal rows of units in group
var columns : int = 3
var rows : int

func _ready() -> void:
	create_formation()

func create_formation() -> void:
	# clear all units and create new formation based on size
	for child in %UnitsNode.get_children():
		child.queue_free()
	
	# attempt to make square formation
	rows = size / columns
	if size % columns != 0:  rows += 1
	
	var last_pos : Vector2 = Vector2(-(x_sep * columns)/2,-(y_sep * rows)/2 )
	for r in range(rows):
		for c in range(columns):
			# add unit
			var unit : Unit = UNIT.instantiate()
			unit.position = last_pos + Vector2(x_sep * 2,0)
			unit.rotation -= rotation
			last_pos = unit.position
			%UnitsNode.add_child(unit)
			
			# add permanent formation position to unit
			var formation_pos = Node2D.new()
			formation_pos.position = unit.position
			unit.add_child(formation_pos)
			unit.formation_position = formation_pos
		last_pos += Vector2(-x_sep * columns * 2,y_sep) # add margin for next row
