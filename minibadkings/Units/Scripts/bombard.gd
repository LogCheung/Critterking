extends Path2D

@export var damage : float
@export var is_enemy : bool

@onready var hurt_box: Area2D = %HurtBox

var num_of_points : float = 30.0
var gravity : float = -9.8
var _target : Vector2

func _ready() -> void:
	if is_enemy:
		%Splash.texture = preload("res://Units/Assets/EnemySplash.png")
		hurt_box.set_collision_mask_value(2,true)
	else:
		# default texture is splash texture
		hurt_box.set_collision_mask_value(3, true)
	calculate_trajectory(global_position,_target)

func calculate_trajectory(_start,_end) -> void:
	var DOT = Vector2(1,0).dot((_end - _start).normalized())
	var angle = 90 - 45 * DOT
	
	var x_dis = _end.x - _start.x
	var y_dis = -1.0 * (_end.y - _start.y)
	
	var speed = sqrt(((0.5 * gravity * x_dis * x_dis ) / pow(cos(deg_to_rad(angle)),2.0)) /(y_dis - (tan(deg_to_rad(angle)) * x_dis)))
	var x_comp = (cos(deg_to_rad(angle)) * speed) 
	var y_comp = (sin(deg_to_rad(angle)) * speed)
	
	var total_time = x_dis / x_comp 
	var new_curve = Curve2D.new()
	var points = []
	
	for point in num_of_points:
		var time = total_time * (point/num_of_points)
		var dx = time * x_comp
		var dy = -1.0 * (time * y_comp + .5 * gravity * time * time)
		#
		points.append(Vector2(dx,dy))
		new_curve.add_point(Vector2(dx,dy))
	#for p in points:
		#new_curve.add_point(p)
	curve = new_curve
	
	var tween = get_tree().create_tween()
	tween.tween_property(%PathFollow2D,"progress_ratio",1.0,total_time / 3)
	tween.play()
	
	await tween.finished
	check_aoe()

func check_aoe() -> void:
	$Timer.start()
	%Splash.global_position = %Node2D.global_position
	%Anim.play("splash")
	%Sprite2D.visible = false
	var areas = hurt_box.get_overlapping_areas()
	for area in areas:
		if !area or !area.owner is Unit: continue
		var enemy = area.owner
		%Hurt.play()
		enemy.health -= damage if enemy.dodge < (randi() % 100 + 1) else 0
		if enemy.health <= 0:
			# trigger death anim
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.anim.play("death")
			#await enemy.anim.animation_finished
			
			var enemyGroup = enemy.group.unitsArray
			if enemyGroup.find(enemy) != -1 : enemyGroup.remove_at(enemyGroup.find(enemy))
			enemy.group.unit_died.emit()
			%Death.play()
			enemy.queue_free()


func _on_timer_timeout() -> void:
	queue_free()
