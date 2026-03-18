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

func match_type() -> void:
	match type:
		# Satisfaction buildings
		TYPE.TAVERN:
			set_building_properties(1,Global.TRAITTYPE.CULTURE,Global.RESOURCETYPE.SATISFACTION,
			5,1,0,Global.RESOURCETYPE.NONE)
		TYPE.MONUMENT:
			set_building_properties(1,Global.TRAITTYPE.CULTURE,Global.RESOURCETYPE.SATISFACTION,
			10,1,5,Global.RESOURCETYPE.MONEY)
		TYPE.CASINO:
			set_building_properties(1,Global.TRAITTYPE.COMMERCE,Global.RESOURCETYPE.SATISFACTION,
			2,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.COMMERCE,
			2)
			
		TYPE.THEATRE:
			set_building_properties(1,Global.TRAITTYPE.CULTURE,Global.RESOURCETYPE.SATISFACTION,
			2,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.CULTURE,
			2)
		# Money buildings
		TYPE.HALL:
			set_building_properties(1,Global.TRAITTYPE.COMMERCE,Global.RESOURCETYPE.MONEY,
			5,1,0,Global.RESOURCETYPE.NONE)
		TYPE.TRADINGPOST:
			set_building_properties(2,Global.TRAITTYPE.COMMERCE,Global.RESOURCETYPE.MONEY,
			0,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.FAME,
			5)
			
		TYPE.MARKETPLACE:
			set_building_properties(0,Global.TRAITTYPE.NONE,Global.RESOURCETYPE.MONEY,
			8,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.COMMERCE,
			6)
		TYPE.GARDEN:
			set_building_properties(1,Global.TRAITTYPE.COMMERCE,Global.RESOURCETYPE.MONEY,
			3,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.PRODUCTIVITY,
			2)
		# Citizen buildings
		TYPE.HOUSE:
			sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
			set_building_properties(1,Global.TRAITTYPE.FAME,Global.RESOURCETYPE.CITIZEN,1,
			2,0,Global.RESOURCETYPE.NONE)
			
			tileWorld.restricted_tiles.append(doorstepTile)
			await anim.animation_finished
			duplicate_sprite()
			return
		TYPE.CUSTOMS:
			set_building_properties(1,Global.TRAITTYPE.FAME,Global.RESOURCETYPE.CITIZEN,
			1,1,0,Global.RESOURCETYPE.NONE,25.0,Global.TRAITTYPE.CULTURE)
			
		TYPE.PANTRY:
			set_building_properties(1,Global.TRAITTYPE.FAME,Global.RESOURCETYPE.NONE,
			0,1,1,Global.RESOURCETYPE.FOOD,25.0,Global.TRAITTYPE.CULTURE)
		TYPE.GUILD:
			set_building_properties(1,Global.TRAITTYPE.FAME,Global.RESOURCETYPE.CITIZEN,
			1,1,0,Global.RESOURCETYPE.NONE,25.0,Global.TRAITTYPE.FAME)
			
		# Food buildings
		TYPE.FIELD:
			set_building_properties(1,Global.TRAITTYPE.PRODUCTIVITY,Global.RESOURCETYPE.FOOD,
			4,1,0,Global.RESOURCETYPE.NONE)

		TYPE.SCHOOL:
			set_building_properties(1,Global.TRAITTYPE.PRODUCTIVITY,Global.RESOURCETYPE.NONE,
			0,1,4,Global.RESOURCETYPE.MONEY)
			
		TYPE.POND:
			pass
		TYPE.BAKERY:
			set_building_properties(0,Global.TRAITTYPE.PRODUCTIVITY,Global.RESOURCETYPE.FOOD,
			2,1,0,Global.RESOURCETYPE.NONE,100.0,Global.TRAITTYPE.NONE,Global.TRAITTYPE.PRODUCTIVITY,
			2)
		TYPE.RUINS:
			%fire.hide()
			sprite_2d.texture = HOUSEA
			sprite_2d.frame = 1
			sprite_2d.offset = Vector2(0,-16)
			
			set_building_properties(0,Global.TRAITTYPE.NONE,Global.RESOURCETYPE.NONE,0,
			1,0,Global.RESOURCETYPE.NONE)

	var path = "res://TileMap/Assets/"+str(TYPE.keys()[type]).to_lower()+"Build.png"
	sprite_2d.texture = load(path)

func set_building_properties(tAmt : int, tType : Global.TRAITTYPE, 
rType : Global.RESOURCETYPE, rAmt : int, cd : int, cAmt : int, 
cType : Global.RESOURCETYPE, chNum : float = 100.0,
chTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE,
sTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE, 
sMult : int = 1, ) -> void:
	traitAmt = tAmt
	traitType = tType
	resourceType = rType
	resourceAmt = rAmt
	cooldown = cd
	costAmt = cAmt
	costType = cType
	chance = chNum
	chanceTrait = chTrait
	scalingTrait = sTrait
	scalingMult = sMult
