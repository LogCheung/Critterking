extends CanvasLayer
class_name UI

signal game_over

@onready var cards: Control = %Cards
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hand: Control = %Hand
@onready var mainmenu: Control = %mainmenu
@onready var help: Control = %Help
@onready var settings: Control = %Settings
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var end_turn: Control = %EndTurn
@onready var gameover: Control = %gameover
@onready var pausemenu: Control = %pausemenu
@onready var crtr_day: AudioStreamPlayer = %crtrDay
@onready var crtr_night: AudioStreamPlayer = %crtrNight
@onready var crtr_pause: AudioStreamPlayer = %crtrPause
@onready var dispatch: Control = %Dispatch
@onready var decrees: Control = %Decrees
@onready var night_counter: Control = %NightCounter
@onready var songs : Array = get_tree().get_nodes_in_group("MUSIC")

@export var rollArray : Array = []

var rolltype : Card.ROLLTYPE
var extraRolls : int = 0
var rollingExtraTime : bool = false
var displaying_cards : bool = false

var dispatchAmt = 0
var dispatchLimit = 1

func _process(delta: float) -> void:
	Global.cardsInHand = hand.get_child(0).get_children()
	if mainmenu.visible and !%crtrMenu.playing:
		play_song(%crtrMenu)
	elif settings.visible and !%crtrPause.playing:
		play_song(%pausemenu)
	elif help.visible and !%crtrPause.playing:
		play_song(%pausemenu)
	elif end_turn.visible and !%crtrDay.playing:
		play_song(%crtrDay)
	elif !end_turn.visible and !%crtrNight.playing and !control_is_visible():
		play_song(%crtrNight)
	%DayNight.text = str(Global.nights)
		
func _ready() -> void:
	# connect signals
	game_over.connect(on_game_over)
	# hide all but show main menu
	for c in get_children():
		if !c is Control: continue
		c.hide()
	mainmenu.show()
	


func play_song(song : AudioStreamPlayer) -> void:
	for s : AudioStreamPlayer in songs:
		s.stop()
	song.play()

func control_is_visible() -> bool:
	for c in get_children():
		if !c is Control: continue
		if c == %NightCounter or c == %Decrees : continue
		if c.visible : return true
	return false
	
func display_cards(display : bool) -> void:
	# after deck of cards is clicked and frame 18 of the anim
	displaying_cards = true
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	for card : Card in cardSprites:
		if !card.for_show : continue
		card.rolltype = rolltype
		card.randomize_type()
		card.visible = display
		card.choice_picked = !display
	
	%Card3.visible = rolltype == Card.ROLLTYPE.CHARM and display
		
func show_hand() -> void:
	# when card is chosen from deck of cards
	rollArray.pop_front()
	if rollArray.size() > 0:
		cards.show()
		displaying_cards = false
		return
	
	cards.hide()
	hand.show()
	end_turn.show()
	decrees.show()
	night_counter.show()
	displaying_cards = false
	var container = %Hand.get_child(0) # Hboxcontainer
	await get_tree().create_timer(.05).timeout
	for c : Card in container.get_children():
		c.set_up()
		c.refreshing = true
	
	if world.dispatchDay: dispatch.show()
	
	refresh_positions()
	#_on_save_pressed()

func on_game_over() -> void:
	hand.hide()
	gameover.show()
	
	%over.texture = load("res://UI/Assets/menus/gameover.png")
	%nights.visible = true
	$AnimationPlayer.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()
	%nights.text = str(Global.nights)

func victory() -> void:
	hand.hide()
	gameover.show()
	
	%over.texture = load("res://UI/Assets/menus/gwj2win.png")
	%nights.visible = false
	anim.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()

func _on_show_pressed() -> void:
	# when deck of cards is clicked, show anim will play
	if displaying_cards : return
	#await get_tree().create_timer(.05).timeout
	
	if anim.is_playing():return
	rolltype = rollArray.front()
	%Shuffle.play()
	
	if rolltype == Card.ROLLTYPE.CHARM:
		%CardShow.texture = preload("res://UI/Assets/menus/discoveryshow.png")
		%CardShow.hframes = 20
		if !Global.cardsDispatched.is_empty() : 
			%Card3.type = Global.cardsDispatched.front().type
		%Card3.match_sprite_type()
	
	else:
		%CardShow.texture = preload("res://UI/Assets/menus/cardshow.png")
		%CardShow.hframes = 20
	anim.play("cardshow")


func _on_play_pressed() -> void:
	if anim.is_playing() : return
	%Button.play()
	$AnimationPlayer.play("MainToGame")
	world.new_game()
	await anim.animation_finished
	%crtrMenu.stop()
	mainmenu.hide()
	world.start_day()
	%crtrDay.play()
	$AnimationPlayer.play("RESET")


func _on_help_pressed() -> void:
	%Button.play()
	if !%crtrPause.playing:
		%crtrPause.play()
	%crtrMenu.stop()
	help.show()
	mainmenu.hide()

