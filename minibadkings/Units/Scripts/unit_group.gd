@tool
extends Node2D
class_name UnitGroup

const UNIT = preload("res://Units/Scenes/unit.tscn")

@export var size : int = 9
@export var max_size : int
@export var type : int
@export var selected : bool = false
@export var unitsArray : Array[Unit]

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var unitsNode : Node2D = get_tree().get_first_node_in_group("UNITSNODE")
@onready var groupsNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")

var x_sep : int = -10
var y_sep : int = 4
var columns : int = 3
var rows : int

var tile : Vector2
func _ready() -> void:
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation()

func create_formation() -> void:
	# clear all units and create new formation based on size
	for child : Unit in unitsArray:
		child.formation_position.queue_free()
		child.queue_free()
	unitsArray.clear()
	# attempt to make square formation
	rows = size / columns
	if size % columns != 0:  rows += 1
	
	var new_row_margin = -(x_sep)
	var vertical_off = -12 if size <= 9 else -17
	var last_pos : Vector2 = Vector2(new_row_margin,vertical_off) 
	for r in range(rows):
		for c in range(columns):
			# add unit
			var unit : Unit = UNIT.instantiate()
			unit.position = last_pos + Vector2(x_sep,y_sep)
			unit.rotation -= rotation
			unit.group = self
			last_pos = unit.position
			unitsNode.add_child(unit)
			unitsArray.append(unit)
			
			# add permanent formation position to unit
			var formation_pos = Node2D.new()
			formation_pos.position = unit.position
			%PositionsNode.add_child(formation_pos)
			unit.formation_position = formation_pos
			
			unit.global_position += global_position # for global offset
		last_pos += Vector2(abs(x_sep) * 2.75,-y_sep) # add margin for next row
		last_pos -= Vector2(x_sep,y_sep) # new row margin

var is_under_mouse : bool = false
func _on_select_area_mouse_entered() -> void:
	is_under_mouse = true
	for unit : Unit in unitsArray:
		if unit.sprite_2d.material != null:
			continue
		unit.selected.emit()
func _on_select_area_mouse_exited() -> void:
	is_under_mouse = false
	if selected:
		return
	for unit : Unit in unitsArray:
		unit.unselected.emit()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and selected:
		var mouse_pos = get_global_mouse_position()
		var pos = tileWorld.ground.local_to_map(mouse_pos) # now tile cord
		if !tileWorld.hover.get_used_cells().has(Vector2i(pos)):
			tileWorld.hover.visible = false
			selected = false
			_on_select_area_mouse_exited()
			return
		
		tile = pos
		pos = tileWorld.ground.map_to_local(pos) # now local map cord
		global_position = pos
		tileWorld.handle_navigable_cells()
		
func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("select"):
		if is_under_mouse:
			selected = !selected
			if selected: 
				_on_select_area_mouse_exited()
				tileWorld.hover.visible = true
