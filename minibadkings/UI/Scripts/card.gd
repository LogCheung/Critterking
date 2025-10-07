extends Control
class_name Card

const GROUP = preload("res://Units/Scenes/unit_group.tscn")
const BUILDING = preload("res://TileMap/Scenes/building.tscn")

# Crazed is border for units, Biter is start
# Storage is border for buildings, TRAPS is start
# Nail is border for charms, Heartlocket is start
enum CARDTYPE {
	NONE = 0, BITER = 1,PLATED = 2,SPITTER = 3, #RHINO, EXPLOSIVE, FUNGI, 
	PARALYTIC, RESILIENT, STINGER ,BOMBARDIER, FLYING,CRAZED,
	
	TRAPS ,DESTROY , HOUSE, CARE , FARM , SAPSTORE, NURSERY, STORAGE, 
	HEARTLOCKET, RING, SWORD, FLAG, SODA, ROLLERSKATE, MEDKIT, GLASSES, NAIL,
	INSPIRATION, DECARE, RECON, DEFENSE, RENOVATE, WAR, CONSCRIPTION, MASTERY, INFLUENCE, CONSTRUCTION
}
enum ROLLTYPE {
	GENERAL, UNIT, BUILDINGS, CHARM, BLESSING
}

@export var type : CARDTYPE
@export var rolltype : ROLLTYPE
@export var for_show : bool  = false
@export var level : int = 1
@export var being_charmed : bool
@export var charm : Charm 

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var button: Button = %Selected
@onready var charm_pos: Node2D = %CharmPos


var default_position : Vector2
var default_custom_min : Vector2

var setting_up : bool = true
var choice_picked : bool = false
var refreshing : bool = false

var dispatchSelected : bool = false

var is_under_mouse : bool = false
func _ready() -> void:
	if for_show: scale = Vector2(3,3)

func set_up() -> void:
	match_sprite_type()
	default_position = position
	default_custom_min = custom_minimum_size
	setting_up = false

var selected : bool = false
var tile : Vector2i
func _process(delta: float) -> void:
	if setting_up : return
	handle_drag()
	
func handle_drag() -> void:
	if refreshing : 
		await get_tree().create_timer(.05).timeout
		default_position = position
		refreshing = false
		return
	if for_show: return
	if ui.pausemenu.visible : return
	# dragging and plopping
	if Input.is_action_just_pressed("select") and !selected:
		if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			# check if selecting for dispatch
			if ui.dispatch.visible and ui.dispatchAmt < ui.dispatchLimit and !charm:
				if type > CARDTYPE.CRAZED : return
				ui.dispatchAmt += 1
				dispatchSelected = true
				sprite_2d.material = preload("res://Units/Shaders/cardHighlight.tres")
				return
			elif dispatchSelected:
				ui.dispatchAmt -= 1
				dispatchSelected = false
				sprite_2d.material = null
			else:
				dispatchSelected = false
				sprite_2d.material = null
			set_to_default()
			selected = true
	if Input.is_action_pressed("select") and selected:
		sprite_2d.scale = Vector2(.4,.4)
		global_position = get_global_mouse_position()
		highlight_tiles()
	elif Input.is_action_just_released("select") and selected:
		if ui.dispatch.visible : 
			set_to_default() 
			return
		plop()
	elif selected:
		is_under_mouse = false
		set_to_default()
	else:
		if is_under_mouse : return
		set_to_default()
	
	if Input.is_action_just_pressed("cancel"):
		set_to_default()
		ui.refresh_positions()

func set_to_default() -> void:
	sprite_2d.scale = Vector2(1.0,1.0)
	sprite_2d.position.y = default_position.y
	if !dispatchSelected : sprite_2d.material = null
	
	z_index = 0
	custom_minimum_size = default_custom_min
	position = default_position
	
	selected = false
	is_under_mouse = false

func highlight_tiles() -> void:
	# preconditions or exceptions
	if type == CARDTYPE.DESTROY : return
	
	# clear hover tiles
	for cell in tileWorld.hover.get_used_cells():
		tileWorld.hover.set_cell(cell,-1)
	
	# filter tiles already placed
	var unit_tiles : Array
	var unit_groups = get_tree().get_first_node_in_group("GROUPSNODE").get_children()
	for group : AllyGroup in unit_groups:
		if !group is AllyGroup : continue
		group.tile = tileWorld.ground.local_to_map(group.global_position)
		unit_tiles.append(Vector2i(group.tile))
	
	# add appropriate tiles
	for cell in tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1):
		if unit_tiles.has(cell) : continue
		tileWorld.hover.set_cell(cell,0,Vector2(0,0),0)
		tileWorld.hover.visible = true
	pass

