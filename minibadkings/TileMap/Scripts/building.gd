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
	NONE, HOUSE, TRAP, NURSERY, STORAGE, FARM, SAPSTORE, RUINS, CARE
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
@onready var ui : UI = get_tree().get_first_node_in_group("UI")

var tile : Vector2i
var doorstepTile : Vector2i

func _ready() -> void:
	match_type()
	tile = tileWorld.ground.local_to_map(global_position)
	tileWorld.ground.set_cell(tile,0,Vector2(0,0),2)
	doorstepTile = tile + Vector2i(1,0)
	%Build.play()
	anim.play("build")

func _process(delta: float) -> void:
	if health <= 0:
		on_destroyed()
	if health <= 10 and health > 0:
		sprite_2d.modulate.v = .3
	else:
		sprite_2d.modulate.v = 1
	if occupants_inside():
		%Timer.start()
		bar.visible = true
	else:
		%Timer.stop()
		bar.value = 0
		bar.visible = false
func occupants_inside() -> bool:
	if !occupant : return false
	if type != TYPE.HOUSE : return false
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
	if type == TYPE.RUINS : return
	# Change appearance and play destroy
	%Break.play()
	anim.play("destroy")
	type = TYPE.RUINS
	match_type()
	
	# alert enemies
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	for enemy : Enemy in enemies:
		enemy.house_destroyed.emit()
	
	# check if final house destroyed and if player lost
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
	if buildings.is_empty():
		ui.game_over.emit()
		# lose screen
		
	# kill unit inside if group is healing
	if occupants_inside():
		occupant.terminate()
	
func remove() -> void:
	type = TYPE.RUINS
	if type == TYPE.HOUSE:
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
		if buildings.is_empty():
			ui.game_over.emit()
	
	tileWorld.ground.set_cell(tile,0,Vector2(0,0),1)
	queue_free()
	tileWorld.handle_navigable_cells()
	

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if !type == TYPE.TRAP : return
	if area.owner is Unit:
		var enemy : Unit = area.owner
		enemy.health -= 1
		enemy.hurt.play()
		if enemy.health <= 0:
			var enemyGroup = enemy.group.unitsArray
			if enemyGroup.find(enemy) != -1 : enemyGroup.remove_at(enemyGroup.find(enemy))
			enemy.group.unit_died.emit()
			enemy.death.play()
			enemy.queue_free()


func _on_timer_timeout() -> void:
	bar.value += .16666 #if occupant.max_size <= 9 else .12345
	if bar.value >= bar.max_value:
		occupant.global_position = tileWorld.ground.map_to_local(doorstepTile)
		occupant.respawn_units()
		for unit : Ally in occupant.unitsArray:
			unit.healing = false
			unit.visible = true
			occupant = null
		%Timer.stop()
