extends Control
class_name InfoOverlay

var projections : Dictionary = {
	Global.RESOURCETYPE.NONE : 0,
	Global.RESOURCETYPE.SATISFACTION : 0,
	Global.RESOURCETYPE.MONEY : 0,
	Global.RESOURCETYPE.FOOD : 0,
	Global.RESOURCETYPE.CITIZEN : 0,
}
var minus_projections : Dictionary = {
	Global.RESOURCETYPE.NONE : 0,
	Global.RESOURCETYPE.SATISFACTION : 0,
	Global.RESOURCETYPE.MONEY : 0,
	Global.RESOURCETYPE.FOOD : 0,
	Global.RESOURCETYPE.CITIZEN : 0,
}

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
@onready var trait_container: HBoxContainer = %TraitContainer
@onready var resource_container: HBoxContainer = %ResourceContainer
@onready var tutorial_button_sprite: Sprite2D = %TutorialButtonSprite
@onready var overlay_texture: TextureRect = %OverlayTexture
@onready var colony_alerts: HBoxContainer = %ColonyAlerts

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
	handle_party_limit()
func show_containers() -> void:
	trait_container.visible = true
	resource_container.visible = true

func _update_resources(showAnim : bool = true) -> void:
	satisfaction_label.set_value(Global.resource_dict[Global.RESOURCETYPE.SATISFACTION],showAnim)
	money_label.set_value(Global.resource_dict[Global.RESOURCETYPE.MONEY],showAnim)
	food_label.set_value(Global.resource_dict[Global.RESOURCETYPE.FOOD],showAnim)
	citizen_label.set_value(Global.resource_dict[Global.RESOURCETYPE.CITIZEN],showAnim)
	
	# handle worker limit for citizens
	handle_worker_limit()
	
	
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
	
	handle_projections()

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
		
	handle_projections()
		
func handle_worker_limit() -> void:
	var citizenCount = Global.resource_dict[Global.RESOURCETYPE.CITIZEN]
	var workerCount = Global.resource_dict[Global.RESOURCETYPE.WORKER]
	
	citizen_label.label.text = str(workerCount) +  " / " + str(citizenCount)
	pass
		
func handle_projections() -> void:
	# reset
	for key in projections:
		projections[key] = 0
		minus_projections[key] = 0
	# positives / production
	var builds = get_tree().get_nodes_in_group("COLONY")
	for b : ColonyBuilding in builds:
		if b.resourceType == Global.RESOURCETYPE.NONE and b.type != Building.TYPE.SCHOOL : continue
		if b.type == Building.TYPE.MARKETPLACE : continue
		if b.time + 1 != b.cooldown: continue
		if !b.active : continue
		
		var projAmt : int = b.resourceAmt
		if b.scalingTrait != Global.TRAITTYPE.NONE:
			projAmt += b.scalingMult * Global.trait_dict[b.scalingTrait] 
		
		projections[b.resourceType] += projAmt
		
		# also for minus projections
		if b.costType != Global.RESOURCETYPE.NONE:
			var cost = b.costAmt
			if b.type == Building.TYPE.SCHOOL: cost *= b.workers
			
			minus_projections[b.costType] -= cost
			
	
	citizen_label.set_projection_value(projections[Global.RESOURCETYPE.CITIZEN],true)
	money_label.set_projection_value(projections[Global.RESOURCETYPE.MONEY],true)
	satisfaction_label.set_projection_value(projections[Global.RESOURCETYPE.SATISFACTION],true)
	food_label.set_projection_value(projections[Global.RESOURCETYPE.FOOD],true)
	
	
	# negatives / consumption or cost
	var houseCount = get_tree().get_nodes_in_group("BUILDING")
	houseCount = houseCount.filter(func(b:Building):return b.type == Building.TYPE.HOUSE)
	houseCount = houseCount.size()
	
	var citizens = Global.resource_dict[Global.RESOURCETYPE.CITIZEN]
	minus_projections[Global.RESOURCETYPE.SATISFACTION] -= citizens + 3 * (houseCount - 1)
	
	# satisfaction drain from ruins
	var ruins = get_tree().get_nodes_in_group("BUILDING")
	ruins = ruins.filter(func(b : Building):return b.type == Building.TYPE.RUINS).size()
	minus_projections[Global.RESOURCETYPE.SATISFACTION] -= ruins
	
	var foodConsump = citizens + Global.partyCount * 2

	minus_projections[Global.RESOURCETYPE.FOOD] -= foodConsump
	
	var foodDebt = Global.resource_dict[Global.RESOURCETYPE.FOOD] + projections[Global.RESOURCETYPE.FOOD]  - foodConsump
	if foodDebt < 0:
		minus_projections[Global.RESOURCETYPE.SATISFACTION] -= abs(foodDebt)
	
	unpaid_parties = 0
	for g : AllyGroup in get_tree().get_nodes_in_group("ALLYGROUP"):
		if get_projected_resource_amt(Global.RESOURCETYPE.MONEY) - g.wage < 0:
			unpaid_parties += 1
		minus_projections[Global.RESOURCETYPE.MONEY] -= g.wage
	citizen_label.set_projection_value(minus_projections[Global.RESOURCETYPE.CITIZEN],false)
	money_label.set_projection_value(minus_projections[Global.RESOURCETYPE.MONEY],false)
	satisfaction_label.set_projection_value(minus_projections[Global.RESOURCETYPE.SATISFACTION],false)
	food_label.set_projection_value(minus_projections[Global.RESOURCETYPE.FOOD],false)
	
	handle_starving_parties()
	handle_colony_alerts()

