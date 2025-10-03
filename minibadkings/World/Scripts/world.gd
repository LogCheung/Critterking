extends Node2D
class_name World

const ENEMYGROUP = preload("res://Units/Scenes/enemy_group.tscn")

signal night_started
signal enemy_group_eliminated
signal night_ended

signal mouse_clicked

@export var is_combat_phase : bool = false
@export var enemy_parties : int = 3
@export var upgraded_parties : int = 0

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var enemy_perimeters: Node = %EnemyPerimeters
@onready var groupNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")
@onready var ui: UI = %UI

var outerFollow : PathFollow2D
var innerFollow : PathFollow2D

var spawned_parties : int = 0
var upgrades_given : int = 0
var upgrade_nums : Array = []

var dispatchDay : bool = false

var night_is_expansion: bool = false
func _ready() -> void:
	night_started.connect(on_night_started)
	night_ended.connect(on_night_ended)
	enemy_group_eliminated.connect(on_enemy_group_eliminated)
	
	Engine.time_scale = 1

func new_game() -> void:
	await get_tree().create_timer(.125).timeout
	%SpawnTimer.stop()
	%SpawnTimer.wait_time = 10
	enemy_parties = 3
	upgraded_parties = 0
	dispatchDay = false
	tileWorld.activeDecree = Decree.TYPE.NONE
	Global.nights = 0
	Global.expansions = 0
	Global.cardsInHand.clear()
	Global.cardsDispatched.clear()	
	ui.rollArray.clear()
	tileWorld.draw_build_area()
	clear_world()
	
	ui.cards.show()
	create_enemy_perimeter(12 + Global.expansions, true)
	create_enemy_perimeter(11 + Global.expansions, false)
	
	# add house card
	ui.rollArray.append(Card.ROLLTYPE.UNIT)
	ui.rollArray.append(Card.ROLLTYPE.UNIT)
	
	for i in range(1):
		add_house_card()
	#for i in range(4):
		#var hCard : Card = preload("res://UI/Scenes/card.tscn").instantiate()
		#hCard.type = Card.CARDTYPE.BOMBARDIER
		#ui.hand.get_child(0).add_child(hCard)
	#for i in range(2):
		#var hCard : Card = preload("res://UI/Scenes/card.tscn").instantiate()
		#hCard.type = Card.CARDTYPE.NURSERY
		#ui.hand.get_child(0).add_child(hCard)
func add_house_card() -> void:
	var hCard : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	hCard.type = Card.CARDTYPE.HOUSE
	ui.hand.get_child(0).add_child(hCard)
func clear_perimeters() -> void:
	# clear children
	outerFollow = null
	innerFollow = null
	for path in enemy_perimeters.get_children():
		path.queue_free()

func clear_world() -> void:
	# groups
	for group : Group in groupNode.get_children():
		group.terminate()
	# enemies
	var enemGroups = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	var units = get_tree().get_first_node_in_group("UNITSNODE")
	for u in units.get_children():
		u.queue_free()
	for g in enemGroups.get_children():
		g.queue_free()
	# buildings
	for b in get_tree().get_nodes_in_group("BUILDING"):
		b.remove()
	# cards
	var cards = get_tree().get_nodes_in_group("CARD")
	for c : Card in cards:
		if c.for_show : continue
		c.queue_free()

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
	if spawned_parties >= enemy_parties:
		return
	# random positon along perimeter of player base
	var rand = randf()
	var follow = innerFollow if randi() % 2 == 0 else outerFollow
	follow.progress_ratio = rand
	# create new enemy group scene and add to world
	var enemGroup = ENEMYGROUP.instantiate()
	enemGroup.global_position = follow.global_position
	enemGroup.size = randi_range(3,6)
	if upgrade_nums.has(spawned_parties):
		enemGroup.upgraded = true
	
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
	spawned_parties += 1
	

func on_night_started() -> void:
	print(enemy_parties)
	ui.hand.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui.decrees.process_mode = Node.PROCESS_MODE_PAUSABLE
	if night_is_expansion:
		%SpawnTimer.wait_time -= 1.5
		enemy_parties += 4
		upgraded_parties += 2
	
	# start game and hide menus
	tileWorld.handle_navigable_cells()
	is_combat_phase = true
	spawned_parties = 0
	spawn_enemy()
	%Game.process_mode = Node.PROCESS_MODE_PAUSABLE
	%SpawnTimer.start()
	
	# set upgrade number
	upgrade_nums.clear()
	for i in range(upgraded_parties):
		var rand = randi_range(0,enemy_parties - 1)
		while upgrade_nums.has(rand):
			rand = randi_range(0,enemy_parties - 1)
		upgrade_nums.append(rand)
	
	for c in ui.get_children():
		if !c is Control: continue
		if c == ui.night_counter or c == ui.decrees : continue
		c.hide()

func on_enemy_group_eliminated() -> void:
	if spawned_parties < enemy_parties : return
	await get_tree().create_timer(.05).timeout
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	if enemyGroupNode.get_children().is_empty():
		night_ended.emit()
		
