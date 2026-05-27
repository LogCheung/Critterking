extends StaticBody2D
class_name Building

signal destroyed
signal day_ended

const HIGHLIGHT = preload("res://Units/Shaders/houseHighlight.tres")
const HOUSEA = preload("res://TileMap/Assets/houseA.png")
const HOUSEB = preload("res://TileMap/Assets/houseB.png")
const TRAPA = preload("res://TileMap/Assets/trapA.png")
const TRAPB = preload("res://TileMap/Assets/trapB.png")
const RUIN = preload("res://TileMap/Assets/ruinBreak.png")
const FARM = preload("res://TileMap/Assets/farmBuild.png")
const SAPSTORE = preload("res://TileMap/Assets/sapBuild.png")
const CARE = preload("res://TileMap/Assets/careBuild.png")
const NURSERY = preload("res://TileMap/Assets/nurseryBuild.png")
const STORAGE = preload("res://TileMap/Assets/storageBuild.png")
const TUNNELA = preload("res://TileMap/Assets/buildTunnelA.png")
const TUNNELB = preload("res://TileMap/Assets/buildTunnelB.png")
const FORT = preload("res://TileMap/Assets/fort.png")
const CAMPFIRE = preload("res://TileMap/Assets/buildCampfire.png")
const CLIFF = preload("res://TileMap/Assets/buildCliff.png")

const ALWAYS_ACTIVE = [
	TYPE.TRAP, TYPE.MONUMENT, TYPE.POND, TYPE.STORAGE, TYPE.CAMPFIRE,
	TYPE.FORT, TYPE.RUINS, TYPE.CARE
]

enum TYPE {
	NONE, TRAP, HOUSE, CARE,  FARM, SAPSTORE, FORT, CAMPFIRE, #CLIFF,  TUNNEL, 
	 NURSERY, STORAGE, 
	# colony buildings
	TAVERN, MONUMENT, CASINO, THEATRE, HALL, TRADINGPOST, MARKETPLACE, GARDEN,
	CUSTOMS, PANTRY, GUILD, FIELD, SCHOOL, POND, BAKERY,
	
	RUINS, 
}

static var pantryActive : bool = false
@export var type : TYPE
@export var occupant : AllyGroup 
@export var health : int = 30
@export var max_health : int = 30
@export var temporary : bool = false
@export var traitType : Global.TRAITTYPE = Global.TRAITTYPE.CULTURE
@export var traitAmt : int = 0
@export var resourceType : Global.RESOURCETYPE = Global.RESOURCETYPE.NONE
@export var resourceAmt : int = 0
@export var cooldown : int = 1
@export var time : int = 0
@export var active : bool = true
@export var max_workers : int = 1
@export var workers : int = 0
@export var citizenWorker : Citizen

@onready var entrance: Node2D = %Entrance
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var bar: TextureProgressBar = $TextureProgressBar
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var ui : UI = get_tree().get_first_node_in_group("UI")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var toggle : Button = %Toggle
@onready var citizen_toggle_sprite: Sprite2D = %CitizenToggle
@onready var worker_alert_sprite: Sprite2D = %WorkerAlert
@onready var citizen_bar: TextureProgressBar = %CitizenBar


var buff_tiles : Array
var tile : Vector2i
var prevTileType : int
var doorstepTile : Vector2i
var highlightSprite : Sprite2D

func _ready() -> void:
	citizen_bar.hide()
	%fire.hide()
	%Toggle.hide()
	%Toggle.connect("toggled",_on_toggle_toggled)
	
	# set up position and blocking navigation
	tile = tileWorld.ground.local_to_map(global_position)
	if temporary : prevTileType = tileWorld.ground.get_cell_alternative_tile(tile)
	tileWorld.ground.set_cell(tile,0,Vector2(0,0),2)
	doorstepTile = tileWorld.ground.local_to_map(entrance.global_position)
	match_type()
	
	if ALWAYS_ACTIVE.has(type):
		set_active(true)
	
	ui.info_overlay._update_traits()
	ui.info_overlay.handle_party_limit()
	
	if health > 0:
		visible = true
		%Build.play()
		anim.play("build")
		
		if type == TYPE.CAMPFIRE:
			await anim.animation_finished
			%fire.show()
			%fire.play("default")
	
	# signals
	day_ended.connect(on_day_ended)
	world.night_ended.connect(on_day_started)