func plop() -> void:
	tileWorld.handle_navigable_cells()
	tile = world.tile2
	var ploppableTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1)
	var hoverTiles = tileWorld.hover.get_used_cells()
	ploppableTiles = ploppableTiles.filter(func(t):return hoverTiles.has(t))
	var groupNode = get_tree().get_first_node_in_group("GROUPSNODE")
	
	if ploppableTiles.has(tile):
		if type > Unit.TYPE.CRAZED:
			plop_building()
			return
		var group = load("res://Units/Scenes/unit_group.tscn").instantiate()
		group.type = type
		group.charm = charm
		group.upgraded = level > 1
		group.level = level
		group.max_size =12 if level == 3 else 9
		group.global_position = tileWorld.ground.map_to_local(tile)
		await get_tree().create_timer(.2).timeout
		groupNode.add_child(group)
		
		remove_self()
	else:
		if check_if_merge(tile) : remove_self()
		if check_destroy(tile): remove_self()
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
		ui.refresh_positions()
	tileWorld.handle_navigable_cells()

func remove_self() -> void:
	var cards = ui.hand.get_child(0).get_children()
	for c : Card in cards:
		c.refreshing = true
	selected = false
	Global.cardsInHand.remove_at(Global.cardsInHand.find(self))
	queue_free()
	
func plop_building() -> void:
	if type == CARDTYPE.DESTROY : 
		if check_destroy(tile) : remove_self()
		return
	var buildingNode = get_tree().get_first_node_in_group("BUILDINGSNODE")
	var building = BUILDING.instantiate()
	building = match_building_type(building)
	if building == null : return # checking if was invalid spot, then match type would return null
	
	building.global_position = tileWorld.ground.map_to_local(tile)
	buildingNode.add_child(building)
	
	# remove self
	remove_self()

func check_if_blocking(plopTile : Vector2) -> bool:
	# tile is showing tilemap coords
	var buildTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),2)
	var takenTiles = []
	
	for t in buildTiles:
		takenTiles.append(t)
		takenTiles.append(Vector2i(t.x+1,t.y))
		takenTiles.append(Vector2i(t.x-1,t.y))
	if takenTiles.has(Vector2i(plopTile)): return true
	return false

func check_destroy(plopTile : Vector2) -> bool:
	var buildTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),2)
	if type != CARDTYPE.DESTROY : return false
	if !buildTiles.has(Vector2i(plopTile)): return false
	# tile is showing tilemap coords
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	
	# create destruction
	var des = preload("res://TileMap/Scenes/destroy.tscn").instantiate()
	des.global_position = tileWorld.ground.map_to_local(plopTile)
	world.add_child(des)
	for b : Building in buildings:
		if b.tile == Vector2i(plopTile): 
			b.on_destroyed()
			return true
	return false

func check_if_merge(plopTile : Vector2) -> bool:
	if type > Unit.TYPE.CRAZED: return false
	var groups = get_tree().get_nodes_in_group("ALLYGROUP")
	var targetGroup : AllyGroup
	
	# Identify group that is going to be upgraded
	for g : AllyGroup in groups:
		if !g.tile == plopTile : continue
		targetGroup = g
	
	if is_instance_valid(targetGroup) and type==targetGroup.type:
		# cant merge if both have charms
		if targetGroup.charm and charm : return false
		# dont forget to alert them of this
		
		if targetGroup.level + level > 3: return false
		targetGroup.being_upgraded.emit(level)
		
		# apply charm if target doesn't have, else let it retain its own
		if !targetGroup.charm and charm:
			targetGroup.charm = charm
		return true
	
	return false

