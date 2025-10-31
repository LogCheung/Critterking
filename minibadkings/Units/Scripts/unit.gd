extends CharacterBody2D
class_name Unit

enum ACTION {
	NONE,FORM, FIGHT, RAID, STRAFE, HEAL, STUNNED, DEAD
}
enum TYPE {
	NONE, MELEE, SHIELDED, RANGED, TRAPJAW, EXPLOSIVE, FUNGI, 
	PARALYTIC, RESILIENT, STINGER, ACIDIC, 
	FLYING,CRAZED, ZOMBIFIED, BOMBER,
}
enum STATUS {
	NONE, STUNNED, POISONED, REGEN
}

signal selected
signal unselected

const HIGHLIGHT = preload("res://Units/Shaders/unitHighlight.tres")

@export var health : float = 4
@export var max_health : float = 4
@export var resistance : float = 0
@export var damage : float = 2
@export var speed : float = 30
@export var attackRange : float = 10
@export var visionRange : float = 32
@export var dodge : int = 0
@export var stun_chance : int = 0
@export var poison_chance : int = 0
@export var knock_chance : int = 0
@export var level : int = 1
@export var formation_position : Node2D 
@export var group : Group
@export var type : TYPE = TYPE.MELEE
@export var decree : Decree.TYPE
@export var upgraded : bool = false
@export var ranged : bool = false
@export var statusArray : Array

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var status_sprite: AnimatedSprite2D = %StatusSprite
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var attack_cd: Timer = %AttackCD
@onready var vision: Area2D = $Vision if self is Enemy else null
@onready var hurtbox_cd: Timer = %HurtboxCD
@onready var hit_box: Area2D = %HitBox
@onready var death: AudioStreamPlayer = %Death
@onready var hurt: AudioStreamPlayer = %Hurt
@onready var stun_cd: Timer = %StunCD
@onready var stun_fatigue: Timer = %StunFatigue
@onready var damage_timer: Timer = %DamageTimer
@onready var healing_timer: Timer = %HealingTimer

var next_path_pos

var action : ACTION = ACTION.NONE
var in_formation : bool = false
var in_combat : bool = false
var path_points : Array
var ranged_buffer : float = 20

var is_behind_wall : bool
var wall_tile

var target
var attacking : bool
var distance_from_form : float = 0.0
var attack_ready : bool
var too_close : bool
var dashing : bool
var knocked : bool = false
var is_stunned : bool

var dead : bool

func _ready() -> void:
	nav.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	%NavDelay.timeout.connect(on_nav_delay)
	stun_cd.timeout.connect(on_stun_finished)
	damage_timer.timeout.connect(on_damage_timer)
	healing_timer.timeout.connect(on_healing_timer)
	%HurtBox.area_entered.connect(on_hurt_box_land)
	%HurtBox.body_entered.connect(on_hurt_box_building_land)
	
	if type == TYPE.ZOMBIFIED:
		await get_tree().create_timer(7.5).timeout
		start_death()

func _process(_delta: float) -> void:
	is_stunned = statusArray.has(STATUS.STUNNED)
	attack_ready = attack_cd.time_left <= 0
	
	check_formation()
	
func check_formation() -> void:
	# zombie has no formation
	if type == TYPE.ZOMBIFIED: 
		in_formation = false
		distance_from_form = 2.0
		return
	
	distance_from_form = global_position.distance_to(formation_position.global_position)
	
	if global_position.distance_to(formation_position.global_position) <= 2:
		# precheck if it is behind something
		is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
		if !is_behind_wall: wall_tile = null
		
		in_formation = true
	else:
		in_formation = false
func handle_behind_wall() -> void:
	is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
	# not liking but looks for closest tile by going all wall tiles and makes transparent
	if is_behind_wall:
		var walls : Array
		for x in range(4):
			for y in range(13,20):
				walls.append_array(tileWorld.obstacles.get_used_cells_by_id(1,Vector2i(x,y)))
		
		
		wall_tile = walls.front()
		for w in walls:
			var w_local_pos = tileWorld.wall.map_to_local(w)
			var wall_tile_local_pos = tileWorld.wall.map_to_local(wall_tile)
			var cur_dist = global_position.distance_to(wall_tile_local_pos)
			var next_dist = global_position.distance_to(w_local_pos)
			if next_dist < cur_dist :
				wall_tile = w
		
		var atlas = tileWorld.obstacles.get_cell_atlas_coords(wall_tile)
		var source = tileWorld.obstacles.get_cell_source_id(wall_tile)
		tileWorld.obstacles.set_cell(wall_tile,source,atlas,1)