func _process(delta: float) -> void:
	# highlight and inspect functionality
	if !world.is_combat_phase and tileWorld.mouseTile == tile and type != TYPE.RUINS:
		_on_mouse_entered()
		if Input.is_action_just_released("inspect"):
			ui.inspect_card.inspect_card(int(type + Card.CARDTYPE.TRAPS - 1))
	elif !world.is_combat_phase:
		_on_mouse_exited()
		
		
	# health functionality
	if health <= 0:
		on_destroyed()
	if health <= max_health / 2 and health > 0:
		sprite_2d.modulate.v = .4
	else:
		sprite_2d.modulate.v = 1
		
	# occupants
	if occupants_inside():
		if %Timer.time_left <= 0:
			%Timer.start()
		bar.visible = true
	else:
		%Timer.stop()
		bar.value = 0
		bar.visible = false
	
	# fort functionality
	if type == TYPE.FORT:
		if !world.is_combat_phase:
			tileWorld.ground.set_cell(tile,0,Vector2(0,0),2)
		else:
			tileWorld.ground.set_cell(tile,0,Vector2(0,0),0)

func occupants_inside() -> bool:
	if !occupant : return false
	#if type != TYPE.HOUSE || type != TYPE.CARE : return false
	for unit in occupant.unitsArray:
		if unit.visible == true and !unit.dead:
			return false
	return true

func match_type() -> void:
	match type:
		TYPE.TRAP:
			sprite_2d.texture = TRAPA if randi() % 2 == 0 else TRAPB
			#sprite_2d.offset = Vector2.ZERO
			z_index = 0
			tileWorld.ground.set_cell(tile,0,Vector2(0,0),3)
		TYPE.CARE:
			sprite_2d.texture = CARE
			
			await anim.animation_finished
			duplicate_sprite()
		TYPE.SAPSTORE:
			sprite_2d.texture = SAPSTORE
			for x in range(tile.x-1,tile.x+2):
				for y in range(tile.y-1,tile.y+2):
					if Vector2i(x,y) == tile : continue
					buff_tiles.append(Vector2i(x,y))
			tileWorld.buffed_tiles.append_array(buff_tiles)
		TYPE.FARM:
			sprite_2d.texture = FARM
			for x in range(tile.x-1,tile.x+2):
				if tile.x  == x : continue
				buff_tiles.append(Vector2i(x,tile.y))
			for y in range(tile.y-1,tile.y+2):
				if tile.y == y : continue
				buff_tiles.append(Vector2i(tile.x,y))
			tileWorld.buffed_tiles.append_array(buff_tiles)
		TYPE.RUINS:
			%fire.hide()
			sprite_2d.texture = HOUSEA
			sprite_2d.frame = 1
			sprite_2d.offset = Vector2(0,-16)
			
			traitAmt = 0
			traitType = Global.TRAITTYPE.NONE
			resourceType = Global.RESOURCETYPE.NONE
			resourceAmt = 0
		TYPE.NURSERY:
			sprite_2d.texture = NURSERY
		TYPE.STORAGE:
			sprite_2d.texture = STORAGE
			sprite_2d.scale.x = -1
		TYPE.FORT:
			sprite_2d.texture = FORT
			sprite_2d.offset = Vector2(-1,-10)
		TYPE.CAMPFIRE:
			sprite_2d.texture = CAMPFIRE
	duplicate_sprite()
	
	# normal map texture
	var texture : CanvasTexture = CanvasTexture.new()
	texture.diffuse_texture = sprite_2d.texture
	texture.normal_texture = load("res://TileMap/Assets/norms/"+ TYPE.keys()[type].to_lower() +"Buildnorm.png")
	sprite_2d.texture = texture
	
func duplicate_sprite() -> void:
	# used for buildings selected during battle
	# allows for highlight when hovered for and making it clearer to player
	# if where they're about to click is actually on the building
	var newSprite = sprite_2d.duplicate()
	newSprite.material = null
	newSprite.visible = false
	newSprite.light_mask = 10
	newSprite.frame = 7
	add_child(newSprite)
	highlightSprite = newSprite
	pass

