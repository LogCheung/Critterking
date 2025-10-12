extends Area2D

@export var SPEED : float
@export var RANGE : float
@export var DIRECTION : Vector2
@export var damage : float
@export var is_fungus : bool
@export var is_enemy : bool
@export var raiding : bool

const ENEMYPROJ = preload("res://Units/Assets/EnemyProjectile.png")
var travelled_distance = 0

var des_angle = 30
var curYSpeed

func _ready() -> void:
	curYSpeed = SPEED
	if is_enemy:
		$Sprite2D.texture = ENEMYPROJ
		set_collision_mask_value(2,true)
	else:
		set_collision_mask_value(3, true)

func _process(delta):
	position += DIRECTION * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.owner is Unit:
		var target : Unit = area.owner
		# for shielded
		if target.decree == Decree.TYPE.DEFENSE:
			damage -= .25
		if target.type == Unit.TYPE.SHIELDED: 
			damage -= .5
		if target.dodge < (randi() % 100 + 1):
		 # chance to ignore damage while also having reduced damage
			#var rand = randi()
			#if rand % 2 == 0: 
			%Hurt.play()
			target.health -= damage
			target.hitAnim(true)
		else:
			target.hitAnim(false)
		if target.health <= 0:
			target.start_death()
			
			# create a zombified (crazed-like) ally at position if fungus
			if is_fungus:
				var unitsNode : UnitsNode = get_tree().get_first_node_in_group("UNITSNODE")
				unitsNode.create_zombified(target.global_position,is_enemy)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Building and raiding:
		if body.type != Building.TYPE.TRAP or body.type != Building.TYPE.RUINS:
			body.health -= damage
		queue_free()
