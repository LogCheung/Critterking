extends Area2D

@export var SPEED : float
@export var RANGE : float
@export var DIRECTION : Vector2
@export var damage : int
@export var is_enemy : bool

var travelled_distance = 0

func _ready() -> void:
	if is_enemy:
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
		if target.type == Unit.TYPE.SHIELDED:
		 # chance to ignore damage while also having reduced damage
			#var rand = randi()
			#if rand % 2 == 0: 
			target.health -= damage - 1
		else:
			%Hurt.play()
			target.health -= damage 
		if target.health <= 0:
			var group = target.group.unitsArray
			if group.find(target) != - 1: group.remove_at(group.find(target))
			target.group.unit_died.emit()
			%Death.play()
			target.queue_free()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Building:
		body.health -= damage
	queue_free()
