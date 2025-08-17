extends Control
class_name Card

const GROUP = preload("res://Units/Scenes/unit_group.tscn")
const BUILDING = preload("res://TileMap/Scenes/building.tscn")

enum CARDTYPE {
	NONE = 0, BITER = 1,PLATED = 2,SPITTER = 3, TRAPS = 4,DESTROY = 5, HOUSE = 6, CARE = 7, FARM = 8, SAPSTORE = 9
}
enum ROLLTYPE {
	GENERAL, UNIT, BUILDING
}

@export var type : CARDTYPE
@export var rolltype : ROLLTYPE
@export var for_show : bool  = false

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var button: Button = $Selected

var default_position : Vector2
var setting_up : bool = true
var choice_picked : bool = false

func set_up() -> void:
	match_type()
	default_position = position
	setting_up = false

var selected : bool = false
var tile : Vector2i
func _process(delta: float) -> void:
	if setting_up : return
	if for_show: return
	scale = Vector2(.75,.75)
	if Input.is_action_just_pressed("select") and !selected:
		if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			selected = true
			print("in card: " + str(type))
	if Input.is_action_pressed("select") and selected:
		sprite_2d.scale = Vector2(.4,.4)
		global_position = get_global_mouse_position()
	elif Input.is_action_just_released("select") and selected:
		plop()
	elif selected:
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
	else:
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
	if Input.is_action_just_pressed("cancel"):
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
func plop() -> void:
	tileWorld.handle_navigable_cells()
	tile = world.tile2
	var ploppableTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1)
	var hoverTiles = tileWorld.hover.get_used_cells()
	ploppableTiles = ploppableTiles.filter(func(t):return hoverTiles.has(t))
	var groupNode = get_tree().get_first_node_in_group("GROUPSNODE")
	
	if ploppableTiles.has(tile):
		if type > 3:
			plop_building()
			return
		var group = GROUP.instantiate()
		group.type = type
		print("in card: " + str(type))
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
	match type:
		CARDTYPE.TRAPS:
			building.type = Building.TYPE.TRAP
		CARDTYPE.HOUSE:
			building.type = Building.TYPE.HOUSE
			if check_if_blocking(tile):
				print("ok")
				sprite_2d.scale = Vector2(1.0,1.0)
				position = default_position
				selected = false
				return
		CARDTYPE.CARE:
			building.type = Building.TYPE.CARE
			if check_if_blocking(tile):
				print("notok")
				sprite_2d.scale = Vector2(1.0,1.0)
				position = default_position
				selected = false
				return
		CARDTYPE.FARM:
			building.type = Building.TYPE.FARM
		CARDTYPE.SAPSTORE:
			building.type = Building.TYPE.SAPSTORE
			
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
			b.remove()
			return true
	return false

func check_if_merge(plopTile : Vector2) -> bool:
	if type > 3: return false
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
	match rolltype:
		ROLLTYPE.GENERAL:
			type = randi_range(1,CARDTYPE.size()-1)
	if type == CARDTYPE.HOUSE : randomize_type()
	
	# check if not same as other card
	var cards = get_tree().get_nodes_in_group("CARD")
	cards = cards.filter(func(c):return c.for_show)
	for card : Card in cards:
		if card == self: continue
		if card.type == type:
			randomize_type()
			return
	match_type()

func match_type() -> void:
	match type:
		CARDTYPE.BITER:
			sprite_2d.texture = preload("res://UI/Assets/cards/biter.png")
		CARDTYPE.PLATED:
			sprite_2d.texture = preload("res://UI/Assets/cards/plated.png")
		CARDTYPE.SPITTER:
			sprite_2d.texture = preload("res://UI/Assets/cards/spitter.png")
		CARDTYPE.TRAPS:
			sprite_2d.texture = preload("res://UI/Assets/cards/traps.png")
		CARDTYPE.HOUSE:
			sprite_2d.texture = preload("res://UI/Assets/cards/houseCard.png")
		CARDTYPE.DESTROY:
			sprite_2d.texture = preload("res://UI/Assets/cards/destroy.png")
		CARDTYPE.CARE:
			sprite_2d.texture = preload("res://UI/Assets/cards/careCard.png")
		CARDTYPE.FARM:
			sprite_2d.texture = preload("res://UI/Assets/cards/farmCard.png")
		CARDTYPE.SAPSTORE:
			sprite_2d.texture = preload("res://UI/Assets/cards/sapCard.png")

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
func refresh_positions() -> void:
	await get_tree().create_timer(1).timeout
	print("ok")
	var cards = ui.hand.get_child(0).get_children()
	var newCards = cards.duplicate()
	for c : Card in cards:
		c.queue_free()
	for c : Card in newCards:
		ui.hand.get_child(0).add_child(c)
		c.set_up()

func add_card_to_hand() -> void:
	var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	dupe.type = type
	Global.cardsInHand.append(dupe)
	dupe.for_show = false
	ui.hand.get_child(0).add_child(dupe) # container
