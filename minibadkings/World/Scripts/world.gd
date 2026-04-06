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
@export var rebel_parties : int = 1

@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var enemy_perimeters: Node = %EnemyPerimeters
@onready var groupNode : Node2D = get_tree().get_first_node_in_group("GROUPSNODE")
@onready var ui: UI = get_tree().get_first_node_in_group("UI")
@onready var game: Node2D = %Game
@onready var camera: Camera2D = %Camera2D
@onready var spawnTimer : Timer = %SpawnTimer

var outerFollow : PathFollow2D
var innerFollow : PathFollow2D

var spawned_parties : int = 0
var upgrades_given : int = 0
var upgrade_nums : Array = []
var rebel_nums : Array = []

var dispatchDay : bool = false

var night_is_expansion: bool = false

var food_debt : int

func _ready() -> void:
	# Load profile data
	Global.unlockedCards = Card.DEFAULT_CARDS
	SaveLoad._load_profile()
	ui._on_mainmenu_mouse_entered()
	#unlock_every_card()
	
	
	# connect signals
	night_started.connect(on_night_started)
	night_ended.connect(on_night_ended)
	enemy_group_eliminated.connect(on_enemy_group_eliminated)
	
	Engine.time_scale = 1
	await RenderingServer.frame_post_draw
	DisplayServer.window_set_title("Critterking", get_window().get_window_id())

func new_game() -> void:
	# set up initial rolls
	ui.rollArray.clear()
	ui.rollArray.append(Card.ROLLTYPE.UNIT)
	ui.rollArray.append(Card.ROLLTYPE.UNIT)
	ui.rollArray.append(Card.ROLLTYPE.SHOP)
	
	await get_tree().create_timer(.125).timeout
	# reset data
	%SpawnTimer.stop()
	%SpawnTimer.wait_time = 10
	if ui.currentAscn >= 8: %SpawnTimer.wait_time -= 1
	enemy_parties = 3
	if ui.currentAscn >= 6: enemy_parties += 1
	upgraded_parties = 0
	dispatchDay = false
	tileWorld.activeDecree = Decree.TYPE.NONE
	tileWorld.buffed_tiles.clear()
	Global.nights = 0
	Global.expansions = 0
	if ui.currentAscn >= 7: Global.expansions -= 1
	if ui.currentChal == UI.CHALLENGE.MINIMALIST: Global.expansions -= 1
	Global.cardsInHand.clear()
	Global.cardsDispatched.clear()
	for decree in get_tree().get_nodes_in_group("DECREE"):
		decree.queue_free()
	
	# resource data
	Global.resource_dict = Global.default_resource_dict.duplicate()
	
	
	# map gen with tilemap patterns
	clear_world()
	await get_tree().create_timer(.125).timeout
	tileWorld.generate_map_patterns()
	tileWorld.draw_build_area()
	tileWorld.restricted_tiles.clear()
	tileWorld.blocked_entry_tiles.clear()
	
	ui.cards.show()
	create_enemy_perimeter(12 + Global.expansions, true)
	create_enemy_perimeter(11 + Global.expansions, false)
	
	
	# add house card
	for i in range(1):
		add_house_card()
	for i in range(1):
		var hCard : Card = load("res://UI/Scenes/card.tscn").instantiate()
		hCard.type = Card.CARDTYPE.FIELD
		ui.hand_container.add_child(hCard)
		hCard.set_owner(get_tree().get_current_scene())
	for i in range(2):
		var hCard : Card = load("res://UI/Scenes/card.tscn").instantiate()
		hCard.type = Card.CARDTYPE.POND
		ui.hand_container.add_child(hCard)
		hCard.set_owner(get_tree().get_current_scene())
	
	#Challenges
	if ui.currentChal == UI.CHALLENGE.JUICED: Engine.time_scale = 2.5
	else: Engine.time_scale = 1
	if ui.currentChal == UI.CHALLENGE.TOWERDEFENSE: expand()
	
