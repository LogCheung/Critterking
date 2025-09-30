extends Unit
class_name Ally

signal speedchange
signal healthchange

const MELEENORMALSE = preload("res://Units/Assets/AllyMelee/AllyMeleeNormalSE.png")
const RANGEDNORMALSE = preload("res://Units/Assets/AllyRanged/AllyRangedNormalSE.png")
const SHIELDEDNORMALSE = preload("res://Units/Assets/AllyShield/AllyShieldNormalSE.png")
const CRAZEDNORMALSE = preload("res://Units/Assets/AllyCrazed/AllyCrazedNormalSE.png")
const MELEENORMALNW = preload("res://Units/Assets/AllyMelee/AllyMeleeNormalNW.png")
const RANGEDNORMALNW = preload("res://Units/Assets/AllyRanged/AllyRangedNormalNW.png")
const SHIELDEDNORMALNW = preload("res://Units/Assets/AllyShield/AllyShieldNormalNW.png")
const BOMBERNORMALSE = preload("res://Units/Assets/AllyBombardier/AllyBombardierSE.png")
const FLYINGNORMALSE = preload("res://Units/Assets/AllyFlying/AllyFlyingSE.png")
const PARALYTICNORMALSE = preload("res://Units/Assets/AllyParalytic/AllyNormalParalytic.png")
const RESILIENTNORMALSE = preload("res://Units/Assets/AllyResilient/AllyNormalResilient.png")
const STINGERNORMALSE = preload("res://Units/Assets/AllyStinger/AllyNormalStinger.png")

const UPMELEENORMALSE = preload("res://Units/Assets/AllyMelee/AllyMeleeUpgradedSE.png")
const UPRANGEDNORMALSE = preload("res://Units/Assets/AllyRanged/AllyRangedUpgradedSE.png")
const UPSHIELDEDNORMALSE = preload("res://Units/Assets/AllyShield/AllyShieldUpgradedSE.png")
const UPCRAZEDNORMALSE = preload("res://Units/Assets/AllyCrazed/AllyCrazedUpgradedSE.png")
const UPMELEENORMALNW = preload("res://Units/Assets/AllyMelee/AllyMeleeUpgradedNW.png")
const UPRANGEDNORMALNW = preload("res://Units/Assets/AllyRanged/AllyRangedUpgradedNW.png")
const UPSHIELDEDNORMALNW = preload("res://Units/Assets/AllyShield/AllyShieldUpgradedNW.png")
const UPBOMBERNORMALSE = preload("res://Units/Assets/AllyBombardier/AllyBombardierUpgradedSE.png")
const UPFLYINGNORMALSE = preload("res://Units/Assets/AllyFlying/AllyFlyingUpgradedSE.png")
const UPPARALYTICNORMALSE = preload("res://Units/Assets/AllyParalytic/AllyUpgradedParalytic.png")
const UPRESILIENTNORMALSE = preload("res://Units/Assets/AllyResilient/AllyUpgradedResilient.png")
const UPSTINGERNORMALSE = preload("res://Units/Assets/AllyStinger/AllyUpgradedStinger.png")

@onready var world : World = get_tree().get_first_node_in_group("WORLD")

var allyGroup : AllyGroup
var healing : bool

func _ready() -> void:
	allyGroup = group
	if level > 1:  # if upgraded
		max_health = max_health + 0.5
		health = max_health
		damage = damage + 0.5
		upgraded = true
		
	
	super._ready()
	selected.connect(on_selected)
	#healthchange.connect(on_health_change)
	#speedchange.connect(on_speed_change)
	unselected.connect(on_unselected)
	match_type()
	
	await get_tree().create_timer(.5).timeout
	set_collision_layer_value(1,true)

