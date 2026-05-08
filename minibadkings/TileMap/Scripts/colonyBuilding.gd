extends Building
class_name ColonyBuilding

static var pondBuffTiles : Array 
@export var costType : Global.RESOURCETYPE = Global.RESOURCETYPE.NONE
@export var costAmt : int = 0 

@export var scalingTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE
@export var scalingMult : float = 1
@export var chance : float = 100.0
@export var chanceTrait : Global.TRAITTYPE = Global.TRAITTYPE.NONE

func _ready() -> void:
	super._ready()

func on_day_started() -> void:
	super.on_day_started()
	if cooldown == 1: time = 0

func on_day_ended() -> void:
	super.on_day_ended()
	time += 1
	
	# check pantry
	pantryActive = check_pantry_active()
	
	if type == TYPE.HOUSE and pantryActive:
		trigger_building()
		time = 0
	if time >= cooldown and active:
		trigger_building()
	
	
func trigger_building() -> void:
	time = 0
	
	# special cases
	# for fields buffed by ponds
	if type == TYPE.FIELD:
		# mult is number of times tile is buffed
		var bonus = pondBuffTiles.count(tile) * Stats.pondBuffAmt
		resourceAmt = Stats.coloBuilds[type]["resourceAmt"] + bonus
	
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
		#if type == TYPE.PANTRY : pantryActive = false
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
		
	return true

func trigger_school() -> void:
	if !active : 
		traitAmt = 0 
	else:
		traitAmt = int(workers * 1)
	ui.info_overlay._update_traits()
	
func trigger_pond(pondActive : bool) -> void:
	var affectedTiles : Array = [
		Vector2i(tile.x,tile.y - 1),
		Vector2i(tile.x,tile.y + 1),
		Vector2i(tile.x + 1,tile.y),
		Vector2i(tile.x - 1,tile.y),
	]
	
	pondBuffTiles.append_array(affectedTiles)
	
	# everything below is useless because im stupid
	# i want a train
	if false:
		# confirm that all tiles are in the array
		for t in affectedTiles:
			if !pondBuffTiles.has(t): return
		# once confirmed, remove affected tiles 
		# we do this confirmation to not 
		# accidentally remove overlapping tiles from other ponds
		for t in affectedTiles:
			pondBuffTiles.remove_at(pondBuffTiles.find(t))
	
func check_pantry_active() -> bool:
	var pantries = get_tree().get_nodes_in_group("COLONY")
	pantries = pantries.filter(func(b: ColonyBuilding ):return b.type == TYPE.PANTRY)
	for p  : ColonyBuilding in pantries:
		if p.active: return true
	return false

func match_type() -> void:
	match type:
		# Satisfaction buildings
		TYPE.TAVERN:
			pass
		TYPE.MONUMENT:
			pass
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
			#sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
			var texture = CanvasTexture.new()
			texture.diffuse_texture  = HOUSEA
			texture.normal_texture = load("res://TileMap/Assets/houseAnorm.png")
			sprite_2d.texture = texture
			
			set_building_properties(type)
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
			max_workers = 3
			%max.text = str(max_workers)
		TYPE.POND:
			trigger_pond(true)
		TYPE.BAKERY:
			pass
		TYPE.RUINS:
			%fire.hide()
			sprite_2d.frame = 1
			sprite_2d.offset = Vector2(0,-16)
			set_building_properties(type)
			return
			
	
	set_building_properties(type)
	var path = "res://TileMap/Assets/"+str(TYPE.keys()[type]).to_lower()+"Build.png"
	var texture = CanvasTexture.new()
	texture.diffuse_texture  = load(path)
	texture.normal_texture = load("res://TileMap/Assets/houseAnorm.png")
	sprite_2d.texture = texture
	#sprite_2d.texture = load(path)
	
	await anim.animation_finished
	duplicate_sprite()

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
	
	citizen_bar.max_value = max_workers

func set_active(condition : bool) -> void:
	super.set_active(condition)
	
	if ALWAYS_ACTIVE.has(type) : return
	
	if type == TYPE.SCHOOL: trigger_school()

func _on_toggle_toggled(toggled_on: bool) -> void:
	var availWorkers = Global.resource_dict[Global.RESOURCETYPE.CITIZEN] - Global.resource_dict[Global.RESOURCETYPE.WORKER]
	if max_workers > 1:
		if workers >= max_workers:
			workers = 0
		else:
			workers += 1 if availWorkers > 0 else -1
			if workers < 0: workers = 0 # make sure it doesnt go negative
		
		set_active(workers > 0)
		%current.text = str(workers)
		citizen_bar.value = workers
		
		calculate_active_workers()
		return
	
	super._on_toggle_toggled(toggled_on)
