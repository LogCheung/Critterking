extends Node2D

const ENEMYGROUP = preload("res://Units/Scenes/enemy_group.tscn")

signal night_started
signal enemy_group_eliminated
signal night_ended

@export var is_combat_phase : bool = true
@export var enemy_parties : int = 4

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var enemy_perimeters: Node = %EnemyPerimeters
@onready var groupNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")
@onready var ui: UI = %UI

var outerFollow : PathFollow2D
var innerFollow : PathFollow2D

var spawned_parties : int = 0

func _ready() -> void:
	Engine.time_scale = 6
	night_started.connect(on_night_started)
	night_ended.connect(on_night_ended)
	enemy_group_eliminated.connect(on_enemy_group_eliminated)
	
	create_enemy_perimeter(12 + Global.expansions, true)
	create_enemy_perimeter(11 + Global.expansions, false)
	on_night_started()
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
	enemGroup.size = randi_range(3,6)
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	enemyGroupNode.add_child(enemGroup)
	# let units approach player borders before activation
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

func on_night_started() -> void:
	%SpawnTimer.start()

func on_enemy_group_eliminated() -> void:
	print("ok")
	await get_tree().create_timer(.05).timeout
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	if enemyGroupNode.get_children().is_empty():
		print("ok2")
		is_combat_phase = false
		night_ended.emit()
		
func on_night_ended() -> void:
	print("alright")
	%Game.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui.cards.visible = true
	pass

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	spawned_parties += 1
	if spawned_parties == enemy_parties:
		%SpawnTimer.stop()
	
