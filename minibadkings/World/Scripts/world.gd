extends Node2D

@export var is_combat_phase : bool = true
@export var enemy_strength : int = 20

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var enemy_perimeters: Node = $EnemyPerimeters

var outerFollow : PathFollow2D
var innerFollow : PathFollow2D

func _ready() -> void:
	create_enemy_perimeter(10 + Global.expansions, true)
	create_enemy_perimeter(9 + Global.expansions, false)

func clear_perimeters() -> void:
	# clear children
	outerFollow = null
	innerFollow = null
	for path in enemy_perimeters.get_children():
		path.queue_free()

func create_enemy_perimeter(dist : int, outer : bool) -> void:
	# Battlefield is 10x10, 
	# radius is 5 tiles from center, another 5 for enemy distance
	var enemy_spawn = Path2D.new()
	var follow = PathFollow2D.new()
	var centerPos = tileWorld.center.global_position
	var tileSize : Vector2i=  tileWorld.ground.tile_set.tile_size
	
	# Left and Right points
	var leftPoint = centerPos - Vector2(tileSize.x * dist,0)
	var rightPoint = centerPos + Vector2(tileSize.x * dist,0)
	
	# Up and Down points
	var upPoint = centerPos - Vector2(0,tileSize.y * dist)
	var downPoint = centerPos + Vector2(0,tileSize.y * dist)
	
	# add points to perimeter
	enemy_spawn.z_index = 100
	var curve = Curve2D.new()
	curve.add_point(leftPoint)
	curve.add_point(upPoint)
	curve.add_point(rightPoint)
	curve.add_point(downPoint)
	curve.add_point(leftPoint)
	
	enemy_perimeters.add_child(enemy_spawn)
	enemy_spawn.curve = curve
	enemy_spawn.add_child(follow)
	if outer:
		outerFollow = follow
	else:
		innerFollow = follow

func spawn_enemy() -> void:
	pass
