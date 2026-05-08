class_name StatusControl
extends Control

@onready var status_sprite: AnimatedSprite2D = %StatusSprite

func play(animName : String) -> void:
	status_sprite.play(animName)
	pass

func stop() -> void:
	status_sprite.stop()
