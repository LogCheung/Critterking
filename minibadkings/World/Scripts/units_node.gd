extends Node2D
class_name UnitsNode

func create_zombified(pos : Vector2, is_enemy : bool):
	var unit
	if is_enemy: 
		unit = preload("res://Units/Scenes/enemy.tscn").instantiate()
	else: 
		unit = preload("res://Units/Scenes/unit.tscn").instantiate()
	unit.type = Unit.TYPE.ZOMBIFIED
	if unit is Enemy : unit.is_active = true
	unit.level = 1
	unit.global_position = pos
	print(unit.type)
	
	call_deferred("add_child",unit)
	await get_tree().create_timer(.1).timeout
