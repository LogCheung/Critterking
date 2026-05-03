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
	
	call_deferred("add_child",unit)
	await get_tree().create_timer(.1).timeout

func spawn_citizen(workplace : Building) -> void:
	# find house
	var houses = get_tree().get_nodes_in_group("COLONY")
	houses = houses.filter(func(e:Building): return e.type == Building.TYPE.HOUSE)
	
	var randInd = randi_range(0,houses.size()-1)
	# spawn and send citizen to destination
	var citizen : Citizen = load("res://Units/Scenes/citizen.tscn").instantiate()
	citizen.workplace = workplace
	citizen.home = houses[randInd]
	citizen.global_position = citizen.home.entrance.global_position
	citizen.set_collision_layer_value(1,false)
	add_child(citizen)
	
	workplace.citizenWorker = citizen
	pass
