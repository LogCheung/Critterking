extends Node2D
class_name TileWorld

@onready var ground : TileMapLayer = $Ground
@onready var hover : TileMapLayer = $Hover
@onready var unit_groups : Array

var unit_tiles : Array

func _ready() -> void:
	await get_tree().create_timer(.2).timeout
	handle_navigable_cells()

func handle_navigable_cells() -> void:
	# reset 
	unit_tiles.clear()
	for tile in hover.get_used_cells():
		hover.set_cell(tile,-1)
	
	# get where the units are
	unit_groups = get_tree().get_first_node_in_group("GROUPSNODE").get_children()
	for group : UnitGroup in unit_groups:
		unit_tiles.append(group.tile)
	print(unit_tiles)
	
	var navCells : Array = ground.get_used_cells_by_id(0,Vector2(0,0),0)
	navCells.append_array(ground.get_used_cells_by_id(0,Vector2(0,0),1))
	for tile in navCells:
		if unit_tiles.has(Vector2(tile)): continue
		hover.set_cell(tile,0,Vector2(0,0))
	hover.visible = false
