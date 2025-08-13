@tool
extends Group
class_name AllyGroup

const UNIT : PackedScene = preload("res://Units/Scenes/unit.tscn")

func _ready() -> void:
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(UNIT)
	
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
