extends Node2D
class_name TileWorld

@onready var ground : TileMapLayer = $Ground
@onready var hover : TileMapLayer = $Hover
@onready var wall: TileMapLayer = $wall
@onready var center: Node2D = $Center
@onready var unit_groups : Array

var wall_tiles : Array
var unit_tiles : Array
var outskirt_tiles : Array

func _ready() -> void:
	find_outskirt_tiles()
	await get_tree().create_timer(.2).timeout
	wall_tiles = wall.get_used_cells()
	handle_navigable_cells()
	limit_colliding_walls()

func handle_navigable_cells() -> void:
	# reset 
	unit_tiles.clear()
	for tile in hover.get_used_cells():
		hover.set_cell(tile,-1)
	
	# get where the units are
	unit_groups = get_tree().get_first_node_in_group("GROUPSNODE").get_children()
	for group : AllyGroup in unit_groups:
		if !group is AllyGroup : continue
		unit_tiles.append(group.tile)
	
	var buildingsCells = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	buildingsCells = buildingsCells.map(func(b : Building):return b.tile)
	# change tile data for buildings
	for cell in buildingsCells:
		ground.set_cell(cell,0,Vector2(0,0),2)
	
	var navCells : Array = ground.get_used_cells_by_id(0,Vector2(0,0),0)
	navCells.append_array(ground.get_used_cells_by_id(0,Vector2(0,0),1))
	for tile in navCells:
		if unit_tiles.has(Vector2(tile)): continue
		if buildingsCells.has(Vector2(tile)) : continue
		hover.set_cell(tile,0,Vector2(0,0))
	hover.visible = false
	
	
func replace_transparent_walls() -> void:
	var units = get_tree().get_nodes_in_group("UNIT")
	var trans_walls = units.map(func(u : Unit):return u.wall_tile)
	trans_walls = trans_walls.filter(func(e):return e != null)
	var opaque_cells = wall.get_used_cells_by_id(0,Vector2(0,2),0)
	for cell in wall_tiles:
		if opaque_cells.has(cell): continue
		if trans_walls.has(cell): continue
		
		wall.set_cell(cell,0,Vector2(0,2),2)

func limit_colliding_walls() -> void:
	for w in wall.get_used_cells():
		if has_surrounding_ground_cells(w):
			wall.set_cell(w,0,Vector2(0,2),2)

func has_surrounding_ground_cells(tile : Vector2i) -> bool:
	var groundCells = ground.get_used_cells()
	for x in range(tile.x -1, tile.x + 1):
		for y in range(tile.y -1, tile.y + 1):
			if groundCells.has(Vector2i(x,y)):
				return true
	return false

func find_outskirt_tiles() -> void:
	var rect : Rect2i = ground.get_used_rect()
	var end : Vector2i = rect.end
	var pos : Vector2i = rect.position
	for y in range(pos.y,end.y):
		outskirt_tiles.append(Vector2i(pos.x - 1,y))
		outskirt_tiles.append(Vector2i(end.x ,y))
	for x in range(pos.x ,end.x):
		outskirt_tiles.append(Vector2i(x,end.y))
		outskirt_tiles.append(Vector2i(x,pos.y - 1))
	for tile in outskirt_tiles:
		ground.set_cell(tile,0,Vector2(0,0),4)
