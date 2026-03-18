extends Control
class_name InfoOverlay

@export var assignMode : bool = false

@onready var ui : UI = get_parent()
@onready var assign_toggle_sprite: Sprite2D = %AssignToggleSprite
@onready var culture_trait: Label = %CultureTrait
@onready var commerce_trait: Label = %CommerceTrait
@onready var fame_trait: Label = %FameTrait
@onready var productivity_trait: Label = %ProductivityTrait
@onready var satisfaction_label: Label = %SatisfactionLabel
@onready var money_label: Label = %MoneyLabel
@onready var food_label: Label = %FoodLabel
@onready var citizen_label: Label = %CitizenLabel

func _ready() -> void:
	assign_toggle_sprite.frame = 0
	assign_toggle_sprite.modulate.v = 1
	
	var colorMask = get_tree().get_first_node_in_group("COLORMASK")
	colorMask.visible = false
	
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	for b : Building in buildings:
		b.worker_alert_sprite.visible = !b.active

func _on_assign_toggle_gui_input(event: InputEvent) -> void:
	if ui.world.is_combat_phase : return
	if event.is_action_released("select"):
		assignMode = !assignMode
		assign_toggle_sprite.frame = 1 if assignMode else 0
		assign_toggle_sprite.modulate.v = 1.5 if assignMode else 1.0
		
		var colorMask = get_tree().get_first_node_in_group("COLORMASK")
		colorMask.visible = assignMode
		
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		for b : Building in buildings:
			b.worker_alert_sprite.visible = !b.active if !assignMode else false
			b.toggle.visible = assignMode
			ui.hand.visible = !assignMode

func _update_resources() -> void:
	satisfaction_label.text = str(Global.resource_dict[Global.RESOURCETYPE.SATISFACTION])
	money_label.text = str(Global.resource_dict[Global.RESOURCETYPE.MONEY])
	food_label.text = str(Global.resource_dict[Global.RESOURCETYPE.FOOD])
	citizen_label.text = str(Global.resource_dict[Global.RESOURCETYPE.CITIZEN])
	
func _update_traits() -> void:
	# reset values to ensure no repeats
	for key in Global.trait_dict.keys():
		Global.trait_dict[key] = 0
	Global.trait_dict[Global.TRAITTYPE.CULTURE] = 0
	
	var colonyBuilds = get_tree().get_nodes_in_group("COLONY")
	
	for c : ColonyBuilding in colonyBuilds:
		Global.trait_dict[c.traitType] += c.traitAmt
		
				
	# set text
	culture_trait.text = str(Global.trait_dict[Global.TRAITTYPE.CULTURE])
	commerce_trait.text = str(Global.trait_dict[Global.TRAITTYPE.COMMERCE])
	fame_trait.text = str(Global.trait_dict[Global.TRAITTYPE.FAME])
	productivity_trait.text = str(Global.trait_dict[Global.TRAITTYPE.PRODUCTIVITY])
