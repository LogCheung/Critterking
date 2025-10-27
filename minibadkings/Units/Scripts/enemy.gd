extends Unit
class_name Enemy

signal house_destroyed

const GHOST = preload("res://Units/Shaders/ghostHighlight.tres")

const MELEENORMALSE = preload("res://Units/Assets/EnemyMelee/EnemyMeleeNormalSE.png")
const RANGEDNORMALSE = preload("res://Units/Assets/EnemyRanged/EnemyRangedNormalSE.png")
const SHIELDEDNORMALSE = preload("res://Units/Assets/EnemyShield/EnemyShieldNormalSE.png")
const CRAZEDNORMALSE = preload("res://Units/Assets/EnemyCrazed/EnemyNormalCrazed.png")
const BOMBERNORMALSE = preload("res://Units/Assets/EnemyBomber/EnemyNormalBomber.png")
const FLYINGNORMALSE = preload("res://Units/Assets/EnemyFlying/EnemyNormalFlying.png")
const PARALYTICNORMALSE = preload("res://Units/Assets/EnemyParalytic/EnemyNormalParalytic.png")
const RESILIENTNORMALSE = preload("res://Units/Assets/EnemyResilient/EnemyNormalResilient.png")
const STINGERNORMALSE = preload("res://Units/Assets/EnemyStinger/EnemyNormalStinger.png")

const UPMELEENORMALSE = preload("res://Units/Assets/EnemyMelee/EnemyMeleeUpgradedSE.png")
const UPRANGEDNORMALSE = preload("res://Units/Assets/EnemyRanged/EnemyRangedUpgradedSE.png")
const UPSHIELDEDNORMALSE = preload("res://Units/Assets/EnemyShield/EnemyShieldUpgradedSE.png")
const UPCRAZEDNORMALSE = preload("res://Units/Assets/EnemyCrazed/EnemyUpgradedCrazed.png")
const UPBOMBERNORMALSE = preload("res://Units/Assets/EnemyBomber/EnemyUpgradedBomber.png")
const UPFLYINGNORMALSE = preload("res://Units/Assets/EnemyFlying/EnemyUpgradedFlying.png")
const UPPARALYTICNORMALSE = preload("res://Units/Assets/EnemyParalytic/EnemyUpgradedParalytic.png")
const UPRESILIENTNORMALSE = preload("res://Units/Assets/EnemyResilient/EnemyUpgradedResilient.png")
const UPSTINGERNORMALSE = preload("res://Units/Assets/EnemyStinger/EnemyUpgradedStinger.png")

var target_in_range : bool
var is_active : bool = false
var houses_exist : bool = true

# astar will be used for appraoch
var aStar : AStarGrid2D
var navPath : Array
var target_pos

func _ready() -> void:
	super._ready()
	match_type()
	if upgraded: 
		max_health = max_health + 0.5
		damage = damage + 0.5
	health = max_health
	house_destroyed.connect(find_building)
	aStar = tileWorld.aStar

func _process(delta: float) -> void:
	super._process(delta)
	if is_active: handle_behind_wall()
	
	if vision.monitoring : target_in_range = vision.has_overlapping_areas()
	handle_action(delta)
	handle_approach()
	check_houses()
func handle_action(delta) -> void:
	if dead:return
	var distToTarget = global_position.distance_to(nav.target_position)
	if knocked: 
		move_and_slide()
	if dashing:
		if !target : 
			find_target()
			dashing = false
			return
		if distToTarget < 5 : dashing = false
		var dir = global_position.direction_to(target.global_position)
		move_to(dir,delta)
		return
	
	match action:
		ACTION.FORM:
			distToTarget = distance_from_form
			if distToTarget <= 16:
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
				if type == TYPE.RANGED or type == TYPE.BOMBER:
					too_close = distToTarget < ranged_buffer
				if type == TYPE.CRAZED : anim.speed_scale = 2
				anim.play("attack")
				dashing = type == TYPE.FLYING
				if type== TYPE.RANGED:
					%Shoot.play()
				else:
					%Attack.play()
				await anim.animation_finished
				anim.speed_scale = 1
				attack_cd.start()
				attacking = true
				return
			elif !anim.is_playing():
				anim.play("walk")
		ACTION.RAID:
			if distToTarget <= 22:
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
		ACTION.STUNNED:
			if stun_cd.is_stopped() : stun_cd.start()
			status_sprite.visible = true
			status_sprite.play("stun")
			attack_cd.paused = true
			anim.stop()
			return
		ACTION.DEAD:
			return
	
	_handle_navigation_path()
	if next_path_pos:
		move_to(self.global_position.direction_to(next_path_pos), delta)
	
func _handle_navigation_path() -> void:
	if is_active : return
	if distance_from_form < 32: 
		nav.target_position = formation_position.global_position
		return
	# go through each path point that astar provides to target
	if nav.is_navigation_finished():
		path_points.pop_front()
	if path_points.is_empty():
		var position_id = tileWorld.wall.local_to_map(global_position)
		var target_id = tileWorld.wall.local_to_map(formation_position.global_position)
		path_points = aStar.get_id_path(position_id,target_id,true)
		
		# add navigation only to tiles needed to get to point
		# to reduce lag from huge nav mesh
		for cell in path_points:
			if tileWorld.ground.get_used_cells().has(cell): continue
			tileWorld.ground.set_cell(cell,0,Vector2(0,0),5)
			navPath.append(cell)
		return
	
	nav.target_position = tileWorld.wall.map_to_local(path_points.front())
