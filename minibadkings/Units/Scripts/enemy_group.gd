extends Group
class_name EnemyGroup

signal formation_finished
signal at_border

const ENEMY : PackedScene = preload("res://Units/Scenes/enemy.tscn")

var approaching : bool = true

func _ready() -> void:
	super._ready()
	type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(ENEMY)
	at_border.connect(activate_units)

func _process(delta: float) -> void:
	if !approaching : return
	for unit in unitsArray:
		if !unit.in_formation:
			return
	at_border.emit()

func activate_units() -> void:
	for unit : Enemy in unitsArray:
		unit.become_active()
