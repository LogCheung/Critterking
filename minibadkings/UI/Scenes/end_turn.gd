extends Control

@onready var ui : UI = get_parent()
@onready var info_overlay : InfoOverlay = ui.info_overlay
@onready var assign_toggle_sprite: Sprite2D = %AssignToggleSprite

func _on_assign_toggle_gui_input(event: InputEvent) -> void:
	if !info_overlay : info_overlay = ui.info_overlay
	if ui.world.is_combat_phase : return
	if event.is_action_released("select"):
		info_overlay.assignMode = !info_overlay.assignMode 
		assign_toggle_sprite.frame = 1 if info_overlay.assignMode  else 0
		assign_toggle_sprite.modulate.v = 1.5 if info_overlay.assignMode  else 1.0
		
		var colorMask = get_tree().get_first_node_in_group("COLORMASK")
		colorMask.visible = info_overlay.assignMode 
		
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		for b : Building in buildings:
			if Building.ALWAYS_ACTIVE.has(b.type):
				b.toggle.visible = false
				continue
			
			b.worker_alert_sprite.visible = !b.active if !info_overlay.assignMode  else false
			b.toggle.visible = info_overlay.assignMode 
			ui.hand.visible = !info_overlay.assignMode 
