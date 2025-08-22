extends Camera2D

@export var move_speed: float = 10
@export var zoom_speed: float = 0.125
@export var min_zoom: float = 1
@export var max_zoom: float = 3
@export var boost_speed: float = 2.0

func _process(delta):
	var velocity = Vector2.ZERO
	var base_speed = move_speed
	
	if Input.is_action_pressed("speedup_camera"):
		base_speed *= boost_speed

	if Input.is_action_pressed("camera_move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("camera_move_down"):
		velocity.y += 1
	if Input.is_action_pressed("camera_move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("camera_move_right"):
		velocity.x += 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * base_speed
	
	position += velocity
	
		# Handle Zoom
	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom -= Vector2(zoom_speed, zoom_speed)
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom += Vector2(zoom_speed, zoom_speed)

	# Clamp the zoom to the defined limits
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