var unpaid_parties = 0
var starving_parties = 0
func handle_starving_parties() -> void:
	# apply starving effect
	starving_parties = 0
	var fedParties = Global.resource_dict[Global.RESOURCETYPE.FOOD] / 2
	starving_parties = Global.partyCount - fedParties
	
	if starving_parties > 0:
		var parties = get_tree().get_nodes_in_group("ALLYGROUP")
		for p : AllyGroup in parties:
			p.starving = true
		pass
	pass

func handle_colony_alerts() -> void:
	var alertArray : Array = []
	
	# rebels
	var rebelCount : int = 0
	var projSatis = get_projected_resource_amt(Global.RESOURCETYPE.SATISFACTION)
	# find rebel count
	if projSatis < 25:
		rebelCount = 1 * ((Global.resource_dict[Global.RESOURCETYPE.CITIZEN] / 6) + 1)
		if projSatis <= 0:
			rebelCount = ui.world.enemy_parties
	for i in range(rebelCount):
		alertArray.append(ColonyAlert.TYPE.REBELS)
	
	# miltia
	if projSatis >= 75:
		alertArray.append(ColonyAlert.TYPE.MILITIA)
	
	# food
	var projFood = get_projected_resource_amt(Global.RESOURCETYPE.FOOD)
	if projFood < 0:
		alertArray.append(ColonyAlert.TYPE.STARVING)
	
	# wages
	for i in range(unpaid_parties):
		alertArray.append(ColonyAlert.TYPE.WAGES)
	
	for key in ColonyAlert.alertCountDict:
		ColonyAlert.alertCountDict[key] = alertArray.count(key)
	create_alerts()

func create_alerts() -> void:
	# clear alerts
	var currentAlerts = get_tree().get_nodes_in_group("ALERT")
	for a : ColonyAlert in currentAlerts:
		a.queue_free()
	
	# make new alerts
	for key in ColonyAlert.alertCountDict:
		if ColonyAlert.alertCountDict[key] > 0:
			var alert : ColonyAlert = load("res://UI/Scenes/alert.tscn").instantiate()
			alert.type = key
			colony_alerts.add_child(alert)
	pass

func get_projected_resource_amt(rType : Global.RESOURCETYPE) -> int:
	var amt = Global.resource_dict[rType]
	amt += projections[rType]
	amt += minus_projections[rType]
	return amt

func _on_end_turn() -> void:
	# add tween anim to make it look more polished
	await get_tree().create_timer(Pop.duration).timeout
	overlay_texture.visible = !ui.world.is_combat_phase
