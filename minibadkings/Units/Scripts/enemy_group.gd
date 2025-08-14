@tool
extends Group
class_name EnemyGroup

const ENEMY : PackedScene = preload("res://Units/Scenes/enemy.tscn")

func _ready() -> void:
	super._ready()
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(ENEMY)
