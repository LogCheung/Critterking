extends CanvasLayer
class_name UI

@onready var cards: Control = %Cards
@onready var anim: AnimationPlayer = $AnimationPlayer


func _on_show_pressed() -> void:
	anim.play("cardshow")


func _on_play_pressed() -> void:
	pass # Replace with function body.


func _on_help_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	pass # Replace with function body.


func _on_backhelp_pressed() -> void:
	pass # Replace with function body.

func _on_settingsback_pressed() -> void:
	pass # Replace with function body.
