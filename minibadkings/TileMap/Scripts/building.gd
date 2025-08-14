extends StaticBody2D
class_name Building

const HIGHLIGHT = preload("res://Units/Shaders/houseHighlight.tres")

enum TYPE {
	NONE, HOUSE, TRAP, NURSERY, STORAGE, FARM, SAPSTORE
}

@export var type : TYPE
@export var occupant : Group 

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