func move_to(direction, _delta):
	if knocked : return
	
	if direction.x > 0.1:
		$Flip.scale.x = 1
	elif direction.x < -0.1:
		$Flip.scale.x = -1
		
	var new_velocity = direction * speed
	velocity = new_velocity
	
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
		
	if action == ACTION.STRAFE:
		velocity /= 4
	if dashing:
		velocity *= 2.5
		
	move_and_slide()
	
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
# Attacking
func attack_finished() -> void:
	attacking = false
	dashing = false
	# Custom attacks such as ranged or dash attacks
	if !target : return
	match type:
		TYPE.RANGED, TYPE.FUNGI:
			var proj = load("res://Units/Scenes/projectile.tscn").instantiate()
			proj.DIRECTION = global_position.direction_to(target.global_position)
			proj.type = type
			proj.global_position = global_position
			proj.damage = damage
			proj.raiding = action == ACTION.RAID
			proj.is_fungus = type == TYPE.FUNGI
			proj.is_enemy = self is Enemy
			get_tree().get_first_node_in_group("WORLD").add_child(proj)
			proj.set_owner(get_tree().get_current_scene())
		TYPE.BOMBER:
			var proj = load("res://Units/Scenes/bombard.tscn").instantiate()
			proj.global_position = global_position
			proj._target = target.global_position
			proj.damage = damage
			proj.is_enemy = self is Enemy
			get_tree().get_first_node_in_group("WORLD").add_child(proj)
			proj.set_owner(get_tree().get_current_scene())
		TYPE.ACIDIC:
			for i in range(3):
				var proj = load("res://Units/Scenes/projectile.tscn").instantiate()
				proj.DIRECTION = global_position.direction_to(target.global_position)
				proj.type = type
				proj.damage = damage
				proj.raiding = action == ACTION.RAID
				proj.is_enemy = self is Enemy
				
				if abs(global_position.y - target.global_position.y) < 20 :
					proj.global_position = global_position - Vector2(0,8)
					proj.global_position += (Vector2(0,8) * i)
				else:
					proj.global_position = global_position - Vector2(8,0)
					proj.global_position += (Vector2(8,0) * i)
				
				get_tree().get_first_node_in_group("WORLD").add_child(proj)
				proj.set_owner(get_tree().get_current_scene())
func find_target() -> void:
	target = null
	if !vision.monitoring: return
	var enemies = vision.get_overlapping_areas().map(func(a):return a.owner)
	enemies = enemies.filter(func(e : Unit):return !e.dead)
	find_closest(enemies)
	if !target : return 
	nav.target_position = target.global_position

func find_closest(nodeArray : Array) -> void:
	if nodeArray.is_empty() : return
	
	# finds closest in range enemy and makes it our target
	var closest = nodeArray.front()
	for node in nodeArray:
		var cur_dist = global_position.distance_to(closest.global_position)
		var next_dist = global_position.distance_to(node.global_position)
		if next_dist < cur_dist:
			closest = node
	target = closest

func on_hurt_box_land(area : Area2D) -> void:
	if hurtbox_cd.time_left > 0 : return
	if area.owner is Unit:
		var enemy : Unit = area.owner
		
		%Hurt.play()
		
		if enemy.dodge < (randi() % 100 + 1): # check for miss
			if knock_chance >= (randi() % 100 + 1):
				var dir = -enemy.global_position.direction_to(global_position)
				enemy.take_knockback(dir)
			enemy.health -= damage - enemy.resistance
			enemy.hitAnim(true)
		else: enemy.hitAnim(false)
		
		if enemy.health <= 0:
			# trigger death anim
			enemy.start_death()
		
		# check for knockback
		
		# check for poison
		if poison_chance >= (randi() % 100 + 1):
			enemy.statusArray.append(Unit.STATUS.POISONED)
			enemy.statusArray.append(Unit.STATUS.POISONED)
			enemy.statusArray.append(Unit.STATUS.POISONED)
			
		# check for stun
		if enemy.stun_fatigue.time_left <= 0 and stun_chance >= (randi() % 100 + 1):
			enemy.statusArray.append(Unit.STATUS.STUNNED)
		
		hurtbox_cd.start()
