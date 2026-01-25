extends Control
class_name Card

const GROUP = preload("res://Units/Scenes/unit_group.tscn")
const BUILDING = preload("res://TileMap/Scenes/building.tscn")
const COLONY = preload("res://TileMap/Scenes/colonyBuilding.tscn")
const DEFAULT_CARDS : Array = [
# units
CARDTYPE.BITER, CARDTYPE.PLATED, CARDTYPE.SPITTER,
CARDTYPE.ACIDIC, CARDTYPE.FLYING, CARDTYPE.CRAZED, 
# buildings
CARDTYPE.TRAPS, CARDTYPE.HOUSE, CARDTYPE.CARE, CARDTYPE.FARM, CARDTYPE.SAPSTORE,
CARDTYPE.NURSERY, CARDTYPE.STORAGE, CARDTYPE.DESTROY,
# colony buildings
#CARDTYPE.TAVERN,  CARDTYPE.MONUMENT, CARDTYPE.CASINO, 
#CARDTYPE.THEATRE, CARDTYPE.HALL, CARDTYPE.TRADINGPOST, 
#CARDTYPE.MARKETPLACE, CARDTYPE.GARDEN,CARDTYPE.CUSTOMS, 
#CARDTYPE.PANTRY, CARDTYPE.GUILD, CARDTYPE.FIELD, 
#CARDTYPE.SCHOOL, CARDTYPE.POND, CARDTYPE.BAKERY,
# charms
CARDTYPE.HEARTLOCKET, CARDTYPE.RING, CARDTYPE.SWORD, CARDTYPE.FLAG, CARDTYPE.SODA, 
CARDTYPE.ROLLERSKATE, CARDTYPE.MEDKIT, CARDTYPE.GLASSES, CARDTYPE.NAIL, 
# decrees
CARDTYPE.INSPIRATION, CARDTYPE.DECARE, CARDTYPE.RECON, CARDTYPE.DEFENSE, CARDTYPE.RENOVATE,
CARDTYPE.WAR, CARDTYPE.CONSCRIPTION, CARDTYPE.MASTERY,  #CARDTYPE.INFLUENCE, 
CARDTYPE.CONSTRUCTION,

]

# Crazed is border for units, Biter is start
# Destroy is border for buildings, TRAPS is start
# Nail is border for charms, Heartlocket is start
# construction is border for decrees, Inspiration is start
# 
enum CARDTYPE {
	NONE = 0, BITER = 1,PLATED = 2,SPITTER = 3, TRAPJAW, EXPLOSIVE, FUNGI, 
	PARALYTIC, RESILIENT, STINGER , ACIDIC, #BOMBER, 
	FLYING,CRAZED,
	
	TRAPS , HOUSE, CARE , FARM , SAPSTORE, FORT, CAMPFIRE,# CLIFF, TUNNEL
	NURSERY, STORAGE, 
	
	#TAVERN, MONUMENT, CASINO, 
	#THEATRE, HALL, TRADINGPOST, 
	#MARKETPLACE, GARDEN,CUSTOMS, 
	#PANTRY, GUILD, FIELD, 
	#SCHOOL, POND, BAKERY,
	# general
	PONDER, DESTROY,
	
	HEARTLOCKET, RING, SWORD, FLAG, 
	SODA, ROLLERSKATE, MEDKIT, GLASSES, BERRIES, PILLS, DOLLHOUSE, EDRINK, NAIL, 
	
	INSPIRATION, DECARE, RECON, DEFENSE, RENOVATE, WAR, CONSCRIPTION, MASTERY,
	TERROR, SABOTAGE, FORTITUDE, #INFLUENCE, 
	CONSTRUCTION,
	
}
enum ROLLTYPE {
	GENERAL, UNIT, BUILDINGS, CHARM, BLESSING, SHOP
}

