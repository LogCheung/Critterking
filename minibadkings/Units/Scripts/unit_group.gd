extends Group
class_name AllyGroup

signal being_upgraded

var UNIT : PackedScene = load("res://Units/Scenes/unit.tscn")

@export var house : Building
@export var wage : int = 2
@export var conscripted : bool
@export var starving : bool

@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var ui: UI = get_tree().get_first_node_in_group("UI")

func _ready() -> void:
	super._ready()
	being_upgraded.connect(on_being_upgraded)
	tile = tileWorld.ground.local_to_map(global_position)
	
	create_formation(UNIT)
	apply_charm()
	%Place.play()
	selected = false
	_on_select_area_mouse_exited()
	
	if self is AllyGroup and !conscripted:
		ui.info_overlay.handle_party_limit()

func _process(delta: float) -> void:
	if selected: highlight_tiles()
	
	# day time inspecting
	if !world.is_combat_phase and tileWorld.mouseTile == Vector2i(tile): 
		_on_select_area_mouse_entered()
		is_under_mouse = false
		if Input.is_action_just_released("inspect"):
			ui.inspect_card.inspect_card(int(type),charm)
	elif !world.is_combat_phase:
		_on_select_area_mouse_exited()
	
func respawn_units() -> void:
	create_formation(UNIT)
	for unit in unitsArray:
		unit.global_position = house.entrance.global_position
		unit.set_collision_layer_value(1,false)
	
	for unit in unitsArray:
		await get_tree().create_timer(1.5).timeout
		print("ok")
		unit.set_collision_layer_value(1,true)

var is_under_mouse : bool = false

func _on_select_area_mouse_entered() -> void:
	if tileWorld.using_decree : return
	if house : return
	is_under_mouse = true
	for unit : Ally in unitsArray:
		if unit.sprite_2d.material != null:
			continue
		unit.selected.emit()
func _on_select_area_mouse_exited() -> void:
	is_under_mouse = false
	if selected:
		return
	for unit : Ally in unitsArray:
		if unit.under_mouse:
			_on_select_area_mouse_entered()
			return
		unit.unselected.emit()
func _input(event: InputEvent) -> void:
	if house : return
	if tileWorld.using_decree : return
	if !world.is_combat_phase: return
	if event.is_action_pressed("select") and selected:
		if ui.currentChal == UI.CHALLENGE.JUICED: Engine.time_scale = 2.5
		else: Engine.time_scale = 1
		var mouse_pos = get_global_mouse_position()
		var pos = tileWorld.ground.local_to_map(mouse_pos) # now tile cord
		if !tileWorld.hover.get_used_cells().has(Vector2i(pos)): # can't go to where clicked
			tileWorld.hover.visible = false
			selected = false
			check_on_house(mouse_pos)
			_on_select_area_mouse_exited()
			unzoom_camera()
			
		else: # can go where clicked
			highlight_houses(false)
			highlight_tunnels(false)
			tile = pos
			pos = tileWorld.ground.map_to_local(pos) # now local map cord
			global_position = pos
			tileWorld.handle_navigable_cells()
func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if tileWorld.using_decree : return
	if !world.is_combat_phase: return
	if house : return
	if event.is_action_pressed("select"):
		if is_under_mouse:
			selected = !selected
			if selected: 
				on_selected()
			else:
				unzoom_camera()
func on_selected() -> void:
	if house:
		selected = false
		tileWorld.hover.visible = false
		return
	# zoom camera
	var cam : Camera2D = get_tree().get_first_node_in_group("CAMERA")
	cam.zoom += Vector2(0.075,0.075)
	# show navigable area
	tileWorld.handle_navigable_cells()
	%Select.play()
	highlight_houses()
	if ui.currentChal == UI.CHALLENGE.JUICED: Engine.time_scale = 1.5
	else: Engine.time_scale = .1
	_on_select_area_mouse_exited()
	tileWorld.hover.visible = true
	
func unzoom_camera() -> void:
	# unzoom camera
	var cam : Camera2D = get_tree().get_first_node_in_group("CAMERA")
	cam.zoom -= Vector2(0.075,0.075)
	tileWorld.hover.visible = false

