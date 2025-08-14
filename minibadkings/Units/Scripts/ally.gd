extends Unit
class_name Ally

const MELEENORMAL = preload("res://Units/Assets/AllyMeleeNormal.png")
const RANGEDNORMAL = preload("res://Units/Assets/AllyRangedNormal.png")

var allyGroup : AllyGroup

func _ready() -> void:
	allyGroup = group
	super._ready()
	selected.connect(on_selected)
	unselected.connect(on_unselected)
	match_type()

func _process(delta: float) -> void:
	super._process(delta)
	
	in_combat = vision.has_overlapping_areas()
	
	handle_action(delta)
func handle_action(delta) -> void:
	var distToTarget = global_position.distance_to(nav.target_position)
	match action:
		ACTION.NONE:
			anim.play("idle")
			return
		ACTION.FORM:
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
			if distToTarget <= attackRange :
				if !attack_cd.time_left <= 0 : return
				if anim.is_playing() : return
				
				anim.play("attack")
				
				await anim.animation_finished
				attack_cd.start()
				attacking = true
				return
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)

func on_selected() -> void:
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null

func match_type() -> void:
	match type:
		TYPE.MELEE:
			return
		TYPE.RANGED:
			sprite_2d.texture = RANGEDNORMAL
			attackRange = 100
			var visionShape : CollisionShape2D = vision.get_child(0)
			visionShape.shape.radius = 120

func _on_utility_ai_agent_top_score_action_changed(top_action_id: Variant) -> void:
	match top_action_id:
		"none":
			tileWorld.replace_transparent_walls()
			action = ACTION.NONE
		"form":
			action = ACTION.FORM
		"fight":
			anim.stop()
			action = ACTION.FIGHT
			find_target()
		pass