@export var type : CARDTYPE
@export var rolltype : ROLLTYPE
@export var for_show : bool  = false
@export var shop_card : bool = false
@export var level : int = 1
@export var being_charmed : bool
@export var charm : Charm 
@export var price : float

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
var purchaseSelected : bool = false

var is_under_mouse : bool = false
func _ready() -> void:
	if for_show: scale = Vector2(3,3)
	if shop_card : set_up()

func set_up() -> void:
	match_sprite_type()
	default_position = position
	default_custom_min = custom_minimum_size
	setting_up = false

var selected : bool = false
var tile : Vector2i
func _process(delta: float) -> void:
	#top_level = selected
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
		sprite_2d.scale = Vector2(.6,.6)
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
	if shop_card: 
		sprite_2d.material = null
		purchaseSelected = false
		return # only need to revert less things for shopcards
	
	sprite_2d.position.y = default_position.y
	if !dispatchSelected : sprite_2d.material = null
	
	z_index = 0
	custom_minimum_size = default_custom_min
	position = default_position
	
	selected = false
	is_under_mouse = false
	
	# remove highlight
	if tileWorld.hover.get_used_cells().has(tile):
		tileWorld.hover.set_cell(tile,0,Vector2.ZERO)

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
		if tileWorld.buffed_tiles.has(cell):
			tileWorld.hover.set_cell(cell,0,Vector2(0,1),0)
		tileWorld.hover.visible = true
	
	# highlight tile hovered over with card
	var hoverTile = world.tileWorld.ground.local_to_map(world.get_global_mouse_position())
	if tileWorld.hover.get_used_cells().has(hoverTile):
		var atlas = tileWorld.hover.get_cell_atlas_coords(hoverTile)
		tileWorld.hover.set_cell(hoverTile,0,atlas,1)

func plop() -> void:
	tileWorld.handle_navigable_cells()
	tile = world.tile2
	var ploppableTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1)
	var hoverTiles = tileWorld.hover.get_used_cells()
	ploppableTiles = ploppableTiles.filter(func(t):return hoverTiles.has(t))
	var groupNode = get_tree().get_first_node_in_group("GROUPSNODE")
	
	if ploppableTiles.has(tile):
		if check_general() : 
			remove_self()
			return
		if type > Unit.TYPE.CRAZED:
			plop_building()
			return
		if Global.partyCount >= Global.partyLimit and type <= CARDTYPE.CRAZED:
			# precondition : is unit card and party limit is reached
			# set to default
			sprite_2d.scale = Vector2(1.0,1.0)
			position = default_position
			selected = false
			ui.refresh_positions()
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
		group.set_owner(get_tree().get_current_scene())
		
		remove_self()
	else:
		if check_if_merge(tile) : remove_self()
		if check_destroy(tile): remove_self()
		if check_general() : remove_self()
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
		ui.refresh_positions()
	tileWorld.handle_navigable_cells()

func remove_self() -> void:
	var cards = ui.hand_container.get_children()
	for c : Card in cards:
		c.refreshing = true
	selected = false
	Global.cardsInHand.remove_at(Global.cardsInHand.find(self))
	ui.card_placed.emit()
	queue_free()
	
func plop_building() -> void:
	if type == CARDTYPE.DESTROY : 
		if check_destroy(tile) : remove_self()
		return
	
	var buildingNode = get_tree().get_first_node_in_group("BUILDINGSNODE")
	var building = BUILDING.instantiate()# if type < CARDTYPE.TAVERN else COLONY.instantiate()
	if type == CARDTYPE.HOUSE : building = COLONY.instantiate()
	
	building = match_building_type(building)
	if building == null : return # checking if was invalid spot, then match type would return null
	
	building.global_position = tileWorld.ground.map_to_local(tile)
	buildingNode.add_child(building)
	building.set_owner(get_tree().get_current_scene())
	
	ui._update_traits()
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

