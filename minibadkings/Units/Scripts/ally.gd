extends Unit
class_name Ally

func _ready() -> void:
	selected.connect(on_selected)
	unselected.connect(on_unselected)

func _process(delta: float) -> void:
	super._process(delta)
	handle_action(delta)

func handle_action(delta) -> void:
	match action:
		ACTION.NONE:
			anim.play("idle")
			
			return
		ACTION.FORM:
			anim.stop()
			nav.target_position = formation_position.global_position
			if global_position.distance_to(nav.target_position) <= 2:
				# precheck if it is behind something
				is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
				if !is_behind_wall: wall_tile = null
				
				in_formation = true
				return
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)

func on_selected() -> void:
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null

func _on_utility_ai_agent_top_score_action_changed(top_action_id: Variant) -> void:
	match top_action_id:
		"none":
			tileWorld.replace_transparent_walls()
			action = ACTION.NONE
		"form":
			action = ACTION.FORM
		pass