func add_house_card() -> void:
	var hCard : Card = load("res://UI/Scenes/card.tscn").instantiate()
	hCard.type = Card.CARDTYPE.HOUSE
	ui.hand_container.add_child(hCard)
	hCard.set_owner(get_tree().get_current_scene())
	
func unlock_every_card() -> void:
	# unlock every card
	var arr = []
	for i in Card.CARDTYPE.size():
		arr.append(i)
	Global.unlockedCards = arr
	
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
	for b : Building in get_tree().get_nodes_in_group("BUILDING"):
		b.remove()
	# cards
	var cards = get_tree().get_nodes_in_group("CARD")
	for c : Card in cards:
		if c.for_show or c.inspected : continue
		c.queue_free()
	# obstacles
	for cell in tileWorld.obstacles.get_used_cells():
		tileWorld.obstacles.set_cell(cell,-1)

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
	enemy_spawn.set_owner(get_tree().get_current_scene())
	enemy_spawn.curve = curve
	enemy_spawn.add_child(follow)
	follow.set_owner(get_tree().get_current_scene())
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
	var enemGroup : EnemyGroup = ENEMYGROUP.instantiate()
	enemGroup.global_position = follow.global_position
	enemGroup.size = randi_range(3,6)
	if upgrade_nums.has(spawned_parties):
		enemGroup.level = 2
	
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	enemyGroupNode.add_child(enemGroup)
	enemGroup.set_owner(get_tree().get_current_scene())
	
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
	
	# make check for rebels
	if rebel_nums.has(spawned_parties):
		spawn_rebel_or_militia(true)
	
	spawned_parties += 1

func spawn_rebel_or_militia(rebel : bool) -> void:
	var houses : Array = get_tree().get_nodes_in_group("BUILDING")
	houses = houses.filter(func(e : Building):return e.type == Building.TYPE.HOUSE)
	
	var randHouse = randi_range(0,houses.size() - 1)
	var rebelHouse : Building = houses[randHouse]
	
	if rebel:
		rebelHouse.anim.play("rebel")
	else:
		rebelHouse.anim.play("militia")


func on_night_started() -> void:
	%Failcheck.start()
	ui.hand.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui.decrees.process_mode = Node.PROCESS_MODE_PAUSABLE
	if night_is_expansion:
		%SpawnTimer.wait_time -= 1
		if ui.currentAscn >= 10:
			enemy_parties += 4
			upgraded_parties += 2
		else:
			enemy_parties += 3
			upgraded_parties += 1
	
	
	# set upgrade number
	upgrade_nums.clear()
	for i in range(upgraded_parties):
		var rand = randi_range(0,enemy_parties - 1)
		while upgrade_nums.has(rand):
			rand = randi_range(0,enemy_parties - 1)
		upgrade_nums.append(rand)
		
	# set rebel numbers
	if Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] < 25:
		rebel_parties = 1 * ((Global.resource_dict[Global.RESOURCETYPE.CITIZEN] / 6) + 1)
		if Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] <= 0:
			rebel_parties = enemy_parties
	
	rebel_nums.clear()
	for i in range(rebel_parties):
		var rand = randi_range(0,enemy_parties - 1)
		while rebel_nums.has(rand):
			rand = randi_range(0,enemy_parties - 1)
		rebel_nums.append(rand)
	
	# set/spawn militia numbers
	if Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] >= 75:
		spawn_rebel_or_militia(false)
		pass

	# start game and hide menus
	tileWorld.handle_navigable_cells()
	is_combat_phase = true
	spawned_parties = 0
	spawn_enemy()
	%Game.process_mode = Node.PROCESS_MODE_PAUSABLE
	%SpawnTimer.start()
	
	for c in ui.get_children():
		if !c is Control: continue
		if c == ui.info_overlay or c == ui.decrees : continue
		c.hide()
		
	# handle 
		
		
	# resource consumption
	handle_resource_consumption()