func on_night_ended() -> void:
	# Reset after dispatch day
	if dispatchDay:
		dispatchDay = false
	
	# Reset after swarm of expansion
	if night_is_expansion:
		night_is_expansion = false
		enemy_parties -= 4
		upgraded_parties -= 2
		%SpawnTimer.wait_time += 1.5
		
	# clear dead enemies
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	for enemy in enemies:
		enemy.queue_free()
	
	# remove cooldown for decrees
	for d : Decree in get_tree().get_nodes_in_group("DECREE"):
		if d.time == 0 : continue
		d.time -= 1.0
		d.update_cooldown()
		pass
	
	if is_combat_phase == false : return
	ui.rollArray.append(Card.ROLLTYPE.GENERAL)
	start_day()
	tileWorld.activeDecree = Decree.TYPE.NONE

func start_day() -> void:
	ui.crtr_night.stop()
	ui.crtr_day.play()
	ui.hand.process_mode = Node.PROCESS_MODE_PAUSABLE
	ui.decrees.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# progress nights
	Global.nights += 1
	check_nights()
	# start upgrade sequence
	is_combat_phase = false
	
	ui.cards.show()
	
	# convert units to cards
	var unitsGroups = get_tree().get_first_node_in_group("GROUPSNODE")
	for g : Group in unitsGroups.get_children():
		if g.conscripted :
			g.terminate()
			continue
		unit_to_card(g)
		g.terminate()
		
	for card : Card in Global.cardsDispatched:
		ui.rollArray.append(Card.ROLLTYPE.CHARM)
	
	# repair buildings
	# jk we don't do that anymore
	# run chance for extra roll
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	var nursuries = buildings.filter(func(b : Building): return b.type == Building.TYPE.NURSERY)
	var storages = buildings.filter(func(b : Building): return b.type == Building.TYPE.STORAGE)
	check_extra_roll(Card.ROLLTYPE.UNIT,nursuries,25)
	check_extra_roll(Card.ROLLTYPE.BUILDINGS,storages,25)
	
	tileWorld.handle_navigable_cells()

func unit_to_card(g : Group) -> void:
	# create card of group
	var newCard = preload("res://UI/Scenes/card.tscn").instantiate()
	newCard = match_unit_to_card(newCard,g.type)
	if g.charm : newCard = preserve_charm_in_card(newCard,g.charm.type)
	newCard.level = g.level
	
	# add card to hand
	Global.cardsInHand.append(newCard)
	ui.hand.get_child(0).add_child(newCard)
	if newCard.charm : newCard.charm_pos.add_child(newCard.charm)
	newCard.for_show = false

func check_extra_roll(extraRolltype : Card.ROLLTYPE,buildingArray : Array, chance : float) -> void:
	var extraChance = chance * buildingArray.size()
	while extraChance > 0:
		var rand = randi_range(1,100)
		if extraChance > rand:
			ui.rolltype = extraRolltype
			ui.cards.show()
			ui.rollArray.append(extraRolltype)
		extraChance -= 100

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	# chance for double
	var rand = randi() % 4
	if rand == 1:
		var parties = Global.nights / 4
		for i in range(parties):
			spawn_enemy()
	await get_tree().create_timer(.5).timeout
	if spawned_parties >= enemy_parties:
		%SpawnTimer.stop()

func match_unit_to_card(card : Card,unitType : Unit.TYPE) -> Card:
	match unitType:
		Unit.TYPE.MELEE:
			card.type = Card.CARDTYPE.BITER
		Unit.TYPE.RANGED:
			card.type = Card.CARDTYPE.SPITTER
		Unit.TYPE.SHIELDED:
			card.type = Card.CARDTYPE.PLATED
		Unit.TYPE.CRAZED:
			card.type = Card.CARDTYPE.CRAZED
		Unit.TYPE.BOMBER:
			card.type = Card.CARDTYPE.BOMBARDIER
		Unit.TYPE.FLYING:
			card.type = Card.CARDTYPE.FLYING
	return card
func preserve_charm_in_card(card : Card, charmType : Charm.TYPE) -> Card:
	var dupeCharm : Charm = preload("res://Units/Scenes/charm.tscn").instantiate()
	dupeCharm.type = charmType
	
	card.charm = dupeCharm
	return card

var tile2
func _input(event: InputEvent) -> void:
	if event.is_action_released("select"):
		tile2 = tileWorld.ground.local_to_map(get_global_mouse_position())
		mouse_clicked.emit()
	if event.is_action_pressed("ui_accept"):
		Engine.time_scale = 8

func check_nights() -> void:
	if Global.nights % 2 == 0:
		enemy_parties += 1
	
	if Global.nights % 3 == 0:
		dispatchDay = true
	
	if Global.nights % 4 == 0:
		upgraded_parties += 1
	
	if Global.nights % 6 == 0:
		night_is_expansion = true
		add_house_card()
		ui.rollArray.append(Card.ROLLTYPE.BLESSING)
		expand()
		
	if Global.nights % 10 == 0:
		%SpawnTimer.wait_time -= 1.5

func expand() -> void:
	Global.expansions += 1
	tileWorld.draw_build_area()


func _on_timer_timeout() -> void:
	if !is_combat_phase: return
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	if spawned_parties >= enemy_parties:
		if enemies.is_empty(): 
			night_ended.emit()
			return
	elif spawned_parties < enemy_parties:
		if %SpawnTimer.time_left > 0:
			return
		else:
			spawn_enemy()
