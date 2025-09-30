extends Node2D
class_name TileWorld

@export var decree : Decree
@export var activeDecree : Decree.TYPE

@onready var ground : TileMapLayer = $Ground
@onready var hover : TileMapLayer = $Hover
@onready var wall: TileMapLayer = $wall
@onready var center: Node2D = $Center
@onready var active_hover: TileMapLayer = $ActiveHover
@onready var unit_groups : Array


var using_decree : bool
var wall_tiles : Array
var start_wall_tiles : Array
var unit_tiles : Array
var outskirt_tiles : Array

func _ready() -> void:
	await get_tree().create_timer(.2).timeout
	start_wall_tiles = wall.get_used_cells()
	find_outskirt_tiles()
	handle_navigable_cells()

func _process(delta: float) -> void:
	for cell in active_hover.get_used_cells():
		active_hover.set_cell(cell,-1)
	handle_decree()
	using_decree = activeDecree != Decree.TYPE.NONE

func handle_navigable_cells() -> void:
	# reset 
	unit_tiles.clear()
	for tile in hover.get_used_cells():
		hover.set_cell(tile,-1)
	
	# get where the units are
	unit_groups = get_tree().get_first_node_in_group("GROUPSNODE").get_children()
	for group : AllyGroup in unit_groups:
		if !group is AllyGroup : continue
		group.tile = ground.local_to_map(group.global_position)
		unit_tiles.append(group.tile)
	
	var buildingsCells = get_tree().get_nodes_in_group("BUILDING")
	#var buildings = buildingsCells
	buildingsCells = buildingsCells.filter(func(b: Building):return b.type != b.TYPE.TRAP)
	buildingsCells = buildingsCells.map(func(b : Building):return b.tile)
	# change tile data for buildings is done in building ready script
	#for cell in buildingsCells:
		#ground.set_cell(cell,0,Vector2(0,0),2)
		
	
	# set hover cells for unit navigation
	var navCells : Array = ground.get_used_cells_by_id(0,Vector2(0,0),0)
	navCells.append_array(ground.get_used_cells_by_id(0,Vector2(0,0),1))
	for tile in navCells:
		if unit_tiles.has(Vector2(tile)): continue
		if buildingsCells.has(Vector2(tile)) : continue
		hover.set_cell(tile,0,Vector2(0,0))
	hover.visible = false
	
	
func replace_transparent_walls() -> void:
	return
	wall_tiles = wall.get_used_cells()
	var units = get_tree().get_nodes_in_group("ALLY")
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
	# clear old outskirt
	outskirt_tiles.clear()
	for tile in ground.get_used_cells_by_id(0,Vector2(0,0),4):
		ground.set_cell(tile,-1)
	
	var rect : Rect2i = ground.get_used_rect()
	var end : Vector2i = rect.end
	var pos : Vector2i = rect.position
	for y in range(pos.y,end.y + 1):
		outskirt_tiles.append(Vector2i(pos.x - 1,y))
		outskirt_tiles.append(Vector2i(end.x ,y))
	for x in range(pos.x - 1,end.x + 1):
		outskirt_tiles.append(Vector2i(x,end.y))
		outskirt_tiles.append(Vector2i(x,pos.y - 1))
	for tile in outskirt_tiles:
		ground.set_cell(tile,0,Vector2(0,0),4)

func draw_build_area() -> void:
	await get_tree().create_timer(.05).timeout
	var extra = Global.expansions
	# clear all ground tiles
	#for tile in start_wall_tiles:
		#wall.set_cell(tile,0,Vector2(0,2))
	for tile in ground.get_used_cells():
		ground.set_cell(tile,-1)
		
	# remove walls
	wall_tiles = wall.get_used_cells()
	var wallMax = wall_tiles.max()
	var wallMin = wall_tiles.min()
	for x in range(wallMin.x, wallMax.x):
		for y in range(wallMin.y, wallMax.y):
			wall.set_cell(Vector2i(x,y),-1)
			
	for x in range(wallMin.x, wallMax.x,5):
		for y in range(wallMin.y, wallMax.y,5):
			wall.set_pattern(Vector2i(x,y),wall.tile_set.get_pattern(randi_range(0,5)))
			
	# Battlefield
	var bStart = Vector2i(4,-4) - Vector2i(extra,extra)
	var bEnd = Vector2i(13,5) +  Vector2i(extra,extra)
	for x in range(bStart.x , bEnd.x + 1):
		for y in range(bStart.y , bEnd.y + 1):
			ground.set_cell(Vector2i(x,y),0,Vector2(0,0),0)
			#if wall_tiles.has(Vector2i(x,y)): 
			wall.set_cell(Vector2i(x,y),-1)
	
	# Building area
	var start = Vector2i(6,-2) - Vector2i(extra,extra)
	var end = Vector2i(11,3) +  Vector2i(extra,extra)
	for x in range(start.x , end.x + 1):
		for y in range(start.y , end.y + 1):
			ground.set_cell(Vector2i(x,y),0,Vector2(0,0),1)
			#if wall_tiles.has(Vector2i(x,y)): 
			wall.set_cell(Vector2i(x,y),-1)
	
	# make check for existing buildings/units
	var unitTiles = get_tree().get_nodes_in_group("ALLYGROUP")
	unitTiles = unitTiles.map(func(g : AllyGroup):return g.tile)
	var buildTiles = get_tree().get_nodes_in_group("BUILDING")
	buildTiles = buildTiles.map(func(b : Building):return b.tile)
	for tile in buildTiles:
		ground.set_cell(tile,0,Vector2(0,0),2)
	find_outskirt_tiles()
	handle_navigable_cells()

