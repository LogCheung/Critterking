extends Node

const save_location = "user://SaveFile.tres"
const prof_location = "user://ProfileFile.tres"

@export var SaveFileData : SaveDataResource = null:
	set(value):
		SaveFileData = value

@export var ProfFileData : ProfileDataResource = ProfileDataResource.new()

func _save(scene : PackedScene, rollArray : Array, walls : PackedByteArray,
		ground : PackedByteArray, obstacles : PackedByteArray, ring : PackedByteArray,
		dispatchDay : bool):
			
	Global.cardsDispatched.clear()
	SaveFileData = SaveDataResource.new()
	SaveFileData.scene = scene
	SaveFileData.nights = Global.nights
	SaveFileData.rolls = rollArray
	SaveFileData.walls = walls
	SaveFileData.ground = ground
	SaveFileData.obstacles = obstacles
	SaveFileData.ring = ring
	SaveFileData.dispatchDay = dispatchDay
	
	# save cards
	SaveFileData.cardsInHand.clear()
	for card in Global.cardsInHand:
		var dupe = load("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = card.type
		dupe.level = card.level
		dupe.charm = card.charm
		SaveFileData.cardsInHand.append(dupe)
		dupe.for_show = false
	
	# save decrees 
	SaveFileData.decreesEquipped.clear()
	for d : Decree in Global.decreesEquipped:
		var dupe : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
		dupe.type = d.type
		dupe.time = d.time
		dupe.cooldown = d.cooldown
		SaveFileData.decreesEquipped.append(dupe)
		
	
	if SaveFileData == null : 
		print("wow")
		return
	ResourceSaver.save(SaveFileData,save_location)

func _save_profile(ui : UI) -> void:
	ProfFileData.tutorial = Global.tutorial
	ProfFileData.tutorialCharm = Global.tutorialCharm
	ProfFileData.tutorialDecree = Global.tutorialDecree
	
	ProfFileData.unlockedCards = Global.unlockedCards
	
	ProfFileData.masterVol = ui.master.value
	ProfFileData.musicVol = ui.music.value
	ProfFileData.sfxrVol = ui.sfx.value
	
	ResourceSaver.save(ProfFileData,prof_location)
	pass

func _load() -> void:
	get_tree().get_first_node_in_group("WORLD").clear_world()
	
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)
		
		get_tree().change_scene_to_packed(SaveFileData.scene)
		await get_tree().process_frame
		await get_tree().process_frame
		var ui = get_tree().get_first_node_in_group("UI")
		ui.load_world()

func _load_profile() -> void:
	if FileAccess.file_exists(prof_location):
		ProfFileData = ResourceLoader.load(prof_location).duplicate(true)
		
		Global.tutorial = ProfFileData.tutorial
		Global.tutorialCharm = ProfFileData.tutorialCharm
		Global.tutorialDecree = ProfFileData.tutorialDecree
		
		Global.unlockedCards = ProfFileData.unlockedCards

		var ui = get_tree().get_first_node_in_group("UI")
		ui.master.value = ProfFileData.masterVol
		ui.music.value = ProfFileData.musicVol
		ui.sfx.value = ProfFileData.sfxrVol

func _reset_profile() -> void:
	if FileAccess.file_exists(prof_location):
		ProfFileData = ResourceLoader.load(prof_location).duplicate(true)
		
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
