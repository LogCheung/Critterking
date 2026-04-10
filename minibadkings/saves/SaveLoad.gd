extends Node

const save_location = "user://SaveFile.tres"
const prof_location = "user://ProfileFile.tres"

@export var SaveFileData : SaveDataResource = null:
	set(value):
		SaveFileData = value

@export var ProfFileData : ProfileDataResource = ProfileDataResource.new()

func _save(#scene : PackedScene, 
		rollArray : Array, walls : PackedByteArray,
		ground : PackedByteArray, obstacles : PackedByteArray, ring : PackedByteArray,
		dispatchDay : bool, defeated : bool, ascension : int, challenge : int):
	
	SaveFileData = SaveDataResource.new()
	#SaveFileData.scene = scene
	SaveFileData.nights = Global.nights
	SaveFileData.expansions = Global.expansions
	SaveFileData.rolls = rollArray
	SaveFileData.walls = walls
	SaveFileData.ground = ground
	SaveFileData.obstacles = obstacles
	SaveFileData.ring = ring
	SaveFileData.dispatchDay = dispatchDay
	SaveFileData.defeated = defeated
	SaveFileData.ascension = ascension
	SaveFileData.challenge = challenge
	
	SaveFileData.resource_dict = Global.resource_dict.duplicate()
	SaveFileData.trait_dict = Global.trait_dict.duplicate()
	# save cards
	SaveFileData.cardsInHand.clear()
	for card in Global.cardsInHand:
		var dupe = load("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = card.type
		dupe.level = card.level
		SaveFileData.cardsInHand.append(dupe)
		dupe.for_show = false
		
		if card.charm:
			var nCharm = load("res://Units/Scenes/charm.tscn").instantiate()
			nCharm.type = card.charm.type
			dupe.charm = nCharm
	
	# save decrees 
	SaveFileData.decreesEquipped.clear()
	for d in Global.decreesEquipped:
		if !d : continue
		var dupe : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
		dupe.type = d.type
		dupe.time = d.time
		dupe.cooldown = d.cooldown
		SaveFileData.decreesEquipped.append(dupe)
	
	# save buildings
	SaveFileData.buildings.clear()
	for b : Building in get_tree().get_nodes_in_group("BUILDING"):
		var BUILDING = load("res://TileMap/Scenes/building.tscn")
		var COLONY = load("res://TileMap/Scenes/colonyBuilding.tscn")
		var isColony : bool = false
		# determine if colony building or not
		var building : Building = BUILDING.instantiate()
		if b.type >= Building.TYPE.TAVERN and b.type != Building.TYPE.RUINS:
			building = COLONY.instantiate()
			isColony = true
		if b.type == Building.TYPE.HOUSE:
			building = COLONY.instantiate()
			isColony = true
		#
		building.type = b.type
		building.global_position = b.global_position
		building.health = b.health
		building.time = b.time
		building.active = b.active
		#
		if isColony:
			building.workers = b.workers
			
		SaveFileData.buildings.append(building)
		
	
	if SaveFileData == null : return
	ResourceSaver.save(SaveFileData,save_location)

func _save_profile(ui : UI) -> void:
	ProfFileData.wins = Global.wins
	
	ProfFileData.tutorial = Global.tutorial
	ProfFileData.tutorialCharm = Global.tutorialCharm
	ProfFileData.tutorialDecree = Global.tutorialDecree
	
	ProfFileData.unlockedCards = Global.unlockedCards
	ProfFileData.maxAscn = Global.maxAscension
	
	ProfFileData.masterVol = ui.master.value
	ProfFileData.musicVol = ui.music.value
	ProfFileData.sfxrVol = ui.sfx.value
	
	ResourceSaver.save(ProfFileData,prof_location)
	
	_load_profile()
	pass

func _load() -> void:
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)
		if SaveFileData.nights == 0 : 
			print("night")
			return
		if SaveFileData.defeated: 
			print("huh")
			return
		
		# clear world
		for i in range(10):
			await get_tree().process_frame
		var world = get_tree().get_first_node_in_group("WORLD")
		world.clear_world()
		
		#get_tree().change_scene_to_packed(SaveFileData.scene)
		await get_tree().process_frame
		await get_tree().process_frame
		var ui = get_tree().get_first_node_in_group("UI")
		ui.load_world()
		

func _load_profile() -> void:
	if FileAccess.file_exists(prof_location):
		ProfFileData = ResourceLoader.load(prof_location).duplicate(true)
		
		Global.wins = ProfFileData.wins
		
		Global.tutorial = ProfFileData.tutorial
		Global.tutorialCharm = ProfFileData.tutorialCharm
		Global.tutorialDecree = ProfFileData.tutorialDecree
		
		Global.unlockedCards = ProfFileData.unlockedCards
		for num in Card.DEFAULT_CARDS:
			if !Global.unlockedCards.has(num):
				Global.unlockedCards.append(num)
		
		Global.maxAscension = ProfFileData.maxAscn 
		
		var ui = get_tree().get_first_node_in_group("UI")
		ui.master.value = ProfFileData.masterVol
		ui.music.value = ProfFileData.musicVol
		ui.sfx.value = ProfFileData.sfxrVol

func _reset_profile() -> void:
	if FileAccess.file_exists(prof_location):
		ProfFileData = ProfileDataResource.new()
		
		ProfFileData.wins = 0
		
		ProfFileData.tutorial = true
		ProfFileData.tutorialCharm = true
		ProfFileData.tutorialDecree = true
		
		ProfFileData.unlockedCards = Card.DEFAULT_CARDS
		
		ProfFileData.masterVol = .5
		ProfFileData.musicVol = .5
		ProfFileData.sfxrVol = .5
		
		ResourceSaver.save(ProfFileData,prof_location)
	
	SaveFileData = SaveDataResource.new()
	ResourceSaver.save(SaveFileData,save_location)
