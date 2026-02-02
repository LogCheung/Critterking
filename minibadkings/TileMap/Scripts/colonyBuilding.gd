extends Building
class_name ColonyBuilding

signal day_ended

static var pantryActive : bool = false
@export var costType : Global.RESOURCETYPE = Global.RESOURCETYPE.NONE
@export var costAmt : int = 0 
@export var workers : Array

@export var scalingTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE
@export var scalingMult : float = 1
@export var chance : float = 100.0
@export var chanceTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE

func _ready() -> void:
	super._ready()
	day_ended.connect(on_day_ended)

func on_day_ended() -> void:
	time += 1
	
	if type == TYPE.HOUSE and pantryActive:
		trigger_building()
		time = 0
	if time >= cooldown:
		trigger_building()
	
func trigger_building() -> void:
	time -= cooldown
	
	# special cases
	# for chance of losing in the casino
	if type == TYPE.CASINO and randi() % 4 == 0 :
		add_resource(resourceType, -resourceAmt)
		return
	# for marketplace proc chance
	if type == TYPE.MARKETPLACE:
		var marketProcChance = 50
		
		var markets = get_tree().get_nodes_in_group("COLONY")
		markets = markets.filter(func(b):return b.type == TYPE.MARKETPLACE)
		marketProcChance += markets.size() * 5
		
		if randi() % 100 >= marketProcChance : return
		
	# chance scaling with traits
	if chance < 100:
		var scaledChance = chance + (5 * Global.trait_dict[chanceTrait])
		if randi() % 100 > scaledChance : return
		
		
	if !add_resource(costType,-costAmt) : # consider cost
		if type == TYPE.PANTRY : pantryActive = false
		return 
	
	add_resource(resourceType,resourceAmt) # add resource
	if type == TYPE.SCHOOL : trigger_school()


func add_resource(rType : Global.RESOURCETYPE,rAmt : int ) -> bool:
	if rType == Global.RESOURCETYPE.NONE : return true
	
	# scaling
	var scaledAmt = 0 
	if scalingTrait != Global.TRAITTYPE.NONE:
		scaledAmt = scalingMult * Global.trait_dict[scalingTrait] 
	
	# add resource
	Global.resource_dict[rType] += int(rAmt + scaledAmt)
	
	# for costs
	if Global.resource_dict[rType] < 0:
		# special cases
		if type == TYPE.CASINO : # for losing in the casino
			Global.resource_dict[rType] = 0
			return false
		
		# refund and return false if insufficient costs met
		Global.resource_dict[rType] += abs(rAmt)
		return false
		
	if type == TYPE.PANTRY : pantryActive = true
	return true

func trigger_school() -> void:
	if !active : 
		traitAmt = 0 
		return
	traitAmt = int(workers.size() * .5)
	ui._update_traits()

func match_type() -> void:
	match type:
		# Satisfaction buildings
		TYPE.TAVERN:
			traitAmt = 1
			traitType = Global.TRAITTYPE.CULTURE
			resourceType = Global.RESOURCETYPE.SATISFACTION
			resourceAmt = 5
			cooldown = 1
			
		TYPE.MONUMENT:
			traitAmt = 1
			traitType = Global.TRAITTYPE.CULTURE
			resourceType = Global.RESOURCETYPE.SATISFACTION
			resourceAmt = 10
			costType = Global.RESOURCETYPE.MONEY
			costAmt = 5
			cooldown = 1
			
		TYPE.CASINO:
			traitAmt = 1
			traitType = Global.TRAITTYPE.COMMERCE
			resourceAmt = 2 
			resourceType = Global.RESOURCETYPE.SATISFACTION
			scalingMult = 2
			scalingTrait = Global.TRAITTYPE.COMMERCE
		TYPE.THEATRE:
			traitAmt = 1
			traitType = Global.TRAITTYPE.CULTURE
			resourceAmt = 2 
			resourceType = Global.RESOURCETYPE.SATISFACTION
			scalingMult = 2
			scalingTrait = Global.TRAITTYPE.CULTURE
		# Money buildings
		TYPE.HALL:
			traitAmt = 1
			traitType = Global.TRAITTYPE.COMMERCE
			resourceType = Global.RESOURCETYPE.MONEY
			resourceAmt = 5
			cooldown = 1
		TYPE.TRADINGPOST:
			traitAmt = 2
			traitType = Global.TRAITTYPE.COMMERCE
			resourceType = Global.RESOURCETYPE.MONEY
			resourceAmt = 0
			scalingMult = 5
			scalingTrait = Global.TRAITTYPE.FAME
			cooldown = 1
		TYPE.MARKETPLACE:
			resourceType = Global.RESOURCETYPE.MONEY
			resourceAmt = 8
			scalingMult = 6
			scalingTrait = Global.TRAITTYPE.COMMERCE
			cooldown = 1
		TYPE.GARDEN:
			traitAmt = 1
			traitType = Global.TRAITTYPE.COMMERCE
			resourceType = Global.RESOURCETYPE.MONEY
			resourceAmt = 3
			scalingMult = 2
			scalingTrait = Global.TRAITTYPE.PRODUCTIVITY
			cooldown = 1
		# Citizen buildings
		TYPE.HOUSE:
			sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
			traitAmt = 1
			traitType = Global.TRAITTYPE.FAME
			cooldown = 2
			resourceAmt = 1
			resourceType = Global.RESOURCETYPE.CITIZEN
			
			await anim.animation_finished
			duplicate_sprite()
		TYPE.CUSTOMS:
			traitAmt = 1
			traitType = Global.TRAITTYPE.FAME
			resourceAmt = 1
			resourceType = Global.RESOURCETYPE.CITIZEN
			chance = 25
			chanceTrait = Global.TRAITTYPE.CULTURE
		TYPE.PANTRY:
			traitAmt = 1
			traitType = Global.TRAITTYPE.FAME
			chance = 25
			chanceTrait = Global.TRAITTYPE.CULTURE
			costType = Global.RESOURCETYPE.FOOD
			costAmt = 1
		TYPE.GUILD:
			traitAmt = 1
			traitType = Global.TRAITTYPE.FAME
			resourceAmt = 1
			resourceType = Global.RESOURCETYPE.CITIZEN
			chance = 25
			chanceTrait = Global.TRAITTYPE.FAME
		# Food buildings
		TYPE.FIELD:
			traitAmt = 1
			traitType = Global.TRAITTYPE.PRODUCTIVITY
			resourceType = Global.RESOURCETYPE.FOOD
			resourceAmt = 4
			cooldown = 1
		TYPE.SCHOOL:
			traitType = Global.TRAITTYPE.PRODUCTIVITY
			costType = Global.RESOURCETYPE.MONEY
			costAmt = 4
			pass
		TYPE.POND:
			pass
		TYPE.BAKERY:
			resourceType = Global.RESOURCETYPE.FOOD
			resourceAmt = 2
			cooldown = 1
			
			scalingMult = 2
			scalingTrait = Global.TRAITTYPE.PRODUCTIVITY
			pass


func _on_toggle_pressed() -> void:
	print(toggle.button_pressed)
