extends StaticBody2D
class_name Building

signal destroyed

const HIGHLIGHT = preload("res://Units/Shaders/houseHighlight.tres")
const HOUSEA = preload("res://TileMap/Assets/houseA.png")
const HOUSEB = preload("res://TileMap/Assets/houseB.png")
const TRAPA = preload("res://TileMap/Assets/trapA.png")
const TRAPB = preload("res://TileMap/Assets/trapB.png")
const RUIN = preload("res://TileMap/Assets/ruinBreak.png")

enum TYPE {
	NONE, HOUSE, TRAP, NURSERY, STORAGE, FARM, SAPSTORE, RUINS
}

@export var type : TYPE
@export var occupant : Group 
@export var health : int = 20
@export var max_health : int = 20

@onready var entrance: Node2D = $Entrance
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var bar: TextureProgressBar = $TextureProgressBar
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var tile : Vector2i
var doorstepTile : Vector2i

func _ready() -> void:
	match_type()
	tile = tileWorld.ground.local_to_map(global_position)
	doorstepTile = tile + Vector2i(1,0)
	anim.play("build")

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

func match_type() -> void:
	match type:
		TYPE.HOUSE:
			sprite_2d.texture = HOUSEA if randi() % 2 == 0 else HOUSEB
		TYPE.TRAP:
			sprite_2d.texture = TRAPA if randi() % 2 == 0 else TRAPB
			sprite_2d.offset = Vector2.ZERO
			z_index = 0

func on_destroyed() -> void:
	type = TYPE.RUINS
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
	if buildings.is_empty():
		queue_free()
		# lose screen

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.owner is Unit:
		var enemy : Unit = area.owner
		enemy.health -= 1
		if enemy.health <= 0:
			var enemyGroup = enemy.group.unitsArray
			if enemyGroup.find(enemy) != -1 : enemyGroup.remove_at(enemyGroup.find(enemy))
			enemy.group.unit_died.emit()
			enemy.queue_free()
