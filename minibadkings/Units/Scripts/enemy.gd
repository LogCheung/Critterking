extends Unit
class_name Enemy

signal house_destroyed

const GHOST = preload("res://Units/Shaders/ghostHighlight.tres")

const MELEENORMALSE = preload("res://Units/Assets/EnemyMelee/EnemyMeleeNormalSE.png")
const RANGEDNORMALSE = preload("res://Units/Assets/EnemyRanged/EnemyRangedNormalSE.png")
const SHIELDEDNORMALSE = preload("res://Units/Assets/EnemyShield/EnemyShieldNormalSE.png")

var target_in_range : bool
var is_active : bool = false
var houses_exist : bool = true

func _ready() -> void:
	super._ready()
	match_type()
	if upgraded: 
		max_health = max_health + 1
		health = max_health
		damage = damage + 1
	house_destroyed.connect(find_building)

func _process(delta: float) -> void:
	super._process(delta)
	
	if vision.monitoring : target_in_range = vision.has_overlapping_areas()
	handle_action(delta)
	handle_approach()
	check_houses()
	
	
func handle_action(delta) -> void:
	var distToTarget = global_position.distance_to(nav.target_position)
	match action:
		ACTION.FORM:
			nav.target_position = formation_position.global_position
			if distToTarget <= 2:
				anim.play("idle")
				# precheck if it is behind something
				is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
				if !is_behind_wall: wall_tile = null
				
				in_formation = true
				return
			else:
				anim.play("walk")
				in_formation = false
		ACTION.FIGHT:
			if attacking : return
			find_target()
			if target == null: target_in_range = false
			if distToTarget <= attackRange :
				if !attack_cd.time_left <= 0 : return
				if type == TYPE.RANGED and distToTarget < 15: 
					too_close = true
					return
				too_close = false
				anim.play("attack")
				if type== TYPE.RANGED:
					%Shoot.play()
				else:
					%Attack.play()
				await anim.animation_finished
				attack_cd.start()
				attacking = true
				return
			elif !anim.is_playing():
				anim.play("walk")
		ACTION.RAID:
			if distToTarget <= 24:
				anim.play("attack")
				if type== TYPE.RANGED:
					%Shoot.play()
				else:
					%Attack.play()
				return
			else:
				anim.play("walk")
		ACTION.STRAFE:
			find_target()
			if !target : return
			var strafe_dist = 20
			var dir = global_position.direction_to(target.global_position)
			nav.target_position = target.global_position - dir * strafe_dist
			anim.play("walk")
			
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)
	
func become_active() -> void:
	is_active = true
	vision.monitoring = true
	sprite_2d.material = null
	z_index = 0
	nav.set_navigation_layer_value(2,false)

func match_type() -> void:
	match type:
		TYPE.MELEE:
			sprite_2d.texture = MELEENORMALSE
		TYPE.RANGED:
			sprite_2d.texture = RANGEDNORMALSE
			health = 2
			damage = 1.5
			attackRange = 100
			var visionShape : CollisionShape2D = vision.get_child(0)
			visionShape.shape.radius = 120
			attack_cd.wait_time = 4
		TYPE.SHIELDED:
			sprite_2d.texture = SHIELDEDNORMALSE
			damage = 1

func find_building() -> void:
	await get_tree().create_timer(.1).timeout
	var buildings = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	buildings = buildings.filter(func(b):return b.type != Building.TYPE.TRAP)
	buildings = buildings.filter(func(b):return b.type != Building.TYPE.RUINS)
	if buildings.is_empty() : return
	find_closest(buildings)
	if target: nav.target_position = target.global_position

func handle_approach() -> void:
	if !is_active:
		z_index = 10
		sprite_2d.material = GHOST

func check_houses() -> void:
	var buildings = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
	houses_exist = true if !buildings.is_empty() else false

func _on_utility_ai_agent_top_score_action_changed(top_action_id: Variant) -> void:
	match top_action_id:
		"form":
			action = ACTION.FORM
		"fight":
			action = ACTION.FIGHT
			find_target()
		"raid":
			action = ACTION.RAID
			find_building()
		"strafe":
			action = ACTION.STRAFE
