class_name InspectControl
extends Control

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var inspection_card: Card = %InspectionCard


func _input(event: InputEvent) -> void:
	if event.is_action("pause"):
		self.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("select"):
		self.visible = false

func inspect_card(type : Card.CARDTYPE, charm : Charm = null):
	# clear charm position
	inspection_card.charm = null
	for c in inspection_card.charm_pos.get_children():
		c.queue_free()
	
	# play animation and show card
	ui.anim.play("InspectShow")
	inspection_card.type = int(type)
	inspection_card.match_sprite_type()
	
	# add charm
	if charm:
		# add clone charm
		var cloneCharm : Charm = load("res://Units/Scenes/charm.tscn").instantiate()
		cloneCharm.type = charm.type
		cloneCharm.is_on_inspected_card = true
		
		inspection_card.charm = cloneCharm
		inspection_card.charm_pos.add_child(cloneCharm)
	
