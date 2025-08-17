extends AnimatedSprite2D

func _ready() -> void:
	play("default")
	await animation_finished
	queue_free()
