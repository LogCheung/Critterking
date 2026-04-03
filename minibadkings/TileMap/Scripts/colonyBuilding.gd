extends Building
class_name ColonyBuilding

signal day_ended

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
	
	# check pantry
	pantryActive = check_pantry_active()
	
	if type == TYPE.HOUSE and pantryActive:
		trigger_building()
		time = 0
	if time >= cooldown and active:
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
	print(rType)
	print(rAmt)
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
	ui.info_overlay._update_traits()

func check_pantry_active() -> bool:
	var pantries = get_tree().get_nodes_in_group("COLONY")
	pantries = pantries.filter(func(b: ColonyBuilding ):return b.type == TYPE.PANTRY)
	for p  : ColonyBuilding in pantries:
		print(p.active)
		if p.active: return true
	return false

func match_type() -> void:
	match type:
		# Satisfaction buildings
		TYPE.TAVERN:
			#set_building_properties(1,Global.TRAITTYPE.CULTURE,Global.RESOURCETYPE.SATISFACTION,
			#5,1,0,Global.RESOURCETYPE.NONE)
			pass
		TYPE.MONUMENT:
			pass
			
			set_active(true)
		TYPE.CASINO:
			pass
			
		TYPE.THEATRE:
			pass
		# Money buildings
		TYPE.HALL:
			pass
		TYPE.TRADINGPOST:
			pass
			
		TYPE.MARKETPLACE:
			pass
		TYPE.GARDEN:
			pass
		# Citizen buildings
		TYPE.HOUSE:
			sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
			
			tileWorld.restricted_tiles.append(doorstepTile)
			await anim.animation_finished
			duplicate_sprite()
			return
		TYPE.CUSTOMS:
			pass
			
		TYPE.PANTRY:
			pass
		TYPE.GUILD:
			pass
			
		# Food buildings
		TYPE.FIELD:
			pass

		TYPE.SCHOOL:
			pass
		TYPE.POND:
			pass
		TYPE.BAKERY:
			pass
		TYPE.RUINS:
			%fire.hide()
			sprite_2d.texture = HOUSEA
			sprite_2d.frame = 1
			sprite_2d.offset = Vector2(0,-16)
			
	
	set_building_properties(type)
	var path = "res://TileMap/Assets/"+str(TYPE.keys()[type]).to_lower()+"Build.png"
	sprite_2d.texture = load(path)

#func set_building_properties(tAmt : int, tType : Global.TRAITTYPE, 
#rType : Global.RESOURCETYPE, rAmt : int, cd : int, cAmt : int, 
#cType : Global.RESOURCETYPE, chNum : float = 100.0,
#chTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE,
#sTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE, 
#sMult : int = 1, ) -> void:
	#traitAmt = tAmt
	#traitType = tType
	#resourceType = rType
	#resourceAmt = rAmt
	#cooldown = cd
	#costAmt = cAmt
	#costType = cType
	#chance = chNum
	#chanceTrait = chTrait
	#scalingTrait = sTrait
	#scalingMult = sMult

func set_building_properties(bType : Building.TYPE):
	traitAmt = Stats.coloBuilds[bType]["traitAmt"]
	traitType = Stats.coloBuilds[bType]["traitType"]
	resourceType = Stats.coloBuilds[bType]["resourceType"]
	resourceAmt = Stats.coloBuilds[bType]["resourceAmt"]
	cooldown = Stats.coloBuilds[bType]["cooldown"]
	costAmt = Stats.coloBuilds[bType]["costAmt"]
	costType = Stats.coloBuilds[bType]["costType"]
	chance = Stats.coloBuilds[bType]["chance"]
	chanceTrait = Stats.coloBuilds[bType]["chanceTrait"]
	scalingTrait = Stats.coloBuilds[bType]["scalingTrait"]
	scalingMult = Stats.coloBuilds[bType]["scalingMult"]
