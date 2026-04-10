extends Control
class_name InfoOverlay

@export var assignMode : bool = false

@onready var ui : UI = get_parent()
@onready var assign_toggle_sprite: Sprite2D = %AssignToggleSprite
@onready var culture_trait: OverlayCounter = %CultureTrait
@onready var commerce_trait: OverlayCounter = %CommerceTrait
@onready var fame_trait: OverlayCounter = %FameTrait
@onready var productivity_trait: OverlayCounter = %ProductivityTrait
@onready var satisfaction_label: OverlayCounter = %SatisfactionLabel
@onready var money_label: OverlayCounter = %MoneyLabel
@onready var food_label: OverlayCounter = %FoodLabel
@onready var citizen_label: OverlayCounter = %CitizenLabel
@onready var house_label: OverlayCounter = %HouseLabel
@onready var party_current: OverlayCounter = %PartyCurrent
@onready var trait_container: HBoxContainer = $TraitContainer
@onready var resource_container: HBoxContainer = $ResourceContainer
@onready var tutorial_button_sprite: Sprite2D = %TutorialButtonSprite

func _ready() -> void:
	trait_container.visible = false
	resource_container.visible = false
	
	assign_toggle_sprite.frame = 0
	assign_toggle_sprite.modulate.v = 1
	
	var colorMask = get_tree().get_first_node_in_group("COLORMASK")
	colorMask.visible = false
	
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	for b : Building in buildings:
		b.worker_alert_sprite.visible = !b.active

func load_overlay() -> void:
	await get_tree().create_timer(2).timeout
	show_containers()
	
	_update_resources(false)
	_update_traits(false)
func show_containers() -> void:
	trait_container.visible = true
	resource_container.visible = true

func _update_resources(showAnim : bool = true) -> void:
	satisfaction_label.set_value(Global.resource_dict[Global.RESOURCETYPE.SATISFACTION],showAnim)
	money_label.set_value(Global.resource_dict[Global.RESOURCETYPE.MONEY],showAnim)
	food_label.set_value(Global.resource_dict[Global.RESOURCETYPE.FOOD],showAnim)
	citizen_label.set_value(Global.resource_dict[Global.RESOURCETYPE.CITIZEN],showAnim)
	
	
	
func _update_traits(showAnim : bool = true) -> void:
	# reset values to ensure no repeats
	for key in Global.trait_dict.keys():
		Global.trait_dict[key] = 0
	Global.trait_dict[Global.TRAITTYPE.CULTURE] = 0
	
	var colonyBuilds = get_tree().get_nodes_in_group("COLONY")
	
	for c : ColonyBuilding in colonyBuilds:
		Global.trait_dict[c.traitType] += c.traitAmt
		
				
	# set text
	culture_trait.set_value(Global.trait_dict[Global.TRAITTYPE.CULTURE],showAnim)
	commerce_trait.set_value(Global.trait_dict[Global.TRAITTYPE.COMMERCE],showAnim)
	fame_trait.set_value(Global.trait_dict[Global.TRAITTYPE.FAME],showAnim)
	productivity_trait.set_value(Global.trait_dict[Global.TRAITTYPE.PRODUCTIVITY],showAnim)
	
	# house counter text
	var houseCount = get_tree().get_nodes_in_group("BUILDING")
	houseCount = houseCount.filter(func(e):return e.type == Building.TYPE.HOUSE)
	houseCount = houseCount.size()
	house_label.label.text = str(houseCount)

func handle_party_limit() -> void:
	var houseCount = get_tree().get_nodes_in_group("BUILDING")
	var campCount = houseCount.filter(func(e):return e.type == Building.TYPE.CAMPFIRE and e.active)
	houseCount = houseCount.filter(func(e):return e.type == Building.TYPE.HOUSE)
	houseCount = houseCount.size()
	campCount = campCount.size()
	
	Global.partyCount = get_tree().get_nodes_in_group("ALLYGROUP").size()
	if ui.currentAscn >= 3: 
		Global.partyLimit = 2 + (1 * houseCount) + (1 * campCount)
	else: 
		Global.partyLimit = 2 + (2 * houseCount) + (1 * campCount)
	
	party_current.label.text = str(Global.partyCount) +  " / " + str(Global.partyLimit)
	
	if Global.partyCount >= Global.partyLimit:
		ui.no_space.show()
	else:
		ui.no_space.hide()
		
	pass
