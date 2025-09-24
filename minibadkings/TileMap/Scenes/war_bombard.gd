extends AnimatedSprite2D

@export var damage : float

@onready var hurt_box: Area2D = %hurtBox

func _ready() -> void:
	await get_tree().create_timer(2).timeout
	play("default")
	await animation_finished
	check_aoe()

func check_aoe() -> void:
	$Timer.start()
	var areas = hurt_box.get_overlapping_areas()
	for area in areas:
		if !area or !area.owner is Unit: continue
		var enemy : Unit = area.owner
		%Hurt.play()
		enemy.health -= damage if enemy.dodge < (randi() % 100 + 1) else 0.0
		if enemy.health <= 0:
			# trigger death anim
			enemy.start_death()


func _on_timer_timeout() -> void:
	queue_free()