func handle_resource_consumption() -> void:
	Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] -= 5
	Global.resource_dict[Global.RESOURCETYPE.FOOD] -= Global.partyCount * 2
	
	# consider food debt
	if Global.resource_dict[Global.RESOURCETYPE.FOOD] < 0:
		var satisfaction_penalty = abs(Global.resource_dict[Global.RESOURCETYPE.FOOD])
		Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] -= satisfaction_penalty
		Global.resource_dict[Global.RESOURCETYPE.FOOD] = 0
		food_debt = satisfaction_penalty
	else:
		food_debt = 0
		
	if Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] < 0:
		Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] = 0 
	
	# pay wages
	for g : AllyGroup in get_tree().get_nodes_in_group("ALLYGROUP"):
		Global.resource_dict[Global.RESOURCETYPE.MONEY] -= g.wage
		pass
	ui.info_overlay._update_resources()


func on_enemy_group_eliminated() -> void:
	if spawned_parties < enemy_parties : return
	await get_tree().create_timer(.05).timeout
	var enemyGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	if enemyGroupNode.get_children().is_empty():
		night_ended.emit()
		
func on_night_ended() -> void:
	# Reset after swarm of expansion
	if night_is_expansion:
		night_is_expansion = false
		if ui.currentAscn >= 10:
			enemy_parties -= 4
			upgraded_parties -= 2
		else:
			enemy_parties -= 3
			upgraded_parties -= 1
		%SpawnTimer.wait_time += 1
	
	# clear dead enemies
	clear_entities()
	
	# remove cooldown for decrees
	for d : Decree in get_tree().get_nodes_in_group("DECREE"):
		if d.time == 0 : continue
		d.time -= 1.0
		d.update_cooldown()
		pass
		
	# remove highlight
	tileWorld.highlight_buildings(false,Building.TYPE.NONE)
	tileWorld.hover.visible = false
	
	if is_combat_phase == false : return
	if ui.anim.is_playing():return
	ui.rollArray.append(Card.ROLLTYPE.GENERAL)
	start_day()
	ui.rollArray.append(Card.ROLLTYPE.SHOP)
	tileWorld.activeDecree = Decree.TYPE.NONE
	
	# reward
	Global.resource_dict[Global.RESOURCETYPE.MONEY] += 10
	ui.info_overlay._update_resources()
func clear_entities() -> void:
	# clear dead enemies
	if !get_tree():return
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	for enemy in enemies:
		enemy.queue_free()
	var enemGroups = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	for grp in enemGroups.get_children():
		grp.queue_free()
		
	# convert units to cards
	var unitsGroups = get_tree().get_first_node_in_group("GROUPSNODE")
	for g : Group in unitsGroups.get_children():
		
		if g.conscripted :
			g.terminate()
			continue
		unit_to_card(g)
		g.terminate()
		
	# clear dead allies
	var allies = get_tree().get_nodes_in_group("ALLY")
	for a : Ally in allies:
		if a.dead: a.queue_free()
		
	# clear zombified 
	for unit in get_tree().get_first_node_in_group("UNITSNODE").get_children():
		if unit.type == Unit.TYPE.ZOMBIFIED : unit.queue_free()
		
	# clear projectiles
	for p in get_tree().get_nodes_in_group("PROJECTILE"):
		p.queue_free()

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
	
	for card : Card in Global.cardsDispatched:
		# find position of shop and place it before
		var shopInd = ui.rollArray
		ui.rollArray.append(Card.ROLLTYPE.CHARM)
	
	# repair buildings
	# jk we don't do that anymore
	# run chance for extra roll
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	var traps = buildings.filter(func(b : Building): return b.type == Building.TYPE.TRAP)
	var nursuries = buildings.filter(func(b : Building): return b.type == Building.TYPE.NURSERY)
	var storages = buildings.filter(func(b : Building): return b.type == Building.TYPE.STORAGE)
	check_extra_roll(Card.ROLLTYPE.UNIT,nursuries,25)
	check_extra_roll(Card.ROLLTYPE.BUILDINGS,storages,25)
	
	# remove temp traps
	for trap : Building in traps:
		if trap.temporary: 
			trap.remove()
			
	tileWorld.handle_navigable_cells()
	if ui.currentChal == UI.CHALLENGE.JUICED: Engine.time_scale = 2.5
	ui.save_game_delayed()
	
