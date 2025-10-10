extends Node

const save_location = "res://saves/SaveFile.tres"

var SaveFileData : SaveDataResource = SaveDataResource.new()

func _save(scene : PackedScene):
	SaveFileData.gameScene = scene
	ResourceSaver.save(SaveFileData,save_location)
	
func _load() :
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)
		
		var big : Big = get_tree().get_first_node_in_group("BIG")
		big.world.queue_free()
		
		var newWorld : World = SaveFileData.gameScene.instantiate()
		newWorld.loading = true
		big.world = newWorld
		big.add_child(newWorld)
		big.ui.world = newWorld
		big.ui.mainmenu.hide()
