extends Node2D
class_name BuildingsNode

@onready var ui : UI = get_tree().get_first_node_in_group("UI")

func _update_traits() -> void:
	#ui.culture_trait
	pass

func _update_resources() -> void:
	ui.satisfaction_label.text = str( Global.satisfaction)
	ui.money_label.text = str(Global.money)
	ui.food_label.text = str(Global.food)
	ui.citizen_label.text = str(Global.citizens)
	pass
