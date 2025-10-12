extends Node

const save_location = "res://saves/SaveFile.tres"

var SaveFileData : SaveDataResource = SaveDataResource.new()

func _save(scene : PackedScene, rollArray : Array, walls : PackedByteArray,
		ground : PackedByteArray, obstacles : PackedByteArray, ring : PackedByteArray ):
	SaveFileData.scene = scene
	SaveFileData.nights = Global.nights
	SaveFileData.rolls = rollArray
	SaveFileData.walls = walls
	SaveFileData.ground = ground
	SaveFileData.obstacles = obstacles
	SaveFileData.ring = ring
	
	# save cards
	SaveFileData.cardsInHand.clear()
	for card in Global.cardsInHand:
		var dupe = load("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = card.type
		dupe.level = card.level
		dupe.charm = card.charm
		print(card.type)
		SaveFileData.cardsInHand.append(dupe)
		dupe.for_show = false
	
	ResourceSaver.save(SaveFileData,save_location)
	
func _load() :
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)
		
		get_tree().change_scene_to_packed(SaveFileData.scene)
		await get_tree().process_frame
		await get_tree().process_frame
		var ui = get_tree().get_first_node_in_group("UI")
		ui.load_world()