func become_active() -> void:
	is_active = true
	vision.monitoring = true
	sprite_2d.material = null
	z_index = 0
	%CollisionShape2D.disabled = false
	set_collision_layer_value(1,true)
	nav.set_navigation_layer_value(1,true)
	nav.set_navigation_layer_value(2,false)
	
	# remove nav cells that were created
	for cell in navPath:
		tileWorld.ground.set_cell(cell,-1)

func match_type() -> void:
	match type:
		TYPE.MELEE:
			if upgraded: sprite_2d.texture = UPMELEENORMALSE
			else: sprite_2d.texture = MELEENORMALSE
		TYPE.RANGED:
			if upgraded: sprite_2d.texture = UPRANGEDNORMALSE
			else: sprite_2d.texture = RANGEDNORMALSE
			health = 2
			damage = 1.5
			attackRange = 100
			var visionShape : CollisionShape2D = vision.get_child(0)
			visionShape.shape.radius = 120
			attack_cd.wait_time = 2
		TYPE.SHIELDED:
			if upgraded: sprite_2d.texture = UPSHIELDEDNORMALSE
			else: sprite_2d.texture = SHIELDEDNORMALSE
			damage = 1
		TYPE.CRAZED:
			if upgraded: sprite_2d.texture = UPCRAZEDNORMALSE
			else: sprite_2d.texture = CRAZEDNORMALSE
			health = 2
			damage = 0.75
			speed = 60
			dodge = 33
			attack_cd.wait_time = 1
		TYPE.BOMBER:
			sprite_2d.texture = BOMBERNORMALSE if !upgraded else UPBOMBERNORMALSE
			health = 2
			damage = .5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 3
		TYPE.FLYING:
			sprite_2d.texture = FLYINGNORMALSE if !upgraded else UPFLYINGNORMALSE
			health = 3
			damage = 1.5
			attackRange = 30
			visionRange = 60
			attack_cd.wait_time = 2.5
		TYPE.PARALYTIC:
			sprite_2d.texture = PARALYTICNORMALSE if !upgraded else UPPARALYTICNORMALSE
			health = 3
			damage = 1.5
			stun_chance = 100
			attack_cd.wait_time = 1.5
		TYPE.RESILIENT:
			sprite_2d.texture = RESILIENTNORMALSE if !upgraded else UPRESILIENTNORMALSE
			health = 3
			damage = 1
			attack_cd.wait_time = 2
		TYPE.STINGER:
			sprite_2d.texture = STINGERNORMALSE if !upgraded else UPSTINGERNORMALSE
			health = 3
			damage = 1
			attack_cd.wait_time = 2
			attackRange = 20
			poison_chance = 100
		TYPE.TRAPJAW:
			health = 4
			damage = 1.5
			knock_chance = 100
			attack_cd.wait_time = 2
		TYPE.EXPLOSIVE:
			health = 3
			damage = 1
			attack_cd.wait_time = 2
			var deathAnim = anim.get_animation("death")
			deathAnim.length = 1
		TYPE.FUNGI:
			health = 2
			damage = 1
			attack_cd.wait_time = 2
			attackRange = 80
			visionRange = 100
			var deathAnim = anim.get_animation("death")
			deathAnim.length = 1
			ranged = true
		TYPE.ACIDIC:
			health = 2
			damage = .5
			attackRange = 50
			visionRange = 75
			attack_cd.wait_time = 2.5
			ranged = true
		TYPE.ZOMBIFIED:
			sprite_2d.texture = CRAZEDNORMALSE if level < 2 else UPCRAZEDNORMALSE
			health = 1
			damage = 0.75
			speed = 60
			attack_cd.wait_time = .5
			visionRange = 400
			sprite_2d.modulate = Color(0.994, 0.834, 0.588, 1.0)
			become_active()
			return
			
	# Find sprite file
	if type > Unit.TYPE.RANGED:
		var typeStr = str(TYPE.keys()[type])
		if type == Unit.TYPE.ZOMBIFIED: typeStr = "FUNGI"
			
		var path : String = "res://Units/Assets/Enemy"
		# find folder
		path += typeStr.substr(0,1)
		path += typeStr.substr(1).to_lower()
		# find file
		path += "/Enemy"
		path += "Normal" if level <= 1 else "Upgraded"
		path += typeStr.substr(0,1)
		path += typeStr.substr(1).to_lower()
		path += ".png"
		
		sprite_2d.texture = load(path)
func find_building() -> void:
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
		"dead":
			action = ACTION.DEAD
		"stunned":
			action = ACTION.STUNNED


func _on_approach_guarantee_timeout() -> void:
	if is_active: return
	self.global_position = self.formation_position.global_position
	