func handle_decree() -> void:
	# handle size of affected area and action (maybe)
	var mousePos = get_global_mouse_position()
	var mouseTile = active_hover.local_to_map(mousePos + Vector2(8,8))
	var hoveringTiles : Array
	
	# preconditons
	if !ground.get_used_cells().has(mouseTile) : return
	
	# handle hover
	match activeDecree:
		Decree.TYPE.NONE:
			return
		Decree.TYPE.INSPIRATION, Decree.TYPE.CONSTRUCTION:
			add_hover_tiles(1,2,mouseTile) # 3x3 area
		Decree.TYPE.DECARE, Decree.TYPE.DEFENSE, Decree.TYPE.WAR:
			add_hover_tiles(1,1,mouseTile) # 2x2
		Decree.TYPE.MASTERY:
			add_hover_tiles(0,1,mouseTile)
		Decree.TYPE.RECON:
			# Global
			var units = get_tree().get_nodes_in_group("ALLY")
			for unit in units:
				unit.decree = activeDecree
				unit.match_decree_status()
		Decree.TYPE.RENOVATE:
			# highlight buildings, no hover
			highlight_buildings(true,Building.TYPE.NONE)
		Decree.TYPE.CONSCRIPTION:
			# highlight buildings, no hover
			highlight_buildings(true,Building.TYPE.HOUSE)
		Decree.TYPE.INFLUENCE:
			# Highlight enemy units, no hover
			var enemGroups = get_tree().get_first_node_in_group("ENEMYGRPNODE")
			enemGroups = enemGroups.get_children()
			for grp : Group in enemGroups:
				# find first unit and set arrow above them
				# but instead of first just do every one
				for unit in grp.unitsArray:
					if !is_instance_valid(unit) : return
					unit.status_sprite.visible = true
					unit.status_sprite.play("promptSelect")
		
	# handle input
	if using_decree and Input.is_action_just_released("select"):
		handle_decree_action(mouseTile)
		
		await get_tree().create_timer(.1).timeout
		activeDecree = Decree.TYPE.NONE
		decree.time = decree.cooldown
		decree.update_cooldown()
		decree = null
	
	if using_decree and Input.is_action_just_released("cancel"):
		activeDecree = Decree.TYPE.NONE

