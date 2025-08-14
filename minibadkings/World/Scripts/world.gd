extends Node2D

const ENEMYGROUP = preload("res://Units/Scenes/enemy_group.tscn")

@export var is_combat_phase : bool = true
@export var enemy_strength : int = 20

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var enemy_perimeters: Node = $EnemyPerimeters
@onready var groupNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")

var outerFollow : PathFollow2D
var innerFollow : PathFollow2D

func _ready() -> void:
	create_enemy_perimeter(10 + Global.expansions, true)
	create_enemy_perimeter(9 + Global.expansions, false)
	spawn_enemy()

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
	# random positon along perimeter of player base
	var rand = randf()
	var follow = innerFollow if randi() % 2 == 0 else outerFollow
	follow.progress_ratio = rand
	# create new enemy group scene and add to world
	var enemGroup = ENEMYGROUP.instantiate()
	enemGroup.global_position = follow.global_position
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	enemyGroupNode.add_child(enemGroup)
	# let units approach player borders before activation
	await enemGroup.formation_finished
	await get_tree().create_timer(1).timeout
	var targetTiles = tileWorld.outskirt_tiles
	targetTiles = targetTiles.map(func(t):return tileWorld.ground.map_to_local(t))
	# find closest target tile
	var closest = targetTiles.front()
	var groupPos = follow.global_position
	for tile in targetTiles:
		if groupPos.distance_to(tile) < groupPos.distance_to(closest):
			closest = tile
	enemGroup.global_position = closest 
	# set groupPos to target and the units within the group will follow
	
func _on_spawn_timer_timeout() -> void:
	pass # Replace with function body.