func spawn_rebels() -> void:
	var rebelGroup : EnemyGroup = load("res://Units/Scenes/enemy_group.tscn").instantiate()
	rebelGroup.size = 6
	rebelGroup.tile = doorstepTile
	rebelGroup.global_position = tileWorld.ground.map_to_local(doorstepTile)
	
	var enemGroupNode = get_tree().get_first_node_in_group("ENEMYGRPNODE")
	enemGroupNode.add_child(rebelGroup)
	rebelGroup.set_owner(get_tree().get_current_scene())

func spawn_militia() -> void:
	var unitType = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	while !Global.unlockedCards.has(unitType) or unitType == Unit.TYPE.BOMBER:
		unitType = randi_range(Unit.TYPE.MELEE,Unit.TYPE.CRAZED)
	
	
	var militiaGroup : AllyGroup = load("res://Units/Scenes/unit_group.tscn").instantiate()
	militiaGroup.type = unitType
	militiaGroup.tile = doorstepTile
	militiaGroup.level = 1
	militiaGroup.global_position = tileWorld.ground.map_to_local(militiaGroup.tile)
	
	militiaGroup.conscripted = true
	
	var groupsNode = get_tree().get_first_node_in_group("GROUPSNODE")
	groupsNode.add_child(militiaGroup) # group ready is then called
	militiaGroup.set_owner(get_tree().get_current_scene())
			
	# stage them coming from building
	for u in militiaGroup.unitsArray:
		u.global_position = entrance.global_position

func on_destroyed() -> void:
	if type == TYPE.RUINS : return
	# tiledata update
	type = TYPE.RUINS
	tileWorld.find_blocked_entry_tiles()
	tileWorld.find_restricted_tiles()
	# Change appearance and play destroy
	%Break.play()
	anim.play("destroy")
	set_active(false)
	worker_alert_sprite.hide()
	await anim.animation_finished
	match_type()
	ui.info_overlay._update_traits()
	
	# alert enemies
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	#if type == TYPE.HOUSE:
	for enemy : Enemy in enemies:
		enemy.house_destroyed.emit()
	
	# check if final house destroyed and if player lost
	var buildings = get_tree().get_nodes_in_group("BUILDING")
	buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
	if buildings.is_empty():
		ui.game_over.emit()
		# lose screen
		
	# kill unit inside if group is healing
	if occupants_inside():
		occupant.terminate()
	# remove buffed tiles
	for t in buff_tiles:
		tileWorld.buffed_tiles.remove_at(tileWorld.buffed_tiles.find(t))
	
	
func remove() -> void:
	tileWorld.ground.set_cell(tile,0,Vector2(0,0),1)
	if temporary : tileWorld.ground.set_cell(tile,0,Vector2(0,0),prevTileType)
	queue_free()
	tileWorld.handle_navigable_cells()
	
	if type == TYPE.HOUSE:
		type = TYPE.RUINS
		var buildings = get_tree().get_nodes_in_group("BUILDING")
		buildings = buildings.filter(func(b):return b.type == Building.TYPE.HOUSE)
		if buildings.is_empty():
			ui.game_over.emit()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.owner is Unit:
		if type == TYPE.TRAP:
			var enemy : Unit = area.owner
			enemy.health -= 1.5
			enemy.hurt.play()
			enemy.hitAnim(true)
			if enemy.health <= 0:
				enemy.start_death()
	if area.owner is Ally:
		if type == TYPE.FORT:
			var target: Unit = area.owner
			target.resistance += .25
			#print("safe")
func _on_hurt_box_area_exited(area: Area2D) -> void:
	if area.owner is Ally:
		if type == TYPE.FORT:
			var target: Unit = area.owner
			target.resistance -= .25
			#print("unsafe")

func _on_adj_area_entered(area: Area2D) -> void:
	if world.is_combat_phase: return
	if area.owner is Ally:
		var target : Unit = area.owner
		if type == TYPE.SAPSTORE and active: 
			target.speed += 6
		#if type == TYPE.RUINS: target.speed -= 6

