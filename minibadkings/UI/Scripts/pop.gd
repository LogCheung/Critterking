class_name Pop
extends Label

signal pop_finished

var travel: Vector2 = Vector2(0, -50)
var duration: float = 1
var speed: float = PI / 4


func show_value(value: int):
	scale = Vector2(.5,.5)
	var tween = create_tween()
	var valSign = "-" if value < 0 else "+"
	text = valSign + " " + str(abs(value))
	pivot_offset = size / 6
	var movement = travel.rotated(randi_range(-speed / 2, speed / 2))
	
	# color
	if valSign == "+":
		modulate = Color(0.0, 2.52, 0.0, 1.0)
	else:
		modulate = Color(3.371, 0.0, 0.0, 1.0)
	
	#Aniamte In
	tween.tween_property(self, "position", position + movement, duration)
	
	#Fade Out
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.play()
	tween.tween_callback(queue_free)
	
	#await get_tree().create_timer(duration/4.0).timeout
	pop_finished.emit()