func check_on_house(mousePos : Vector2) -> void:
	if size == max_size : return
	var houses = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	houses = houses.filter(func(b : Building):return b.type == Building.TYPE.HOUSE or b.type == Building.TYPE.CARE)
	for h : Building in houses:
		if h.occupant != null : continue
		h.sprite_2d.material = null
		if mousePos.distance_to(h.global_position) < 32:
			h.occupant = self
			house = h
			
			for unit : Ally in unitsArray:
				unit.healing = true
			highlight_houses(false)
			highlight_tunnels(false)
			tile = h.tile
			global_position = tileWorld.ground.map_to_local(h.tile) # now local map cord
			tileWorld.handle_navigable_cells()
			return
func highlight_houses(highlight : bool = true) -> void:
	if size == max_size : return
	var houses = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	houses = houses.filter(func(b : Building):return b.type == Building.TYPE.HOUSE or b.type == Building.TYPE.CARE)
	for h : Building in houses:
		if h.occupant != null: continue
		h.sprite_2d.material = h.HIGHLIGHT if highlight else null

func highlight_tunnels(highlight : bool = true) -> void:
	return
	#var tunnels = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	#tunnels = tunnels.filter(func(b):return b.type == Building.TYPE.TUNNEL)
	#
	#for t : Building in tunnels:
		#t.sprite_2d.material = t.HIGHLIGHT if highlight else null

func on_being_upgraded(incLevel : int) -> void:
	%Merge.play()
	level = level + incLevel
	match level:
		2:
			upgraded = true
		3:
			upgraded = true
			max_size += 3
	create_formation(UNIT)
	wage = 2 + (level - 1)
	
	ui.info_overlay.handle_projections()

func highlight_tiles() -> void:
	# clear hover tiles
	for cell in tileWorld.hover.get_used_cells():
		tileWorld.hover.set_cell(cell,-1)
	
	# filter tiles already placed
	var unit_tiles : Array
	var unit_groups = get_tree().get_first_node_in_group("GROUPSNODE").get_children()
	for group : AllyGroup in unit_groups:
		if !group is AllyGroup : continue
		group.tile = tileWorld.ground.local_to_map(group.global_position)
		unit_tiles.append(Vector2i(group.tile))
	
	# add appropriate tiles
	var navTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),0)
	navTiles.append_array(tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1))
	for cell in navTiles:
		if unit_tiles.has(cell) : continue
		tileWorld.hover.set_cell(cell,0,Vector2(0,0),0)
		tileWorld.hover.visible = true
	
	# highlight tile hovered over with card
	var hoverTile = world.tileWorld.ground.local_to_map(world.get_global_mouse_position())
	if tileWorld.hover.get_used_cells().has(hoverTile):
		var atlas = tileWorld.hover.get_cell_atlas_coords(hoverTile)
		tileWorld.hover.set_cell(hoverTile,0,atlas,1)
	
func apply_charm() -> void:
	if !is_instance_valid(charm) or !charm: return
	var nCharm = preload("res://Units/Scenes/charm.tscn").instantiate()
	nCharm.type = charm.type
	nCharm.visible = false
	add_child(nCharm)
	charm = nCharm
	nCharm.set_owner(get_tree().get_current_scene())
	
	for unit : Ally in unitsArray:
		match charm.type:
			Charm.TYPE.HEARTLOCKET:
				unit.max_health += 1
				unit.health = unit.max_health
			Charm.TYPE.RING:
				if unit.attack_cd.wait_time > .5: 
					unit.attack_cd.wait_time -=.5
				else:
					unit.attack_cd.wait_time = .1
			Charm.TYPE.SWORD:
				unit.damage += .5
			Charm.TYPE.FLAG:
				max_size += 1
				create_formation(UNIT)
				return
			Charm.TYPE.SODA:
				unit.speed += 12
			Charm.TYPE.ROLLERSKATE:
				unit.dodge += 20
			Charm.TYPE.MEDKIT:
				pass # recovery speed
			Charm.TYPE.GLASSES:
				unit.visionRange += 20
				unit.attackRange += 10
				unit.vision.queue_free()
				unit.set_up_vision()
			Charm.TYPE.NAIL:
				unit.stun_chance += 20
				pass # allow for stun
			Charm.TYPE.BERRIES:
				unit.poison_chance += 20
			Charm.TYPE.PILLS:
				pass
			Charm.TYPE.DOLLHOUSE:
				pass # building buffs
			Charm.TYPE.EDRINK:
				unit.anim.speed_scale += .5

func apply_starvation() -> void:
	for unit : Unit in unitsArray:
		unit.speed -= 10
		unit.health -= 1
	pass
