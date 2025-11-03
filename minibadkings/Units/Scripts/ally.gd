extends Unit
class_name Ally

signal speedchange
signal healthchange

const MELEENORMALSE = preload("res://Units/Assets/AllyMelee/AllyMeleeNormalSE.png")
const RANGEDNORMALSE = preload("res://Units/Assets/AllyRanged/AllyRangedNormalSE.png")
const SHIELDEDNORMALSE = preload("res://Units/Assets/AllyShield/AllyShieldNormalSE.png")
const CRAZEDNORMALSE = preload("res://Units/Assets/AllyCrazed/AllyNormalCrazed.png")
const BOMBERNORMALSE = preload("res://Units/Assets/AllyBomber/AllyNormalBomber.png")
const FLYINGNORMALSE = preload("res://Units/Assets/AllyFlying/AllyNormalFlying.png")
const PARALYTICNORMALSE = preload("res://Units/Assets/AllyParalytic/AllyNormalParalytic.png")
const RESILIENTNORMALSE = preload("res://Units/Assets/AllyResilient/AllyNormalResilient.png")
const STINGERNORMALSE = preload("res://Units/Assets/AllyStinger/AllyNormalStinger.png")

const UPMELEENORMALSE = preload("res://Units/Assets/AllyMelee/AllyMeleeUpgradedSE.png")
const UPRANGEDNORMALSE = preload("res://Units/Assets/AllyRanged/AllyRangedUpgradedSE.png")
const UPSHIELDEDNORMALSE = preload("res://Units/Assets/AllyShield/AllyShieldUpgradedSE.png")
const UPCRAZEDNORMALSE = preload("res://Units/Assets/AllyCrazed/AllyUpgradedCrazed.png")
const UPBOMBERNORMALSE = preload("res://Units/Assets/AllyBomber/AllyUpgradedBomber.png")
const UPFLYINGNORMALSE = preload("res://Units/Assets/AllyFlying/AllyUpgradedFlying.png")
const UPPARALYTICNORMALSE = preload("res://Units/Assets/AllyParalytic/AllyUpgradedParalytic.png")
const UPRESILIENTNORMALSE = preload("res://Units/Assets/AllyResilient/AllyUpgradedResilient.png")
const UPSTINGERNORMALSE = preload("res://Units/Assets/AllyStinger/AllyUpgradedStinger.png")

@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var ui: UI = get_tree().get_first_node_in_group("UI")

var allyGroup : AllyGroup
var healing : bool

func _ready() -> void:
	allyGroup = group
	if level > 1: upgraded = true
	super._ready()
	selected.connect(on_selected)
	#healthchange.connect(on_health_change)
	#speedchange.connect(on_speed_change)
	unselected.connect(on_unselected)
	match_type()
	
	if level > 1:  # if upgraded
		max_health = max_health + 0.5
		damage = damage + 0.5
	#challenge changes
	if ui.currentChal == UI.CHALLENGE.TOWERDEFENSE:
		speed *= .33
		max_health = max_health + 2
		visionRange *= 1.5
	#ascension changes
	if ui.currentAscn >= 9: 
		max_health -= .25 if type != TYPE.ZOMBIFIED else 0.0
	health = max_health
	await get_tree().create_timer(.5).timeout
	set_collision_layer_value(1,true)
	

func _process(delta: float) -> void:
	super._process(delta)
	if action != ACTION.NONE:
		handle_behind_wall()
		
	# Check if in combat
	if vision and vision.has_overlapping_areas(): # inside sight of ally
		for area in vision.get_overlapping_areas(): # not dead and not in walls
			in_combat = is_instance_valid(area.owner) and area.owner.is_active
	else:
		in_combat = false
	if type == TYPE.ZOMBIFIED : in_combat = true
	
	# check if enemy is too close
	if ranged:
		if is_instance_valid(target):
			var distToTarget = global_position.distance_to(target.global_position)
			too_close = distToTarget < ranged_buffer
	
	handle_action(delta)

