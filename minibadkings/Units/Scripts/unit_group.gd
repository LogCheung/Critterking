extends Group
class_name AllyGroup

signal being_upgraded

var UNIT : PackedScene = load("res://Units/Scenes/unit.tscn")

@export var house : Building
@export var conscripted : bool

@onready var world : World = get_tree().get_first_node_in_group("WORLD")

func _ready() -> void:
	super._ready()
	being_upgraded.connect(on_being_upgraded)
	tile = tileWorld.ground.local_to_map(global_position)
	
	create_formation(UNIT)
	apply_charm()
	%Place.play()
	selected = false
	_on_select_area_mouse_exited()
	
func respawn_units() -> void:
	create_formation(UNIT)
	for unit in unitsArray:
		unit.global_position = house.entrance.global_position
		unit.set_collision_layer_value(1,false)

var is_under_mouse : bool = false

func _on_select_area_mouse_entered() -> void:
	if tileWorld.using_decree : return
	if !world.is_combat_phase: return
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
	if tileWorld.using_decree : return
	if !world.is_combat_phase: return
	if event.is_action_pressed("select") and selected:
		Engine.time_scale = 1
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
			tile = pos
			pos = tileWorld.ground.map_to_local(pos) # now local map cord
			global_position = pos
			tileWorld.handle_navigable_cells()
func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if tileWorld.using_decree : return
	if !world.is_combat_phase: return
	if event.is_action_pressed("select"):
		if is_under_mouse:
			selected = !selected
			if selected: 
				on_selected()
			else:
				unzoom_camera()
func on_selected() -> void:
	# zoom camera
	var cam : Camera2D = get_tree().get_first_node_in_group("CAMERA")
	cam.zoom += Vector2(0.075,0.075)
	# show navigable area
	tileWorld.handle_navigable_cells()
	%Select.play()
	highlight_houses()
	Engine.time_scale = .1
	_on_select_area_mouse_exited()
	tileWorld.hover.visible = true
	
func unzoom_camera() -> void:
	# unzoom camera
	var cam : Camera2D = get_tree().get_first_node_in_group("CAMERA")
	cam.zoom -= Vector2(0.075,0.075)

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
			return
func highlight_houses(highlight : bool = true) -> void:
	if size == max_size : return
	var houses = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	houses = houses.filter(func(b : Building):return b.type == Building.TYPE.HOUSE or b.type == Building.TYPE.CARE)
	for h : Building in houses:
		if h.occupant != null: continue
		h.sprite_2d.material = h.HIGHLIGHT if highlight else null

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
	
func apply_charm() -> void:
	if !is_instance_valid(charm) or !charm: return
	var nCharm = preload("res://Units/Scenes/charm.tscn").instantiate()
	nCharm.type = charm.type
	nCharm.visible = false
	add_child(nCharm)
	charm = nCharm
	
	for unit : Ally in unitsArray:
		match charm.type:
			Charm.TYPE.HEARTLOCKET:
				unit.max_health += 1
				unit.health = unit.max_health
			Charm.TYPE.RING:
				unit.attack_cd.wait_time -= .5
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
				unit.vision.queue_free()
				unit.set_up_vision()
			Charm.TYPE.NAIL:
				pass # allow for stun
		