func check_general() -> bool:
	if type == CARDTYPE.PONDER:
		for decree : Decree in get_tree().get_nodes_in_group("DECREE"):
			decree.time -= 1
			decree.update_cooldown()
	return type == CARDTYPE.PONDER

func check_destroy(plopTile : Vector2) -> bool:
	tileWorld.find_obstacle_tiles()
	var can_destroy : bool = false
	var buildTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),2)
	buildTiles.append_array(tileWorld.obstacle_tiles)
	if type != CARDTYPE.DESTROY : return can_destroy
	if !buildTiles.has(Vector2i(plopTile)): return can_destroy
	
	var pos = tileWorld.ground.map_to_local(plopTile)
	# create destruction for organic map obstacles
	if buildTiles.has(Vector2i(plopTile)):
		create_destroy(pos)
		tileWorld.obstacles.set_cell(plopTile,-1)
		tileWorld.draw_build_area()
		can_destroy = true
	
	# tile is showing tilemap coords
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	# create destruction for buildings
	create_destroy(pos)
	for b : Building in buildings:
		if b.tile == Vector2i(plopTile): 
			b.remove()
			can_destroy = true
	return can_destroy

func create_destroy(pos : Vector2) -> void:
	var des = preload("res://TileMap/Scenes/destroy.tscn").instantiate()
	des.global_position = pos
	world.add_child(des)
	des.set_owner(get_tree().get_current_scene())
	pass

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
			type = randi_range(CARDTYPE.BITER,CARDTYPE.DESTROY)
		ROLLTYPE.UNIT:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.CRAZED)
		ROLLTYPE.BUILDINGS:
			type = randi_range(CARDTYPE.TRAPS,CARDTYPE.DESTROY)
		ROLLTYPE.CHARM:
			type = randi_range(CARDTYPE.HEARTLOCKET,CARDTYPE.NAIL)#randi_range(CARDTYPE.SWORD,CARDTYPE.FLAG) 
		ROLLTYPE.BLESSING:
			type = randi_range(CARDTYPE.INSPIRATION,CARDTYPE.CONSTRUCTION)
		ROLLTYPE.SHOP:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.CRAZED) #randi_range(CARDTYPE.TAVERN,CARDTYPE.BAKERY)
	if type == CARDTYPE.HOUSE : randomize_type()
	if type == CARDTYPE.FLAG : randomize_type() # nuke flag
	if !Global.unlockedCards.has(type) : randomize_type()
	
	# check if not same as other card when drawing
	var cards = get_tree().get_nodes_in_group("CARD")
	cards = cards.filter(func(c):return c.for_show and !c.shop_card)
	for card : Card in cards:
		if card == self: continue
		if card.type == type:
			randomize_type()
			return

	# check if not same as other card when shopping
	if shop_card:
		var shopCards = get_tree().get_nodes_in_group("CARD")
		shopCards = shopCards.filter(func(c):return c.shop_card)
		for scard : Card in shopCards:
			if scard == self: continue
			if scard.type == type:
				randomize_type()
				return
	match_sprite_type()

func add_card_to_hand() -> void:
	if shop_card:
		var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = type
		Global.cardsInHand.append(dupe)
		dupe.for_show = false
		dupe.shop_card = false
		ui.hand_container.add_child(dupe) # container
		dupe.set_owner(get_tree().get_current_scene())
		return
	match ui.rolltype:
		ROLLTYPE.GENERAL,ROLLTYPE.UNIT,ROLLTYPE.BUILDINGS:
			var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
			dupe.type = type
			Global.cardsInHand.append(dupe)
			dupe.for_show = false
			ui.hand_container.add_child(dupe) # container
			dupe.set_owner(get_tree().get_current_scene())
		ROLLTYPE.CHARM:
			var card : Card = Global.cardsDispatched.front()
			var newCard = preload("res://UI/Scenes/card.tscn").instantiate()
			newCard.type = Global.cardsDispatched.front().type
			newCard.level = card.level
			
			var newCharm = preload("res://Units/Scenes/charm.tscn").instantiate()
			newCharm.type = type - CARDTYPE.HEARTLOCKET
			
			Global.cardsInHand.append(newCard)
			ui.hand_container.add_child(newCard)
			newCard.set_owner(get_tree().get_current_scene())
			Global.cardsDispatched.remove_at(Global.cardsDispatched.find(card))
			
			newCard.for_show = false
			newCard.charm_pos.add_child(newCharm)
			newCharm.set_owner(get_tree().get_current_scene())
			newCard.charm = newCharm
		ROLLTYPE.BLESSING:
			var decree : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
			decree.type = type - CARDTYPE.INSPIRATION + 1
			ui.decrees.get_child(0).add_child(decree)
			decree.set_owner(get_tree().get_current_scene())
			Global.decreesEquipped.append(decree)
	

