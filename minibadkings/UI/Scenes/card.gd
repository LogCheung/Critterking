extends Control
class_name Card

const GROUP = preload("res://Units/Scenes/unit_group.tscn")

enum CARDTYPE {
	NONE, BITER,PLATED,SPITTER, TRAPS,DESTROY, HOUSE
}
enum ROLLTYPE {
	GENERAL, UNIT, BUILDING
}

@export var type : CARDTYPE
@export var rolltype : ROLLTYPE
@export var for_show : bool

@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")

var default_position : Vector2

func set_up() -> void:
	match_type()
	default_position = position
	if !for_show: scale = Vector2(.75,.75)
	if !for_show: print(default_position)

var selected : bool = false
var tile : Vector2i
func _process(delta: float) -> void:
	if for_show: return
	if Input.is_action_just_pressed("select") and !selected:
		if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			selected = true
	if Input.is_action_pressed("select") and selected:
		sprite_2d.scale = Vector2(.4,.4)
		global_position = get_global_mouse_position()
	elif Input.is_action_just_released("select") and selected:
		plop()
	elif selected:
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
	
func plop() -> void:
	await world.mouse_clicked
	tile = world.tile2
	var ploppableTiles = tileWorld.ground.get_used_cells_by_id(0,Vector2(0,0),1)
	var groupNode = get_tree().get_first_node_in_group("GROUPSNODE")
	print(tile)
	if ploppableTiles.has(tile):
		if type > 3:
			plop_building()
			return
		var group = GROUP.instantiate()
		group.type = type
		group.global_position = tileWorld.ground.map_to_local(tile)
		await get_tree().create_timer(.2).timeout
		groupNode.add_child(group)
	else:
		sprite_2d.scale = Vector2(1.0,1.0)
		position = default_position
		selected = false
func plop_building() -> void:
	return

func randomize_type() -> void:
	match rolltype:
		ROLLTYPE.GENERAL:
			type = (randi() % CARDTYPE.size() - 1) + 1
	
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

func _on_selected_pressed() -> void:
	if for_show:
		ui.anim.play("cardhide")
		add_card_to_hand()
	pass # Replace with function body.

func add_card_to_hand() -> void:
	var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	dupe.type = type
	Global.cardsInHand.append(dupe)
	dupe.for_show = false
	ui.hand.get_child(0).add_child(dupe) # container
