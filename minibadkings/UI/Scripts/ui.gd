extends CanvasLayer
class_name UI

@onready var cards: Control = %Cards
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hand: Control = %Hand
@onready var mainmenu: Control = %mainmenu
@onready var help: Control = %Help
@onready var settings: Control = %Settings
@onready var world = get_tree().get_first_node_in_group("WORLD")

func display_cards(display : bool) -> void:
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	for card in cardSprites:
		card.visible = display
func show_hand() -> void:
	cards.hide()
	hand.show()

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


func _on_endturn_pressed() -> void:
	world.night_started.emit()
