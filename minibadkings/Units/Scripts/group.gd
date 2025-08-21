extends Node2D
class_name Group

signal unit_died

@export var type : Unit.TYPE
@export var size : int = 9
@export var max_size : int = 9
@export var selected : bool = false
@export var unitsArray : Array[Unit]
@export var upgraded : bool = false

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var unitsNode : Node2D = get_tree().get_first_node_in_group("UNITSNODE")
@onready var groupsNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")

var x_sep : int = -10
var y_sep : int = 4
var columns : int = 3
var rows : int

var tile : Vector2

func _ready() -> void:
	unit_died.connect(_on_unit_died)

func create_formation(unit_type : PackedScene) -> void:
	# clear all units and create new formation based on size
	for child : Unit in unitsArray:
		child.formation_position.queue_free()
		child.queue_free()
	unitsArray.clear()
	# attempt to make square formation
	rows = max_size / columns
	if max_size % columns != 0:  rows += 1
	
	var new_row_margin = -(x_sep)
	var vertical_off = -14 if max_size <= 9 else -18
	var last_pos : Vector2 = Vector2(new_row_margin,vertical_off) 
	for r in range(rows):
		for c in range(columns):
			# add unit
			var unit : Unit = unit_type.instantiate()
			unit.position = last_pos + Vector2(x_sep,y_sep)
			unit.rotation -= rotation
			unit.upgraded = upgraded
			unit.group = self
			unit.type = type
			
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

func _on_unit_died() -> void:
	print("wo")
	size = unitsArray.size()
	if unitsArray.is_empty():
		var world = get_tree().get_first_node_in_group("WORLD")
		if self is EnemyGroup :
			world.enemy_group_eliminated.emit()
			print("enemy group bye")
		queue_free()

func terminate() -> void:
	for unit in unitsArray:
		unit.process_mode = Node.PROCESS_MODE_DISABLED
	for unit in unitsArray:
		unit.queue_free()
	queue_free()
	