func _on_orth_area_entered(area: Area2D) -> void:
	if world.is_combat_phase: return
	if area.owner is Ally:
		var target : Unit = area.owner
		if !target.group : return
		if target.group.charm and target.group.charm.type == Charm.TYPE.DOLLHOUSE:
			if target.attack_cd.wait_time > .2:
				target.attack_cd.wait_time -=.2
			else:
				target.attack_cd.wait_time = .1
		if type == TYPE.FARM and active: 
			target.max_health = target.max_health + 0.5
			target.health = target.max_health

func _on_trans_area_entered(area: Area2D) -> void:
	if type == TYPE.TRAP: return
	sprite_2d.self_modulate.a = 0.8
	pass # Replace with function body.
func _on_trans_area_exited(area: Area2D) -> void:
	if !$trans.has_overlapping_areas():
		sprite_2d.self_modulate.a = 1
	pass # Replace with function body.

func _on_timer_timeout() -> void:
	# healing timer finished
	if ui.currentAscn >= 1:
		bar.value += 1
		if type == TYPE.CARE: bar.value += .5
	else:
		bar.value += 1.25 #if occupant.max_size <= 9 else .12345
		if type == TYPE.CARE: bar.value += .75
	if occupant.charm and occupant.charm.type == Charm.TYPE.MEDKIT: bar.value += .5
	if bar.value >= bar.max_value:
		occupant.global_position = tileWorld.ground.map_to_local(doorstepTile)
		if type == TYPE.CARE:
			occupant.max_size = round(occupant.max_size * (2.0/3)  + .4)
		else:
			occupant.max_size = 12 if occupant.level == 3 else 9
		occupant.respawn_units()
		occupant.house = null
		for unit : Ally in occupant.unitsArray:
			unit.healing = false
			unit.visible = true
			occupant = null
			
		%Timer.stop()

func _on_mouse_entered() -> void:
	if !highlightSprite: return
	if (Engine.time_scale == .1 and sprite_2d.material != null) or !world.is_combat_phase: 
		highlightSprite.modulate = Color(3,3,3)
		highlightSprite.visible = true

func _on_mouse_exited() -> void:
	if !highlightSprite: return
	highlightSprite.visible = false
	highlightSprite.modulate = Color(1,1,1)

func on_day_started() -> void:
	worker_alert_sprite.visible = !active and type != TYPE.RUINS
	pass

func on_day_ended() -> void:
	worker_alert_sprite.visible = false
	pass

func _on_toggle_toggled(toggled_on: bool) -> void:
	if ALWAYS_ACTIVE.has(type): 
		set_active(true)
		return
	if !active:
		var availWorkers = Global.resource_dict[Global.RESOURCETYPE.CITIZEN] - Global.resource_dict[Global.RESOURCETYPE.WORKER]
		if availWorkers <= 0: 
			calculate_active_workers()
			return
		
	# set active 
	set_active(toggled_on)
	
	calculate_active_workers()

func set_active(condition : bool) -> void:
	citizen_toggle_sprite.frame = 1 if condition else 0
	citizen_toggle_sprite.modulate.v = 1.5 if condition else 1.0
	active = condition
	worker_alert_sprite.visible = !condition
	
	ui.info_overlay.handle_projections()
	
	if active and !is_instance_valid(citizenWorker):
		var unitsNode : UnitsNode = get_tree().get_first_node_in_group("UNITSNODE")
		unitsNode.spawn_citizen(self)
		

func calculate_active_workers() -> void:
	var workedBuilds = get_tree().get_nodes_in_group("BUILDING")
	workedBuilds = workedBuilds.filter(func(b:Building):return b.active)
	workedBuilds = workedBuilds.filter(func(b:Building):return !ALWAYS_ACTIVE.has(b.type))
	
	var totalWorkers : int = 0
	for b : Building in workedBuilds:
		if b.max_workers > 1:
			totalWorkers += b.workers
		else:
			totalWorkers += 1
	
	Global.resource_dict[Global.RESOURCETYPE.WORKER] = totalWorkers
	ui.info_overlay.handle_worker_limit()
	
