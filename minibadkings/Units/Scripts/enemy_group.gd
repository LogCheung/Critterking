extends Group
class_name EnemyGroup

signal formation_finished
signal at_border

const ENEMY : PackedScene = preload("res://Units/Scenes/enemy.tscn")

var approaching : bool = true
var isActive : bool = false

func _ready() -> void:
	super._ready()
	type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	while Global.nights <= 3 and (type == Unit.TYPE.RANGED or type == Unit.TYPE.BOMBER):
		type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	tile = tileWorld.ground.local_to_map(global_position)
	create_formation(ENEMY)
	at_border.connect(activate_units)

func _process(delta: float) -> void:
	if !approaching : return
	for unit in unitsArray:
		if !unit : continue
		if !unit.in_formation:
			return
	at_border.emit()

func highlight_units(highlight : bool) -> void:
	for unit in unitsArray:
		unit.HIGHLIGHT 
	pass

func activate_units() -> void:
	isActive = true
	for unit in unitsArray:
		if !unit: continue
		unit.become_active()

func _on_timer_timeout() -> void:
	if !approaching and !isActive :
		activate_units()
	pass 
