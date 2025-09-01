extends Control
class_name Card

const GROUP = preload("res://Units/Scenes/unit_group.tscn")
const BUILDING = preload("res://TileMap/Scenes/building.tscn")

enum CARDTYPE {
	NONE = 0, BITER = 1,PLATED = 2,SPITTER = 3,BOMBARDIER = 4, FLYING = 5 ,CRAZED = 6,
	TRAPS ,DESTROY , HOUSE, CARE , FARM , SAPSTORE, NURSERY, STORAGE
}
enum ROLLTYPE {
	GENERAL, UNIT, BUILDING
}

@export var type : CARDTYPE
@export var rolltype : ROLLTYPE
@export var for_show : bool  = false
@export var level : int = 0

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var button: Button = %Selected

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
		await get_tree().create_timer(.3).timeout
		default_position = position
		refreshing = false
		return
	if for_show: return
	
	# dragging and plopping
	if Input.is_action_just_pressed("select") and !selected:
		if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			# check if selecting for dispatch
			if ui.dispatch.visible and ui.dispatchAmt < ui.dispatchLimit:
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

func set_to_default() -> void:
	sprite_2d.scale = Vector2(1.0,1.0)
	sprite_2d.position.y = default_position.y
	if !dispatchSelected : sprite_2d.material = null
	
	z_index = 0
	custom_minimum_size = default_custom_min
	position = default_position
	
	selected = false
	is_under_mouse = false

func plop() -> void:
	print("is type : " + str(type))
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
		var group = GROUP.instantiate()
		group.type = type
		group.upgraded = level > 0
		group.max_size = 12 if level == 2 else 9
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
	tileWorld.handle_navigable_cells()

func remove_self() -> void:
	var cards = ui.hand.get_child(0).get_children()
	for c : Card in cards:
		c.refreshing = true
	selected = false
	Global.cardsInHand.remove_at(Global.cardsInHand.find(self))
	queue_free()
	refresh_positions()
	
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
			b.remove()
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
		targetGroup.being_upgraded.emit()
		return true
	
	return false

func randomize_type() -> void:
	if !for_show : return
	match rolltype:
		ROLLTYPE.GENERAL:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.size()-1)
		ROLLTYPE.UNIT:
			type = randi_range(CARDTYPE.BITER,CARDTYPE.CRAZED)
		ROLLTYPE.BUILDING:
			type = randi_range(CARDTYPE.TRAPS,CARDTYPE.size()-1)
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

func refresh_positions() -> void:
	var cards = ui.hand.get_child(0).get_children()
	for c : Card in cards:
		c.set_up()
	

func add_card_to_hand() -> void:
	var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	dupe.type = type
	Global.cardsInHand.append(dupe)
	dupe.for_show = false
	ui.hand.get_child(0).add_child(dupe) # container

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
	
	%Upgrade1.visible = level == 1
	%Upgrade2.visible = level == 2
	
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
	set_to_default()