func randomize_type() -> void:
	if !for_show : return
	if being_charmed : return
	match rolltype:
		ROLLTYPE.GENERAL:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.STORAGE)
		ROLLTYPE.UNIT:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.CRAZED)
		ROLLTYPE.BUILDINGS:
			type = randi_range(CARDTYPE.TRAPS,CARDTYPE.STORAGE)
		ROLLTYPE.CHARM:
			type = randi_range(CARDTYPE.HEARTLOCKET,CARDTYPE.NAIL)#randi_range(CARDTYPE.SWORD,CARDTYPE.FLAG) 
		ROLLTYPE.BLESSING:
			type = randi_range(CARDTYPE.INSPIRATION,CARDTYPE.CONSTRUCTION)
	if type == CARDTYPE.HOUSE : randomize_type()
	
	# check if not same as other card
	var cards = get_tree().get_nodes_in_group("CARD")
	cards = cards.filter(func(c):return c.for_show)
	for card : Card in cards:
		if card == self: continue
		if card.type == type:
			randomize_type()
			return
	match_sprite_type()

func add_card_to_hand() -> void:
	match ui.rolltype:
		ROLLTYPE.GENERAL,ROLLTYPE.UNIT,ROLLTYPE.BUILDINGS:
			var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
			dupe.type = type
			Global.cardsInHand.append(dupe)
			dupe.for_show = false
			ui.hand.get_child(0).add_child(dupe) # container
		ROLLTYPE.CHARM:
			var card : Card = Global.cardsDispatched.front()
			var newCard = preload("res://UI/Scenes/card.tscn").instantiate()
			newCard.type = Global.cardsDispatched.front().type
			newCard.level = card.level
			
			var newCharm = preload("res://Units/Scenes/charm.tscn").instantiate()
			newCharm.type = type - CARDTYPE.HEARTLOCKET
			
			Global.cardsInHand.append(newCard)
			ui.hand.get_child(0).add_child(newCard)
			Global.cardsDispatched.remove_at(Global.cardsDispatched.find(card))
			
			newCard.for_show = false
			newCard.charm_pos.add_child(newCharm)
			newCard.charm = newCharm
		ROLLTYPE.BLESSING:
			var decree : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
			decree.type = type - CARDTYPE.INSPIRATION + 1
			ui.decrees.get_child(0).add_child(decree)

func match_building_type(building : Building) -> Building:
	match type:
		CARDTYPE.TRAPS:
			building.type = Building.TYPE.TRAP
		CARDTYPE.HOUSE:
			building.type = Building.TYPE.HOUSE
			if check_if_blocking(tile):
				sprite_2d.scale = Vector2(1.0,1.0)
				position = default_position
				selected = false
				building = null
		CARDTYPE.CARE:
			building.type = Building.TYPE.CARE
			if check_if_blocking(tile):
				sprite_2d.scale = Vector2(1.0,1.0)
				position = default_position
				selected = false
				building = null
		CARDTYPE.FARM:
			building.type = Building.TYPE.FARM
		CARDTYPE.SAPSTORE:
			building.type = Building.TYPE.SAPSTORE
		CARDTYPE.NURSERY:
			building.type = Building.TYPE.NURSERY
		CARDTYPE.STORAGE:
			building.type = Building.TYPE.STORAGE
	return building

func _on_selected_pressed() -> void:
	if choice_picked : return
	if being_charmed : return
	if for_show:
		choice_picked = true
		ui.anim.play("cardhide")
		add_card_to_hand()
		
	var cards = get_tree().get_nodes_in_group("CARD")
	cards = cards.filter(func(c):return c.for_show)
	for c : Card in cards:
		c.choice_picked = true

func _on_selected_mouse_entered() -> void:
	if for_show : return
	if selected : return
	if refreshing : return
	if setting_up : return
	if ui.pausemenu.visible : return
	sprite_2d.scale = Vector2(1.5,1.5)
	sprite_2d.position.y = default_position.y - (custom_minimum_size.y / 1.5) - 32
	custom_minimum_size.x = default_custom_min.x * 1.5
	is_under_mouse = true
	z_index = 4096
func _on_selected_mouse_exited() -> void:
	if for_show : return
	if selected : return
	if refreshing : return
	if setting_up : return
	if ui.pausemenu.visible : return
	set_to_default()