func unit_to_card(g : Group) -> void:
	# create card of group
	var newCard = load("res://UI/Scenes/card.tscn").instantiate()
	newCard.type = g.type
	if g.charm : newCard = preserve_charm_in_card(newCard,g.charm.type)
	newCard.level = g.level
	
	# add card to hand
	Global.cardsInHand.append(newCard)
	ui.hand_container.add_child(newCard)
	if newCard.charm : 
		newCard.charm_pos.add_child(newCard.charm)
		newCard.charm.set_owner(get_tree().get_current_scene())
	newCard.for_show = false
	newCard.set_owner(get_tree().get_current_scene())
	
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
		
	
		
func preserve_charm_in_card(card : Card, charmType : Charm.TYPE) -> Card:
	var dupeCharm : Charm = preload("res://Units/Scenes/charm.tscn").instantiate()
	dupeCharm.type = charmType
	
	card.charm = dupeCharm
	return card

var tile2
func _input(event: InputEvent) -> void:
	if event.is_action_released("select") or event.is_action_pressed("select"):
		#if ui.unlock.visible and !ui.anim.is_playing(): ui.hide_unlocks()
		tile2 = tileWorld.ground.local_to_map(get_global_mouse_position())
		mouse_clicked.emit()
	if event.is_action_pressed("ui_accept"):
		#ui.info_overlay._update_resources()
		#ui.info_overlay._update_traits()
		Engine.time_scale = 8
		return

	#if event.is_action_pressed("cancel"):
		#print(Global.wins)
		#SaveLoad._reset_profile()
		#SaveLoad._load_profile()
func world_start() -> void:
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	ui.crtr_pause.stop()
	ui.pausemenu.hide()
	ui.mainmenu.hide()
	if !is_combat_phase: ui.end_turn.show()
	if is_combat_phase: ui.crtr_night.play()

func check_nights() -> void:
	if Global.nights % 2 == 0:
		enemy_parties += 1
	if ui.currentAscn < 5: 
		if Global.nights % 3 == 0:
			dispatchDay = true
	
	if Global.nights % 4 == 0:
		upgraded_parties += 1
		if ui.currentAscn >= 5: dispatchDay = true 
	
	if Global.nights % 6 == 0:
		night_is_expansion = true
		add_house_card()
		ui.rollArray.append(Card.ROLLTYPE.BLESSING)
		expand()
		
	if Global.nights % 10 == 0:
		%SpawnTimer.wait_time -= 1
		
	if Global.nights == 25 and ui.currentChal == UI.CHALLENGE.JUICED:
		ui.victory()
	if Global.nights == 19 && ui.currentChal == UI.CHALLENGE.MINIMALIST:
		ui.victory()
	if Global.nights == 19 && ui.currentChal == UI.CHALLENGE.TOWERDEFENSE:
		ui.victory()
	if Global.nights == 31 and ui.currentChal == UI.CHALLENGE.NONE:
		ui.victory()
		

func expand() -> void:
	if ui.currentChal == UI.CHALLENGE.MINIMALIST: return
	Global.expansions += 1
	tileWorld.draw_build_area()

func _on_timer_timeout() -> void:
	SaveLoad._save_profile(ui)
	if !is_combat_phase: return
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	enemies = enemies.filter(func(e : Enemy):return !e.dead)
	if spawned_parties >= enemy_parties:
		if enemies.is_empty(): 
			night_ended.emit()
			return
	elif spawned_parties < enemy_parties:
		if %SpawnTimer.time_left > 0:
			return
		else:
			spawn_enemy()
