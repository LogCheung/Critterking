extends StaticBody2D
class_name Building

signal destroyed

const HIGHLIGHT = preload("res://Units/Shaders/houseHighlight.tres")

enum TYPE {
	NONE, HOUSE, TRAP, NURSERY, STORAGE, FARM, SAPSTORE, RUINS
}

@export var type : TYPE
@export var occupant : Group 
@export var health : int = 10
@export var max_health : int = 20

@onready var entrance: Node2D = $Entrance
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var bar: TextureProgressBar = $TextureProgressBar
@onready var sprite_2d: Sprite2D = $Sprite2D

var tile : Vector2i
var doorstepTile : Vector2i

func _ready() -> void:
	tile = tileWorld.ground.local_to_map(global_position)
	doorstepTile = tile + Vector2i(1,0)

func _process(delta: float) -> void:
	if health <= 0:
		on_destroyed()
	if health <= 10 and health > 0:
		sprite_2d.modulate.v = .3
	else:
		sprite_2d.modulate.v = 1
	if occupants_inside():
		bar.visible = true
		bar.value += .16666 #if occupant.max_size <= 9 else .12345
		if bar.value >= bar.max_value:
			occupant.global_position = tileWorld.ground.map_to_local(doorstepTile)
			occupant.respawn_units()
			for unit : Ally in occupant.unitsArray:
				unit.healing = false
				unit.visible = true
			occupant = null
	else:
		bar.value = 0
		bar.visible = false
func occupants_inside() -> bool:
	if !occupant : return false
	for unit in occupant.unitsArray:
		if unit.visible == true:
			return false
	return true

func on_destroyed() -> void:
	type = TYPE.RUINS
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
	if buildings.is_empty():
		queue_free()
		# lose screen
	pass