func handle_action(delta) -> void:
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
		ACTION.NONE:
			anim.play("idle")
			visible = true
			return
		ACTION.FORM:
			# if zombie, can't go to formation cuz no group
			if type == TYPE.ZOMBIFIED: return
			
			anim.play("walk")
			nav.target_position = formation_position.global_position
			if distToTarget <= 2:
				set_collision_layer_value(1,true)
				# precheck if it is behind something
				is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
				if !is_behind_wall: wall_tile = null
				
				in_formation = true
				anim.stop()
				return
		ACTION.FIGHT:
			if attacking: return
			find_target()
			if distToTarget <= attackRange :
				if !attack_cd.time_left <= 0 : return
				if anim.is_playing() and type != TYPE.ZOMBIFIED: return
				
				anim.play("attack")
				dashing = type == TYPE.FLYING
				if ranged: %Shoot.play()
				else: %Attack.play()
				
				await anim.animation_finished
				velocity = Vector2.ZERO
				attack_cd.start()
				attacking = true
				return
			elif !anim.is_playing() and type == TYPE.ZOMBIFIED:
				anim.play("walk")
		ACTION.STRAFE:
			find_target()
			if !target : 
				in_combat = false if !vision.has_overlapping_areas() else true
				return
			var strafe_dist = 5
			var dir = global_position.direction_to(target.global_position)
			nav.target_position = global_position - dir * strafe_dist
			anim.play("walk")
		ACTION.HEAL:
			anim.play("walk")
			if distToTarget < 8:
				visible = false
				hit_box.set_collision_layer_value(2,false)
				return
		ACTION.STUNNED:
			if dead:return
			if stun_cd.is_stopped() : stun_cd.start()
			status_sprite.visible = true
			status_sprite.play("stun")
			anim.stop()
			attack_cd.paused = true
			return 
		ACTION.DEAD:
			sprite_2d.material = null
			return
	
	if next_path_pos:
		move_to(self.global_position.direction_to(next_path_pos), delta)

func on_selected() -> void:
	if dead : return
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null

func set_up_vision() -> void:
	if self.vision: self.vision.queue_free()
	
	var newVision = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = visionRange
	col.shape = shape
	newVision.set_collision_layer_value(1,false)
	newVision.set_collision_mask_value(1,false)
	newVision.set_collision_mask_value(3,true)
	add_child(newVision)
	newVision.add_child(col)
	self.vision = newVision
	vision.visible = false


func match_type() -> void:
	match type:
		TYPE.MELEE:
			visionRange = 32
			sprite_2d.texture = MELEENORMALSE if level < 2 else UPMELEENORMALSE
		TYPE.RANGED:
			sprite_2d.texture = RANGEDNORMALSE if level < 2 else UPRANGEDNORMALSE
			health = 2
			damage = 1.5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 2
			ranged = true
		TYPE.SHIELDED:
			visionRange = 32
			damage = 1
			sprite_2d.texture = SHIELDEDNORMALSE if level < 2 else UPSHIELDEDNORMALSE
		TYPE.CRAZED:
			sprite_2d.texture = CRAZEDNORMALSE if level < 2 else UPCRAZEDNORMALSE
			health = 2
			damage = 0.5
			speed = 60
			dodge = 33 if level < 2 else 25
			attack_cd.wait_time = .5
			anim.speed_scale = 2
		TYPE.BOMBER:
			sprite_2d.texture = BOMBERNORMALSE if level < 2 else UPBOMBERNORMALSE
			health = 2
			damage = .5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 3
			ranged = true
		TYPE.FLYING:
			sprite_2d.texture = FLYINGNORMALSE if level < 2 else UPFLYINGNORMALSE
			speed = 40
			health = 3
			damage = 1.5
			attackRange = 50
			visionRange = 70
			attack_cd.wait_time = 2.5
			%HurtShape.shape.size = Vector2(15,15)
			%HurtShape.position = Vector2(6.5,1.5)
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
			health = 4
			damage = 1
			attack_cd.wait_time = 2
			attackRange = 10
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
			#var deathAnim = self.anim.get_animation("death")
			#deathAnim.length = 1
		TYPE.FUNGI:
			health = 2
			damage = .75
			attack_cd.wait_time = 2
			attackRange = 80
			visionRange = 100
			ranged = true
		TYPE.ACIDIC:
			health = 2
			damage = .5
			attackRange = 50
			visionRange = 75
			attack_cd.wait_time = 3
			ranged = true
		TYPE.ZOMBIFIED:
			health = .25
			damage = 0.5
			speed = 60
			attack_cd.wait_time = .5
			visionRange = 400
			#sprite_2d.modulate = Color(0.994, 0.834, 0.588, 1.0)
	set_up_vision()
	
	# Find sprite file
	if type > Unit.TYPE.RANGED:
		var typeStr = str(TYPE.keys()[type])
		var path : String = "res://Units/Assets/Ally"
		
		if type == Unit.TYPE.ZOMBIFIED: typeStr = "FUNGI"
		# find folder
		path += typeStr.substr(0,1)
		path += typeStr.substr(1).to_lower()
		# find file
		path += "/Ally"
		path += "Normal" if level <= 1 else "Upgraded"
		path += typeStr.substr(0,1)
		path += typeStr.substr(1).to_lower()
		path += ".png"
		
		sprite_2d.texture = load(path)