func _on_settings_pressed() -> void:
	%Button.play()
	if !%crtrPause.playing:
		%crtrPause.play()
	%crtrMenu.stop()
	settings.show()
	mainmenu.hide()
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_backhelp_pressed() -> void:
	%Button.play()
	help.hide()
	if !pausemenu.visible:
		mainmenu.show()
	pass # Replace with function body.

func _on_settingsback_pressed() -> void:
	%Button.play()
	settings.hide()
	if !pausemenu.visible:
		mainmenu.show()
	pass # Replace with function body.

func _on_endturn_pressed() -> void:
	# check if house is not placed
	%Button.play()
	for card : Card in Global.cardsInHand:
		if card.type == Card.CARDTYPE.HOUSE: 
			%noHouse.show()
			return
	var units = get_tree().get_nodes_in_group("ALLY")
	for u:Ally in units:
		u.healthchange.emit()
		u.speedchange.emit()
	world.night_started.emit()
	%noHouse.hide()

func _on_newgame_pressed() -> void:
	$AnimationPlayer.play("playAgain")
	await anim.animation_finished
	%crtrOver.stop()
	gameover.hide()
	world.new_game()
	await anim.animation_finished
	world.start_day()
	%crtrDay.play()
	$AnimationPlayer.play("RESET")

func _on_title_pressed() -> void:
	%Button.play()
	mainmenu.show()
	$AnimationPlayer.play("LoseToTitle")
	await anim.animation_finished
	%crtrOver.stop()
	gameover.hide()
	%crtrMenu.play()
	$AnimationPlayer.play("RESET")

func _on_continue_pressed() -> void:
	%Button.play()
	handle_pause()

func _on_dispatch_end_pressed() -> void:
	dispatch.hide()
	dispatchAmt = 0
	
	var cards = get_tree().get_nodes_in_group("CARD")
	for c : Card in cards:
		if c.dispatchSelected:
			var newCard = preload("res://UI/Scenes/card.tscn").instantiate()
			newCard.type = c.type
			newCard.level = c.level
			Global.cardsDispatched.append(newCard)
			c.queue_free()
			
func refresh_positions() -> void:
	# Add and remove dummy card to refresh positions
	var hCard : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	hand.get_child(0).add_child(hCard)
	#hCard.set_owner(get_tree().get_current_scene())
	hCard.set_up()
	hCard.remove_self()
	
	var cardsInHand = hand.get_child(0).get_children()
	for c : Card in cardsInHand:
		c.set_up()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		handle_pause()
func handle_pause() -> void:
	if mainmenu.visible or gameover.visible or help.visible or settings.visible : return
	if pausemenu.visible:
		world.game.process_mode = Node.PROCESS_MODE_PAUSABLE
		crtr_pause.stop()
		pausemenu.hide()
		if world.is_combat_phase == false: end_turn.show()
		if world.is_combat_phase == true: crtr_night.play()
		return
	world.game.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pausemenu.show()
	end_turn.hide()
	get_tree().call_group("MUSIC", "stop")
	crtr_pause.play()


func _on_save_pressed() -> void:
	var scene = PackedScene.new()
	scene.pack(world)
	
	var walls = world.tileWorld.wall.tile_map_data
	var ground = world.tileWorld.ground.tile_map_data
	var obstacles = world.tileWorld.obstacles.tile_map_data
	var ring = world.tileWorld.ring.tile_map_data
	
	SaveLoad._save(scene,rollArray,walls,ground,obstacles,ring)
	#ResourceSaver.save(scene,"res://saves/savefile.tscn")

func _on_load_pressed() -> void:
	SaveLoad._load()

func load_world() -> void:
	# clear dead allies
	for unit : Ally in get_tree().get_nodes_in_group("ALLY"):
		if unit.dead or !unit.group: unit.queue_free()
	
	# load data from save
	world.game.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.create_enemy_perimeter(12 + Global.expansions, true)
	world.create_enemy_perimeter(11 + Global.expansions, false)
	mainmenu.hide()
	night_counter.show()
	end_turn.show()
	hand.show()
	decrees.show()
	
	world.tileWorld.wall.tile_map_data = SaveLoad.SaveFileData.walls
	world.tileWorld.ground.tile_map_data = SaveLoad.SaveFileData.ground
	world.tileWorld.obstacles.tile_map_data = SaveLoad.SaveFileData.obstacles
	world.tileWorld.ring.tile_map_data  = SaveLoad.SaveFileData.ring
	Global.nights = SaveLoad.SaveFileData.nights
	
	# load cards
	for card : Card in SaveLoad.SaveFileData.cardsInHand:
		var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = card.type
		Global.cardsInHand.append(dupe)
		dupe.for_show = false
		hand.get_child(0).add_child(dupe) # container
		dupe.set_owner(get_tree().get_current_scene())
	await get_tree().process_frame
	for card : Card in hand.get_child(0).get_children():
		card.set_up()
		
	# verify data of units
	world.tileWorld.set_up_astar()
	for unit in get_tree().get_nodes_in_group("ALLY"):
		unit._ready()
	#if !FileAccess.file_exists("res://saves/savefile.tscn"):
		#return
	#else:
		#var new_scene = ResourceLoader.load("res://saves/savefile.tscn")
		#get_tree().change_scene_to_packed(new_scene)
