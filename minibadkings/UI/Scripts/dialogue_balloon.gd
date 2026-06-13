extends DialogueManagerExampleBalloon

@onready var choices: Control = %Choices

func _on_responses_menu_visibility_changed() -> void:
	await get_tree().process_frame
	if !responses_menu or responses_menu.visible:
		choices.show()
	else:
		choices.hide()
