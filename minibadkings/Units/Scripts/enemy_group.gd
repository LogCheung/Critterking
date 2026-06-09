extends Group
class_name EnemyGroup

signal formation_finished
signal at_border

const ENEMY : PackedScene = preload("res://Units/Scenes/enemy.tscn")
const RANGEDCLASS = [Unit.TYPE.RANGED,Unit.TYPE.BOMBER,Unit.TYPE.ACIDIC,Unit.TYPE.FUNGI]

static var groupsAtBorder : int = 0
@export var behaviorType : Enemy.BEHAVIOR

var approaching : bool = true
var isActive : bool = false

var start_pos : Vector2i
var end_pos : Vector2i
var path_points : Array
var navPath : Array


func _ready() -> void:
	super._ready()
	type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	while type == Unit.TYPE.BOMBER:
		type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	
	while Global.nights <= 3 and RANGEDCLASS.has(type):
		type = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	tile = tileWorld.ground.local_to_map(global_position)
	start_pos = tile
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

func direct_units_to_attack() -> void:
	# create path
	var aStar = tileWorld.aStar
	var position_id = start_pos
	var target_id = end_pos
	path_points = aStar.get_id_path(position_id,target_id,true)
	
	# add navigation only to tiles needed to get to point
	# to reduce lag from huge nav mesh
	for cell in path_points:
		if tileWorld.ground.get_used_cells().has(cell): continue
		tileWorld.ground.set_cell(cell,0,Vector2(0,0),5)
		navPath.append(cell)
	
	for unit : Enemy in unitsArray:
		unit.path_points = path_points

func activate_units() -> void:
	isActive = true
	for unit in unitsArray:
		if !unit: continue
		unit.become_active()
	
	# remove nav cells that were created
	for cell in navPath:
		tileWorld.ground.set_cell(cell,-1)

func _on_timer_timeout() -> void:
	if !approaching and !isActive :
		activate_units()
	pass 