func match_building_type(building : Building) -> Building:
	building.type = type - CARDTYPE.TRAPS + 1
	if building.type == Building.TYPE.CARE or building.type == Building.TYPE.HOUSE:
		if check_if_blocking(tile):
			sprite_2d.scale = Vector2(1.0,1.0)
			position = default_position
			selected = false
			building = null
	return building

func _on_selected_mouse_entered() -> void:
	if for_show and !shop_card: return
	if selected : return
	if refreshing : return
	if setting_up : return
	if ui.pausemenu.visible : return
	
	if shop_card:
		sprite_2d.scale = Vector2(1.2,1.2)
		return
		
	# enlarge when hovered
	sprite_2d.scale = Vector2(1.5,1.5)
	sprite_2d.position.y = default_position.y - (custom_minimum_size.y / 1.5)
	custom_minimum_size.x = default_custom_min.x * 1.5
	is_under_mouse = true
	z_index = 4096
func _on_selected_mouse_exited() -> void:
	if for_show and !shop_card: return
	if selected : return
	if refreshing : return
	if setting_up : return
	if ui.pausemenu.visible : return
	set_to_default()

func match_sprite_type() -> void:
	if type == CARDTYPE.NONE : return
	#if type >= CARDTYPE.TAVERN : return
	var path = "res://UI/Assets/cards/"+str(CARDTYPE.keys()[type]).to_lower()+"Card.png"
	sprite_2d.texture = load(path)
	
	%Upgrade1.visible = level == 2
	%Upgrade2.visible = level == 3


func _on_selected_gui_input(e: InputEvent) -> void:
	if choice_picked : return
	if being_charmed : return
	if !e.is_action_released("select") : return # if not clicking bye bye
	
	# for buying cards
	if shop_card:
		_on_purchase_card_confirm()
		return
	
	# for selecting cards
	_on_draw_card_to_hand()

func _on_purchase_card_confirm() -> void:
	if price > Global.resource_dict[Global.RESOURCETYPE.MONEY]: return
	if !purchaseSelected:
		var cards = get_tree().get_nodes_in_group("CARD")
		cards = cards.filter(func(c):return c.shop_card)
		for c : Card in cards:
			c.purchaseSelected = false
			c.sprite_2d.material = null
		
		purchaseSelected = true
		sprite_2d.material = preload("res://Units/Shaders/cardHighlight.tres")
		
		return
	
	if purchaseSelected:
		Global.resource_dict[Global.RESOURCETYPE.MONEY] -= price
		add_card_to_hand()
		
		# make invisible
		var slot = get_parent()
		if slot is CardPurchaseSlot: 
			slot.card.visible = false
			slot.price_label.visible = false
func _on_draw_card_to_hand() -> void:
	if for_show:
		choice_picked = true
		ui.anim.play("cardhide")
		add_card_to_hand()
		
	var cards = get_tree().get_nodes_in_group("CARD")
	cards = cards.filter(func(c):return c.for_show and !c.shop_card)
	for c : Card in cards:
		c.choice_picked = true