#func on_health_change() -> void:
	#var farms = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	#farms = farms.filter(func(b : Building):return b.type == Building.TYPE.FARM)
	#for f : Building in farms:
		#max_health = max_health + 0.5
		#health = max_health
		#
#func on_speed_change() -> void:
	#var saps = get_tree().get_first_node_in_group("BUILDINGSNODE").get_children()
	#saps = saps.filter(func(b : Building):return b.type == Building.TYPE.SAPSTORE)
	#for s : Building in saps:
		#speed = speed + 3

func match_decree_status() -> void:
	if dead : 
		status_sprite.visible = false
		return
	match decree:
		Decree.TYPE.NONE:
			return
		Decree.TYPE.INSPIRATION:
			#print("yesss")
			status_sprite.visible = true
			status_sprite.play("inspiration")
			damage += .5
		Decree.TYPE.DECARE:
			if !dead : return
			status_sprite.visible = false
			process_mode = Node.PROCESS_MODE_PAUSABLE
			modulate.a8 = 255
			anim.play_backwards("death")
			group.deadUnitsArray.remove_at(group.deadUnitsArray.find(self))
			group.unitsArray.append(self)
			dead = false
			health = max_health
		Decree.TYPE.RECON:
			status_sprite.play("recon")
			visionRange += 25
			set_up_vision()
		Decree.TYPE.DEFENSE:
			status_sprite.play("defense")
			resistance += .25
		Decree.TYPE.RENOVATE:
			pass # do nothing
		Decree.TYPE.WAR:
			pass # do nothing
		Decree.TYPE.CONSCRIPTION:
			pass # do nothing
		Decree.TYPE.MASTERY:
			status_sprite.play("mastery")
			level += 1 if level == 1 else 0
			vision.queue_free()
			match_type()
			max_health = max_health + 0.5
			health = max_health
			damage = damage + 0.5
		Decree.TYPE.CONSTRUCTION:
			pass # do nothing
		Decree.TYPE.FORTITUDE:
			#print("hardy")
			status_sprite.visible = true
			status_sprite.play("hardy")
			damage += .25
			visionRange *= 1.5
			max_health += 2
			health += 2
			speed *= .33
	status_sprite.visible = true 

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
		"strafe":
			action = ACTION.STRAFE
		"heal":
			action = ACTION.HEAL
			nav.target_position = allyGroup.house.entrance.global_position
			set_collision_layer_value(1,false)
			#hit_box.set_collision_layer_value(2,false)
		"dead":
			action = ACTION.DEAD
		"stunned":
			action = ACTION.STUNNED


# select unit to select whole group of unit
var under_mouse : bool = false
func _on_behind_wall_mouse_entered() -> void:
	if dead or type == TYPE.ZOMBIFIED : return
	under_mouse = true
	allyGroup._on_select_area_mouse_entered()
func _on_behind_wall_mouse_exited() -> void:
	if dead or type == TYPE.ZOMBIFIED: return
	under_mouse = false
	allyGroup._on_select_area_mouse_exited()
func _on_behind_wall_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if dead or type == TYPE.ZOMBIFIED: return
	if allyGroup.is_under_mouse and event.is_action_pressed("select"):
		allyGroup.selected = !allyGroup.selected
		if allyGroup.selected: 
			allyGroup.on_selected()
			allyGroup._on_select_area_mouse_entered()
			allyGroup.is_under_mouse = false
			allyGroup.highlight_houses()
