extends Group
class_name EnemyGroup

signal formation_finished

const ENEMY : PackedScene = preload("res://Units/Scenes/enemy.tscn")

func _ready() -> void:
	super._ready()
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(ENEMY)
	await get_tree().create_timer(.1).timeout
	formation_finished.emit()

func _process(delta: float) -> void:
	for unit in unitsArray:
		if !unit.in_formation:
			return
	for unit : Enemy in unitsArray:
		unit.become_active()

func activate_units() -> void:
	for unit : Enemy in unitsArray:
		unit.become_active()
