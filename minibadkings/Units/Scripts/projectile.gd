extends Area2D

@export var SPEED : float
@export var RANGE : float
@export var DIRECTION : Vector2
@export var damage : float
@export var type : Unit.TYPE
@export var is_fungus : bool = false
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
	
	if type == Unit.TYPE.ACIDIC:
		$Sprite2D.texture = load("res://Units/Assets/AllyAcid.png") if !is_enemy else load("res://Units/Assets/EnemyAcid.png")
	elif type == Unit.TYPE.FUNGI:
		$Sprite2D.texture = load("res://Units/Assets/allyspore.png") if !is_enemy else load("res://Units/Assets/enemyspore.png")
		
	# run chance for angle offset
	#if randi_range(0,3) == 0 : 
	offset_angle()

func _process(delta):
	position += DIRECTION * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

# off angle chance
func offset_angle() -> void:
	var off : float =  .3
	DIRECTION += Vector2(randf_range(-off,off),randf_range(-off,off))
	pass

func _on_area_entered(area: Area2D) -> void:
	if area.owner is Unit:
		var target : Unit = area.owner
		# for shielded
		if target.type == Unit.TYPE.SHIELDED: 
			damage -= .5 if type == Unit.TYPE.RANGED else .25
		if target.type == Unit.TYPE.RESILIENT: 
			damage -= .25 if type == Unit.TYPE.RANGED else 0.0
		if target.dodge < (randi() % 100 + 1):
		 # chance to ignore damage while also having reduced damage
			#var rand = randi()
			#if rand % 2 == 0: 
			if damage - target.resistance > 0: target.health -= damage - target.resistance
			else: target.health -= damage
			target.hitAnim(true)
		else:
			target.hitAnim(false)
		if target.health <= 0:
			target.start_death()
			
			# create a zombified (crazed-like) ally at position if fungus
			if is_fungus:
				if target.type == Unit.TYPE.ZOMBIFIED : return
				if randi_range(1,100) <= 30 : return
				var unitsNode : UnitsNode = get_tree().get_first_node_in_group("UNITSNODE")
				unitsNode.create_zombified(target.global_position,is_enemy)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Building and raiding:
		if body.type != Building.TYPE.TRAP or body.type != Building.TYPE.RUINS:
			body.health -= damage
		queue_free()
