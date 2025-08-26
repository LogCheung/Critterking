extends Path2D

@export var damage : float
@export var is_enemy : bool

var num_of_points : int = 30
var gravity : float = -9.8
var _target : Vector2

func _ready() -> void:
	calculate_trajectory(global_position,_target)
	pass

func calculate_trajectory(_start,_end) -> void:
	var DOT = Vector2(1,0).dot((_end - _start).normalized())
	var angle = 90 - 45 * DOT
	
	var x_dis = _end.x - _start.x
	var y_dis = -1.0 * (_end.y - _start.y)
	
	var speed = sqrt(((0.5 * gravity * x_dis * x_dis ) / pow(cos(deg_to_rad(angle)/(y_dis - (tan(deg_to_rad(angle)) * x_dis))),2)))
	var x_comp = (cos(deg_to_rad(angle)) * speed)
	var y_comp = (sin(deg_to_rad(angle)) * speed)
	
	var total_time = x_dis/ x_comp
	var new_curve = Curve2D.new()
	
	for point in num_of_points:
		var time = total_time * (point/num_of_points)
		var dx = time * x_comp
		var dy = -1.0 * (time * y_comp + .5 * gravity * time * time)
		
		new_curve.add_point(Vector2(dx,dy))
		
	curve = new_curve
	
	var tween = Tween.new()
	add_child(tween)
	tween.tween_property(%PathFollow2D,"unit_offset",1.0,total_time)
	tween.play()
	
	await tween.finished
	queue_free()
