extends Sprite2D

enum CARDTYPE {
	NONE,PLATED,BITER,SPITTER, TRAPS,HOUSE,DESTROY
}

@export var type : CARDTYPE
@export var for_show : bool

@onready var ui : UI = get_tree().get_first_node_in_group("UI")


func _on_selected_pressed() -> void:
	if for_show:
		ui.anim.play("cardhide")
	pass # Replace with function body.