func on_hurt_box_building_land(body : Node2D):
	if body is Building and action == ACTION.RAID:
		if body.type != Building.TYPE.TRAP or body.type != Building.TYPE.RUINS:
			body.health -= damage
	pass

func hitAnim(hit : bool, status : STATUS = STATUS.NONE) -> void:
	var reg = Color(1,1,1)
	var mod = Color(1.0, 0.0, 0.0, 1.0)
	
	# set modulate to custom based on status
	match status:
		STATUS.NONE:
			if self is Enemy: mod = Color(2, 0.0, 0.0, 2)
		STATUS.POISONED:
			mod = Color(.6,.0,1)
		STATUS.REGEN:
			mod = Color(0,2.0,0)
			
	if hit:
		modulate = mod
		await get_tree().create_timer(.05).timeout
		set_modulate(reg)
	else: # dodged
		modulate.a = 0.8
		await get_tree().create_timer(.05).timeout
		modulate.a = 1
func start_death(destroy : bool = false) -> void:
	dead = true
	status_sprite.visible = false
	sprite_2d.material = null
	process_mode = Node.PROCESS_MODE_DISABLED
	anim.play("death")
	await anim.animation_finished
	
	z_index = 0
	modulate.a8 = 200
	
	# remove from group unless is zombified
	if type == TYPE.ZOMBIFIED :
		queue_free()
		return
	var unitArr = group.unitsArray
	if unitArr.find(self) != -1 : unitArr.remove_at(unitArr.find(self))
	group.unit_died.emit()
	group.deadUnitsArray.append(self)
	
	%Death.play()
	if self is Ally :
		var ui : UI = get_tree().get_first_node_in_group("UI")
		ui.ally_died.emit()
	#queue_free()

func take_knockback(dir : Vector2) -> void:
	knocked = true
	dir = dir.normalized()
	var knockSpeed = 250
	velocity = dir * knockSpeed
	move_and_slide()
	
	await get_tree().create_timer(.175).timeout
	knocked = false
	pass

func on_stun_finished() -> void:
	statusArray.remove_at(statusArray.find(STATUS.STUNNED))
	stun_fatigue.start()
	status_sprite.stop()
	status_sprite.visible = false
	attack_cd.paused = false
	is_stunned = false

func explode_on_death() -> void:
	if type != TYPE.EXPLOSIVE : return # check is explosive
	# create explosion hurtbox area
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	area.process_mode = Node.PROCESS_MODE_ALWAYS
	shape.radius = 12
	shape.height = 40
	col.rotation = 90
	col.shape = shape
	area.add_child(col)
	area.set_collision_layer_value(1,false)
	area.set_collision_mask_value(1,false)
	if self is Enemy:
		area.set_collision_mask_value(2,true)
	else:
		# default texture is splash texture
		area.set_collision_mask_value(3, true)
	add_child(area)
	# wait three frames
	for i in range(3):
		await get_tree().process_frame
	# check for enemies under explosion
	for a in area.get_overlapping_areas():
		if !a or !a.owner is Unit: continue
		var enemy : Unit = a.owner
		%Hurt.play()
		if enemy.dodge < (randi() % 100 + 1): 
			enemy.health -= 0.5 
			enemy.hitAnim(true)
		else:enemy.hitAnim(false)
		if enemy.health <= 0:
			# trigger death anim
			enemy.start_death()
	
	# destroy self
	await get_tree().create_timer(.5).timeout
	queue_free()
	pass
func on_damage_timer() -> void:
	if statusArray.has(STATUS.POISONED):
		health -= .5
		if health <= 0:
			start_death()
		hitAnim(true, STATUS.POISONED)
		statusArray.remove_at(statusArray.find(STATUS.POISONED))
	pass
func on_healing_timer() -> void:
	if type == TYPE.RESILIENT: statusArray.append(STATUS.REGEN)
	if statusArray.has(STATUS.REGEN):
		if health >= max_health : return
		health += .5
		hitAnim(true,STATUS.REGEN)
		statusArray.remove_at(statusArray.find(STATUS.REGEN))
	pass
func on_nav_delay() -> void:
	next_path_pos = nav.get_next_path_position()
	pass