func handle_decree_action(mouseTile : Vector2i) -> void:
	# executed when clicked and decree is being used
	match activeDecree:
		Decree.TYPE.NONE:
			return
		Decree.TYPE.INSPIRATION, Decree.TYPE.DEFENSE,Decree.TYPE.MASTERY:
			handle_stat_modifying_decree()
		Decree.TYPE.DECARE:
			handle_stat_modifying_decree()
		Decree.TYPE.WAR:
			var bombard = preload("res://TileMap/Scenes/war_bombard.tscn").instantiate()
			bombard.global_position = active_hover.map_to_local(mouseTile) - Vector2(0,16)
			add_child(bombard)
		Decree.TYPE.RECON:
			pass # do nothing
		Decree.TYPE.RENOVATE:
			# highlight buildings, no hover
			var building = get_clicked_building()
			if building:
				building.health = building.max_health
				highlight_buildings(false,Building.TYPE.NONE)
		Decree.TYPE.CONSCRIPTION:
			# highlight buildings, no hover
			var building = get_clicked_building()
			if building:
				# create new unit at building's front door
				var group : AllyGroup= preload("res://Units/Scenes/unit_group.tscn").instantiate()
				group.type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
				group.tile = building.doorstepTile
				group.level = 1
				group.global_position = ground.map_to_local(group.tile)
				
				group.conscripted = true
				
				var groupsNode = get_tree().get_first_node_in_group("GROUPSNODE")
				groupsNode.add_child(group) # group ready is then called
				
				# stage them coming from building
				for u in group.unitsArray:
					u.global_position = building.entrance.global_position
					#u.visible = false
				
				highlight_buildings(false,Building.TYPE.NONE)
		Decree.TYPE.INFLUENCE:
			var enemGroups = get_tree().get_first_node_in_group("ENEMYGRPNODE")
			enemGroups = enemGroups.get_children()
			# remove prompt select from each enemy
			for grp : Group in enemGroups:
				for unit in grp.unitsArray:
					if !is_instance_valid(unit) : return
					unit.status_sprite.visible = false
					unit.status_sprite.play("promptSelect")
			pass
		Decree.TYPE.CONSTRUCTION:
			var usableTiles = ground.get_used_cells_by_id(0,Vector2(0,0),0)
			usableTiles.append_array(ground.get_used_cells_by_id(0,Vector2(0,0),1))
			for tile in active_hover.get_used_cells():
				if !usableTiles.has(tile) : continue
				var buildingNode = get_tree().get_first_node_in_group("BUILDINGSNODE")
				var trap : Building = load("res://TileMap/Scenes/building.tscn").instantiate()
				trap.type = Building.TYPE.TRAP
				
				trap.global_position = ground.map_to_local(tile)
				buildingNode.add_child(trap)
				
			
	highlight_buildings(false,Building.TYPE.NONE)
	
func handle_stat_modifying_decree() -> void:
	# Create affected area
	var area : Area2D = Area2D.new()
	var col : CollisionShape2D= CollisionShape2D.new()
	var shape : ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	
	# add points for shape
	var usedRect = active_hover.get_used_rect()
	var pointsArr : Array = []
	var tileSize = Vector2i(32,16)
	pointsArr.append(Vector2i(-usedRect.size.x,0) * tileSize + Vector2i(4,0))
	pointsArr.append(Vector2i(0,-usedRect.size.y) * tileSize + Vector2i(0,4))
	pointsArr.append(Vector2i(usedRect.size.x,0) * tileSize + Vector2i(-4,0))
	pointsArr.append(Vector2i(0,usedRect.size.y) * tileSize + Vector2i(0,-4))
	pointsArr.append(Vector2i(-usedRect.size.x,0) * tileSize + Vector2i(4,0))
	shape.points = pointsArr
	
	col.shape = shape
	area.add_child(col)
	area.global_position = get_global_mouse_position()
	area.global_position = active_hover.map_to_local(active_hover.local_to_map(area.global_position))
	area.set_collision_layer_value(1,false) # no clue but maybe this is good thing to do
	area.set_collision_mask_value(1,false) # for no reason
	area.set_collision_mask_value(5,true) # to check for allies
	area.set_collision_mask_value(6,true) # to check for enemies
	area.top_level = true
	add_child(area)
	
	# wait for 5 frames before checking
	for i in range(5): await get_tree().process_frame 
	
	var affectedArray : Array 
	for a in area.get_overlapping_areas():
		var unit = a.owner
		if !unit: continue
		if unit is Ally : 
			unit.decree = activeDecree
			unit.match_decree_status()
			affectedArray.append(unit)
		elif unit is Enemy and activeDecree == Decree.TYPE.INFLUENCE:
			affectedArray.append(unit)
		
	area.queue_free()

func add_hover_tiles(from : int, to : int,startPos : Vector2i) -> void:
	var hoveringTiles : Array
	for x in range(startPos.x - from,startPos.x + to ):
		for y in range(startPos.y - from,startPos.y + to ):
			hoveringTiles.append(Vector2i(x,y))
	
	active_hover.set_cells_terrain_connect(hoveringTiles,0,0)

func highlight_buildings(highlight : bool, type : Building.TYPE) -> void:
	var buildings = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	if type != Building.TYPE.NONE:
		buildings = buildings.filter(func(bu : Building):return bu.type == type)
	for b : Building in buildings:
		b.sprite_2d.material = b.HIGHLIGHT if highlight else null

func get_clicked_building() -> Building:
	var buildings = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	for b : Building in buildings:
		if get_global_mouse_position().distance_to(b.global_position) < 32:
			return b
	return null
