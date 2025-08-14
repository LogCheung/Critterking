extends Unit
class_name Enemy

var target_in_range : bool
var is_active : bool = false

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	target_in_range = vision.has_overlapping_areas()
	handle_action(delta)
	
func handle_action(delta) -> void:
	var distToTarget = global_position.distance_to(nav.target_position)
	match action:
		ACTION.FORM:
			anim.stop()
			nav.target_position = formation_position.global_position
			if distToTarget <= 2:
				# precheck if it is behind something
				is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
				if !is_behind_wall: wall_tile = null
				
				in_formation = true
				return
		ACTION.FIGHT:
			if attacking : return
			find_target()
			if distToTarget <= 10 :
				if !attack_cd.time_left <= 0 : return
				if anim.is_playing() : return
				
				anim.play("attack")
				
				await anim.animation_finished
				attack_cd.start()
				attacking = true
				return
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)
	
func become_active() -> void:
	is_active = true
	hit_box.monitorable = true

func _on_utility_ai_agent_top_score_action_changed(top_action_id: Variant) -> void:
	match top_action_id:
		"form":
			action = ACTION.FORM
		"fight":
			action = ACTION.FIGHT
			find_target()
