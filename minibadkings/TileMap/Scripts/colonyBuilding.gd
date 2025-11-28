extends Building
class_name ColonyBuilding

signal day_ended

@export var costType : Global.RESOURCETYPE = Global.RESOURCETYPE.NONE
@export var costAmt : int = 0 
@export var workers : Array

@export var scalingTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE
@export var scalingMult : float = 1

func _ready() -> void:
	super._ready()
	day_ended.connect(on_day_ended)

func on_day_ended() -> void:
	time += 1
	if time >= cooldown:
		time -= cooldown
		
		# special cases
		if type == TYPE.CASINO and randi() % 4 == 0 :
			# for chance of losing in the casino
			add_resource(resourceType, -resourceAmt)
			return
			
		if !add_resource(costType,-costAmt) : return # consider cost
		
		add_resource(resourceType,resourceAmt) # add resource
		
		


func add_resource(rType : Global.RESOURCETYPE,rAmt : int ) -> bool:
	if rType == Global.RESOURCETYPE.NONE : return true
	
	var scalingValue = 1
	if scalingTrait != Global.TRAITTYPE.NONE:
		scalingValue = scalingMult * Global.trait_dict[scalingTrait]
	
	Global.resource_dict[rType] += int(rAmt * scalingValue)
	
	# for costs
	if Global.resource_dict[rType] < 0:
		# special cases
		if type == TYPE.CASINO : # for losing in the casino
			Global.resource_dict[rType] = 0
			return false
		
		# refund and return false if insufficient costs met
		Global.resource_dict[rType] += abs(rAmt)
		return false
	return true
	
func match_type() -> void:
	match type:
		TYPE.HOUSE:
			sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
			traitAmt = 1
			traitType = Global.TRAITTYPE.FAME
			cooldown = 2
			resourceAmt = 1
			resourceType = Global.RESOURCETYPE.CITIZEN
			
			await anim.animation_finished
			duplicate_sprite()
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