func match_sprite_type() -> void:
	match type:
		CARDTYPE.BITER:
			sprite_2d.texture = preload("res://UI/Assets/cards/biterCard.png")
		CARDTYPE.PLATED:
			sprite_2d.texture = preload("res://UI/Assets/cards/platedCard.png")
		CARDTYPE.SPITTER:
			sprite_2d.texture = preload("res://UI/Assets/cards/spitterCard.png")
		CARDTYPE.BOMBARDIER:
			sprite_2d.texture = preload("res://UI/Assets/cards/bomberCard.png")
		CARDTYPE.FLYING:
			sprite_2d.texture = preload("res://UI/Assets/cards/flyingCard.png")
		CARDTYPE.CRAZED:
			sprite_2d.texture = preload("res://UI/Assets/cards/crazedCard.png")
		CARDTYPE.TRAPS:
			sprite_2d.texture = preload("res://UI/Assets/cards/trapsCard.png")
		CARDTYPE.HOUSE:
			sprite_2d.texture = preload("res://UI/Assets/cards/houseCard.png")
		CARDTYPE.DESTROY:
			sprite_2d.texture = preload("res://UI/Assets/cards/destroyCard.png")
		CARDTYPE.CARE:
			sprite_2d.texture = preload("res://UI/Assets/cards/careCard.png")
		CARDTYPE.FARM:
			sprite_2d.texture = preload("res://UI/Assets/cards/farmCard.png")
		CARDTYPE.SAPSTORE:
			sprite_2d.texture = preload("res://UI/Assets/cards/sapCard.png")
		CARDTYPE.NURSERY:
			sprite_2d.texture = preload("res://UI/Assets/cards/nurseryCard.png")
		CARDTYPE.STORAGE:
			sprite_2d.texture = preload("res://UI/Assets/cards/storageCard.png")
		CARDTYPE.HEARTLOCKET:
			sprite_2d.texture = preload("res://UI/Assets/cards/locketCard.png")
		CARDTYPE.RING:
			sprite_2d.texture = preload("res://UI/Assets/cards/ringCard.png")
		CARDTYPE.SWORD:
			sprite_2d.texture = preload("res://UI/Assets/cards/swordCard.png")
		CARDTYPE.FLAG:
			sprite_2d.texture = preload("res://UI/Assets/cards/flagCard.png")
		CARDTYPE.SODA:
			sprite_2d.texture = preload("res://UI/Assets/cards/sodaCard.png")
		CARDTYPE.ROLLERSKATE:
			sprite_2d.texture = preload("res://UI/Assets/cards/skateCard.png")
		CARDTYPE.MEDKIT:
			sprite_2d.texture = preload("res://UI/Assets/cards/medkitCard.png")
		CARDTYPE.GLASSES:
			sprite_2d.texture = preload("res://UI/Assets/cards/glassesCard.png")
		CARDTYPE.NAIL:
			sprite_2d.texture = preload("res://UI/Assets/cards/nailsCard.png")
		CARDTYPE.INSPIRATION:
			sprite_2d.texture = preload("res://UI/Assets/cards/inspirationCard.png")
		CARDTYPE.DECARE:
			sprite_2d.texture = preload("res://UI/Assets/cards/decareCard.png")
		CARDTYPE.RECON:
			sprite_2d.texture = preload("res://UI/Assets/cards/reconCard.png")
		CARDTYPE.DEFENSE:
			sprite_2d.texture = preload("res://UI/Assets/cards/defenseCard.png")
		CARDTYPE.RENOVATE:
			sprite_2d.texture = preload("res://UI/Assets/cards/renovateCard.png")
		CARDTYPE.WAR:
			sprite_2d.texture = preload("res://UI/Assets/cards/warCard.png")
		CARDTYPE.CONSCRIPTION:
			sprite_2d.texture = preload("res://UI/Assets/cards/conscriptionCard.png")
		CARDTYPE.MASTERY:
			sprite_2d.texture = preload("res://UI/Assets/cards/masteryCard.png")
		CARDTYPE.INFLUENCE:
			sprite_2d.texture = preload("res://UI/Assets/cards/influenceCard.png")
		CARDTYPE.CONSTRUCTION:
			sprite_2d.texture = preload("res://UI/Assets/cards/constructionCard.png")
		CARDTYPE.PARALYTIC:
			sprite_2d.texture = preload("res://UI/Assets/cards/paralyticCard.png")
		CARDTYPE.RESILIENT:
			sprite_2d.texture = preload("res://UI/Assets/cards/resilientCard.png")
		CARDTYPE.STINGER:
			sprite_2d.texture = preload("res://UI/Assets/cards/stingerCard.png")
	
	%Upgrade1.visible = level == 2
	%Upgrade2.visible = level == 3
