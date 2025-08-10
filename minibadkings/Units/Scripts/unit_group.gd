@tool
extends CharacterBody2D
class_name UnitGroup

const UNIT = preload("res://Units/Scenes/unit.tscn")

@export var size : int = 9
@export var max_size : int
@export var type : int
@export var selected : bool = false

@onready var tileWorld

var x_sep : int = -10
var y_sep : int = 4
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
	
	var new_row_margin = -(x_sep)
	var last_pos : Vector2 = Vector2(new_row_margin,-15 )
	for r in range(rows):
		for c in range(columns):
			# add unit
			var unit : Unit = UNIT.instantiate()
			unit.position = last_pos + Vector2(x_sep,y_sep)
			unit.rotation -= rotation
			last_pos = unit.position
			%UnitsNode.add_child(unit)
			
			# add permanent formation position to unit
			var formation_pos = Node2D.new()
			formation_pos.position = unit.position
			%PositionsNode.add_child(formation_pos)
			unit.formation_position = formation_pos
		last_pos += Vector2(abs(x_sep) * 2.75,-y_sep) # add margin for next row
		last_pos -= Vector2(x_sep,y_sep) # new row margin

var is_under_mouse : bool = false
func _on_select_area_mouse_entered() -> void:
	is_under_mouse = true
	for unit : Unit in %UnitsNode.get_children():
		if unit.sprite_2d.material != null:
			continue
		unit.selected.emit()
func _on_select_area_mouse_exited() -> void:
	is_under_mouse = false
	if selected:
		return
	for unit : Unit in %UnitsNode.get_children():
		unit.unselected.emit()
func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("select") and is_under_mouse:
		selected = !selected
		if selected:
			_on_select_area_mouse_exited()