func _process(delta: float) -> void:
	super._process(delta)
	if action != ACTION.NONE:
		handle_behind_wall()
		
	# Check if in combat
	if vision.has_overlapping_areas(): # inside sight of ally
		for area in vision.get_overlapping_areas(): # not dead and not in walls
			in_combat = is_instance_valid(area.owner) and area.owner.is_active
	else:
		in_combat = false
	
	# check if enemy is too close
	if type == TYPE.RANGED or type == TYPE.BOMBER:
		if is_instance_valid(target):
			var distToTarget = global_position.distance_to(target.global_position)
			too_close = distToTarget < ranged_buffer
	
	handle_action(delta)

func handle_action(delta) -> void:
	var distToTarget = global_position.distance_to(nav.target_position)
	if dashing:
		if !target : 
			find_target()
			return
		var dir = global_position.direction_to(target.global_position)
		move_to(dir,delta)
		return
	
	match action:
		ACTION.NONE:
			anim.play("idle")
			visible = true
			return
		ACTION.FORM:
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
				if anim.is_playing() : return
				if type == TYPE.CRAZED : anim.speed_scale = 2
				anim.play("attack")
				dashing = type == TYPE.FLYING
				if type== TYPE.RANGED or type == TYPE.BOMBER:
					%Shoot.play()
				else:
					%Attack.play()
				await anim.animation_finished
				anim.speed_scale = 1
				velocity = Vector2.ZERO
				attack_cd.start()
				attacking = true
				return
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
				return
		ACTION.DEAD:
			return
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)

func on_selected() -> void:
	if dead : return
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null

func set_up_vision() -> void:
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
	vision = newVision
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
		TYPE.SHIELDED:
			visionRange = 32
			damage = 1
			sprite_2d.texture = SHIELDEDNORMALSE if level < 2 else UPSHIELDEDNORMALSE
		TYPE.CRAZED:
			sprite_2d.texture = CRAZEDNORMALSE if level < 2 else UPCRAZEDNORMALSE
			health = 2
			damage = 0.75
			speed = 60
			dodge = 33
			attack_cd.wait_time = .5
		TYPE.BOMBER:
			sprite_2d.texture = BOMBERNORMALSE if level < 2 else UPBOMBERNORMALSE
			health = 2
			damage = .5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 3
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
			attack_cd.wait_time = 2.5
		TYPE.RESILIENT:
			sprite_2d.texture = RESILIENTNORMALSE if !upgraded else UPRESILIENTNORMALSE
		TYPE.STINGER:
			sprite_2d.texture = STINGERNORMALSE if !upgraded else UPSTINGERNORMALSE
	set_up_vision()

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
	match decree:
		Decree.TYPE.NONE:
			return
		Decree.TYPE.INSPIRATION:
			status_sprite.play("inspiration")
			damage += .5
		Decree.TYPE.DECARE:
			if !dead : return
			process_mode = Node.PROCESS_MODE_PAUSABLE
			modulate.a8 = 255
			anim.play_backwards("death")
			group.deadUnitsArray.remove_at(group.deadUnitsArray.find(self))
			group.unitsArray.append(self)
			dead = false
			health = max_health
		Decree.TYPE.RECON:
			status_sprite.play("recon")
			visionRange += 10
			vision.queue_free()
			set_up_vision()
		Decree.TYPE.DEFENSE:
			status_sprite.play("defense")
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
		Decree.TYPE.INFLUENCE:
			pass # do nothing
		Decree.TYPE.CONSTRUCTION:
			pass # do nothing
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
			hit_box.set_collision_layer_value(2,false)
		"dead":
			action = ACTION.DEAD


# select unit to select whole group of unit
var under_mouse : bool = false
func _on_behind_wall_mouse_entered() -> void:
	if dead : return
	under_mouse = true
	allyGroup._on_select_area_mouse_entered()
func _on_behind_wall_mouse_exited() -> void:
	if dead : return
	under_mouse = false
	allyGroup._on_select_area_mouse_exited()
func _on_behind_wall_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if dead : return
	if allyGroup.is_under_mouse and event.is_action_pressed("select"):
		allyGroup.selected = !allyGroup.selected
		if allyGroup.selected: 
			allyGroup.on_selected()
			allyGroup._on_select_area_mouse_entered()
			allyGroup.is_under_mouse = false
			allyGroup.highlight_houses()
