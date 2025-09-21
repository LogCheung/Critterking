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

const UPMELEENORMALSE = preload("res://Units/Assets/AllyMelee/AllyMeleeUpgradedSE.png")
const UPRANGEDNORMALSE = preload("res://Units/Assets/AllyRanged/AllyRangedUpgradedSE.png")
const UPSHIELDEDNORMALSE = preload("res://Units/Assets/AllyShield/AllyShieldUpgradedSE.png")
const UPCRAZEDNORMALSE = preload("res://Units/Assets/AllyCrazed/AllyCrazedUpgradedSE.png")
const UPMELEENORMALNW = preload("res://Units/Assets/AllyMelee/AllyMeleeUpgradedNW.png")
const UPRANGEDNORMALNW = preload("res://Units/Assets/AllyRanged/AllyRangedUpgradedNW.png")
const UPSHIELDEDNORMALNW = preload("res://Units/Assets/AllyShield/AllyShieldUpgradedNW.png")
const UPBOMBERNORMALSE = preload("res://Units/Assets/AllyBombardier/AllyBombardierUpgradedSE.png")
const UPFLYINGNORMALSE = preload("res://Units/Assets/AllyFlying/AllyFlyingUpgradedSE.png")

@onready var world : World = get_tree().get_first_node_in_group("WORLD")

var allyGroup : AllyGroup
var healing : bool


func _ready() -> void:
	allyGroup = group
	if level > 1: 
		max_health = max_health + 0.5
		health = max_health
		damage = damage + 0.5
		
	
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
func handle_behind_wall() -> void:
	is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
	# not liking but looks for closest tile by going all wall tiles and makes transparent
	if is_behind_wall:
		var walls = tileWorld.wall.get_used_cells_by_id(0,Vector2(0,2),2)
		walls.append_array(tileWorld.wall.get_used_cells_by_id(0,Vector2(0,2),1))
		
		wall_tile = walls.front()
		for w in walls:
			
			var w_local_pos = tileWorld.wall.map_to_local(w)
			var wall_tile_local_pos = tileWorld.wall.map_to_local(wall_tile)
			var cur_dist = global_position.distance_to(wall_tile_local_pos)
			var next_dist = global_position.distance_to(w_local_pos)
			if next_dist < cur_dist :
				wall_tile = w
		
		tileWorld.wall.set_cell(wall_tile,0,Vector2(0,2),1)

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
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)

func on_selected() -> void:
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
			sprite_2d.texture = MELEENORMALSE if !upgraded else UPMELEENORMALSE
		TYPE.RANGED:
			sprite_2d.texture = RANGEDNORMALSE if !upgraded else UPRANGEDNORMALSE
			health = 2
			damage = 1.5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 2
		TYPE.SHIELDED:
			visionRange = 32
			damage = 1
			sprite_2d.texture = SHIELDEDNORMALSE if !upgraded else UPSHIELDEDNORMALSE
		TYPE.CRAZED:
			sprite_2d.texture = CRAZEDNORMALSE if !upgraded else UPCRAZEDNORMALSE
			health = 2
			damage = 0.75
			speed = 60
			dodge = 25
			attack_cd.wait_time = .5
		TYPE.BOMBER:
			sprite_2d.texture = BOMBERNORMALSE if !upgraded else UPBOMBERNORMALSE
			health = 2
			damage = .5
			attackRange = 80
			visionRange = 100
			attack_cd.wait_time = 3
		TYPE.FLYING:
			sprite_2d.texture = FLYINGNORMALSE if !upgraded else UPFLYINGNORMALSE
			speed = 40
			health = 3
			damage = 1.5
			attackRange = 50
			visionRange = 70
			attack_cd.wait_time = 2.5
			%HurtShape.shape.size = Vector2(15,15)
			%HurtShape.position = Vector2(6.5,1.5)
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


# select unit to select whole group of unit
var under_mouse : bool = false
func _on_behind_wall_mouse_entered() -> void:
	under_mouse = true
	allyGroup._on_select_area_mouse_entered()
func _on_behind_wall_mouse_exited() -> void:
	under_mouse = false
	allyGroup._on_select_area_mouse_exited()
func _on_behind_wall_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if allyGroup.is_under_mouse and event.is_action_pressed("select"):
		allyGroup.selected = !allyGroup.selected
		if allyGroup.selected: 
			allyGroup.on_selected()
			allyGroup._on_select_area_mouse_entered()
			allyGroup.is_under_mouse = false
			allyGroup.highlight_houses()
