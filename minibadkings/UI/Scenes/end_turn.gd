class_name EndTurn
extends Control

@onready var ui : UI = get_parent()
@onready var info_overlay : InfoOverlay = ui.info_overlay
@onready var assign_toggle_sprite: Sprite2D = %AssignToggleSprite
@onready var end_day_continue_button: Sprite2D = %endDayContinueButton
@onready var world : World = get_tree().get_first_node_in_group("WORLD")

func _on_assign_toggle_gui_input(event: InputEvent) -> void:
	if !info_overlay : info_overlay = ui.info_overlay
	if ui.world.is_combat_phase : return
	if event.is_action_released("select"):
		info_overlay.assignMode = !info_overlay.assignMode 
		assign_toggle_sprite.frame = 1 if info_overlay.assignMode  else 0
		assign_toggle_sprite.modulate.v = 1.5 if info_overlay.assignMode  else 1.0
		
		var colorMask = get_tree().get_first_node_in_group("COLORMASK")
		colorMask.visible = info_overlay.assignMode 
		
		ui.hand.visible = !info_overlay.assignMode 
		ui.hand.process_mode = Node.PROCESS_MODE_DISABLED if info_overlay.assignMode else Node.PROCESS_MODE_INHERIT
		
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		for b : Building in buildings:
			if Building.ALWAYS_ACTIVE.has(b.type):
				b.toggle.visible = false
				continue
			
			b.worker_alert_sprite.visible = !b.active if !info_overlay.assignMode  else false
			b.toggle.visible = info_overlay.assignMode 
		
			if b.max_workers > 1:
				b.citizen_bar.visible = info_overlay.assignMode
			else:
				b.citizen_bar.visible = false

func _on_endturn_pressed() -> void:
	# hide assign mode
	if !info_overlay : info_overlay = ui.info_overlay
	if info_overlay.assignMode:
		var event : InputEventAction = InputEventAction.new()
		event.action = "select"
		_on_assign_toggle_gui_input(event)
	# hide dispatch
	if ui.dispatch.visible and end_day_continue_button.frame == 1: 
		ui._on_dispatch_end_pressed()
		end_day_continue_button.frame = 0 
		return
	# hide shop
	if ui.shop.visible and end_day_continue_button.frame == 1: 
		ui._on_shop_end_pressed()
		end_day_continue_button.frame = 0 
		return
	
	# check if house is not placed
	%Button.play()
	for card : Card in Global.cardsInHand:
		if card.type == Card.CARDTYPE.HOUSE: 
			%noHouse.show()
			return
	
	# run building functions first
	for b : Building in get_tree().get_nodes_in_group("BUILDING"):
		b.day_ended.emit()
	
	# start night for real
	world.night_started.emit()
	
	
	info_overlay._update_resources()
	info_overlay._on_end_turn()
	
	var units = get_tree().get_nodes_in_group("ALLY")
	for u:Ally in units:
		u.healthchange.emit()
		u.speedchange.emit()
	%noHouse.hide()
	"res://Units/Assets/AllyAcidic/"
	
	ui.tutorial.play_tutorial(Tutorial.TYPE.NIGHT)

func _on_button_mouse_entered(nodePath : NodePath) -> void:
	var sprite : Sprite2D = get_node(nodePath)
	sprite.modulate.v = 1.5

func _on_button_mouse_exited() -> void:
	end_day_continue_button.modulate.v = 1.0
	assign_toggle_sprite.modulate.v = 1.0
