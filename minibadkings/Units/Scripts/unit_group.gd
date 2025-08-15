extends Group
class_name AllyGroup

const UNIT : PackedScene = preload("res://Units/Scenes/unit.tscn")

@export var house : Building

func _ready() -> void:
	super._ready()
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(UNIT)

func respawn_units() -> void:
	create_formation(UNIT)
	for unit in unitsArray:
		unit.global_position = house.entrance.global_position
		unit.set_collision_layer_value(1,false)

var is_under_mouse : bool = false

func _on_select_area_mouse_entered() -> void:
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
		unit.unselected.emit()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and selected:
		Engine.time_scale = 1
		var mouse_pos = get_global_mouse_position()
		var pos = tileWorld.ground.local_to_map(mouse_pos) # now tile cord
		if !tileWorld.hover.get_used_cells().has(Vector2i(pos)):
			tileWorld.hover.visible = false
			selected = false
			check_on_house(mouse_pos)
			_on_select_area_mouse_exited()
			return
		highlight_houses(false)
		tile = pos
		pos = tileWorld.ground.map_to_local(pos) # now local map cord
		global_position = pos
		tileWorld.handle_navigable_cells()
func _on_select_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("select"):
		if is_under_mouse:
			selected = !selected
			if selected: 
				highlight_houses()
				Engine.time_scale = .1
				_on_select_area_mouse_exited()
				tileWorld.hover.visible = true

func check_on_house(mousePos : Vector2) -> void:
	if size == max_size : return
	var houses = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	houses = houses.filter(func(b : Building):return b.type == Building.TYPE.HOUSE )
	print(houses)
	for h : Building in houses:
		if h.occupant != null : continue
		h.sprite_2d.material = null
		if mousePos.distance_to(h.global_position) < 32:
			h.occupant = self
			house = h
			for unit : Ally in unitsArray:
				unit.healing = true
			pass
func highlight_houses(highlight : bool = true) -> void:
	if size == max_size : return
	var houses = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	houses = houses.filter(func(b : Building):return b.type == Building.TYPE.HOUSE )
	for h : Building in houses:
		if h.occupant != null: continue
		h.sprite_2d.material = h.HIGHLIGHT if highlight else null
