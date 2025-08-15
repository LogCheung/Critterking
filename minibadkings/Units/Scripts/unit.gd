extends CharacterBody2D
class_name Unit

enum ACTION {
	NONE,FORM, FIGHT, RAID, STRAFE, HEAL
}
enum TYPE {
	NONE, MELEE, SHIELDED, RANGED
}

signal selected
signal unselected

const HIGHLIGHT = preload("res://Units/Shaders/unitHighlight.tres")

@export var health : int = 4
@export var max_health : int = 4
@export var damage : int = 2
@export var speed : float = 30
@export var attackRange : float = 10
@export var formation_position : Node2D 
@export var group : Group
@export var type : TYPE = TYPE.MELEE
@export var upgraded : bool = false

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var attack_cd: Timer = $AttackCD
@onready var vision: Area2D = $Vision
@onready var hurtbox_cd: Timer = $HurtboxCD
@onready var hit_box: Area2D = %HitBox

var action : ACTION = ACTION.NONE
var in_formation : bool = false
var in_combat : bool = false
var path_points : Array

var is_behind_wall : bool
var wall_tile

var target
var attacking : bool
var distance_from_form : float = 0.0
var attack_ready : bool
var too_close : bool


func _ready() -> void:
	nav.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	%HurtBox.area_entered.connect(on_hurt_box_land)
	%HurtBox.body_entered.connect(on_hurt_box_building_land)
	pass

func _process(_delta: float) -> void:
	attack_ready = attack_cd.time_left <= 0
	distance_from_form = global_position.distance_to(formation_position.global_position)
	
	
	if global_position.distance_to(formation_position.global_position) <= 2:
		# precheck if it is behind something
		is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
		if !is_behind_wall: wall_tile = null
		
		in_formation = true
	else:
		in_formation = false
	

func move_to(direction, _delta):
	if direction.x > 0:
		$Flip.scale.x = 1
	else:
		$Flip.scale.x = -1
		
	var new_velocity = direction * speed
	velocity = new_velocity
	if action == ACTION.STRAFE:
		velocity /= 4
	
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
		
	move_and_slide()
	
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
# Attacking
func attack_finished() -> void:
	attacking = false
	# Shooting after animation finished
	if !target : return
	if type == TYPE.RANGED:
		var proj = preload("res://Units/Scenes/projectile.tscn").instantiate()
		proj.DIRECTION = global_position.direction_to(target.global_position)
		proj.global_position = global_position
		proj.damage = damage
		proj.is_enemy = self is Enemy
		get_tree().get_first_node_in_group("WORLD").add_child(proj)

func find_target() -> void:
	target = null
	if !vision.monitoring: return
	var enemies = vision.get_overlapping_areas().map(func(a):return a.owner)
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
		enemy.health -= damage
		if enemy.health <= 0:
			var enemyGroup = enemy.group.unitsArray
			if enemyGroup.find(enemy) != -1 : enemyGroup.remove_at(enemyGroup.find(enemy))
			enemy.group.unit_died.emit()
			enemy.queue_free()
			hurtbox_cd.start()
func on_hurt_box_building_land(body : Node2D):
	if body is Building:
		print("ok")
	pass
