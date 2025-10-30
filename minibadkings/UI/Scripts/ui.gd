extends CanvasLayer
class_name UI

signal game_over

# for tutorial purposes
signal card_placed
signal ally_died
signal unit_healed

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
@onready var party_current: Label = %PartyCurrent
@onready var party_limit: Label = %PartyLimit
@onready var no_space: TextureRect = %noSpace
@onready var master: HSlider = %Master
@onready var music: HSlider = %Music
@onready var sfx: HSlider = %SFX
@onready var unlock: Sprite2D = %unlock
@onready var hand_container: HBoxContainer = %HandContainer

@export var rollArray : Array = []

var rolltype : Card.ROLLTYPE
var extraRolls : int = 0
var rollingExtraTime : bool = false
var displaying_cards : bool = false

var dispatchAmt = 0
var dispatchLimit = 1

func _process(delta: float) -> void:
	Global.cardsInHand = hand_container.get_children()
	if mainmenu.visible and !%crtrMenu.playing:
		play_song(%crtrMenu)
	elif settings.visible and !%crtrPause.playing:
		play_song(%crtrPause)
	elif help.visible and !%crtrPause.playing:
		play_song(%crtrPause)
	elif end_turn.visible and !%crtrDay.playing:
		play_song(%crtrDay)
	elif !end_turn.visible and !%crtrNight.playing and !control_is_visible():
		play_song(%crtrNight)
	%DayNight.text = str(Global.nights)
	world.handle_party_limit()
	
	%ScrollControl.custom_minimum_size.x = 128 * hand_container.get_children().size()
	%ScrollControl.custom_minimum_size.x += 20 * hand_container.get_children().size() - 1
		
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
	save_game_delayed()
	rollArray.pop_front()
	if rollArray.size() > 0:
		cards.show()
		displaying_cards = false
		return
	
	cards.hide()
	%Tutorial.hide()
	
	hand.show()
	end_turn.show()
	decrees.show()
	night_counter.show()
	displaying_cards = false
	await get_tree().create_timer(.05).timeout
	for c : Card in hand_container.get_children():
		c.set_up()
		c.refreshing = true
	
	if world.dispatchDay: 
		dispatch.show()
	
	refresh_positions()
	
	if world.dispatchDay and Global.tutorialCharm:
		%Tutorial.show()
		%TutorialTitle.text = "Discoveries"
		%TutorialText.text = "Units sent out will be disabled for a night, but will come back tomorrow with an upgrade"
		%TutorialText.text += "\n\nYou can continue without selecting if you choose."
		Global.tutorialCharm = false
		return
	
	if Global.tutorial:
		%Tutorial.show()
		%TutorialTitle.text = "Placing"
		%TutorialText.text = "Place your cards by dragging them from your hand onto the map!"
		%TutorialText.text += "\n\nIf you have two of the same unit card, you can merge them!"
		
		await card_placed
		await card_placed
		
		%TutorialTitle.text = "Unit Types"
		%TutorialText.text = "Units tend to fall into categories, offensive, defensive, and ranged"
		%TutorialText.text += "\n\nDuring battle, strategize carefully to ensure a favorable matchup!"
		
		await card_placed
		%TutorialTitle.text = "Camera"
		%TutorialText.text = "\nUse WASD to move your camera. Hold down shift to speed up the camera!"

func save_game_delayed() -> void:
	for i in range(5):
		await get_tree().process_frame
	_on_save_pressed()

func on_game_over() -> void:
	hand.hide()
	gameover.show()
	
	%over.texture = load("res://UI/Assets/menus/gameover.png")
	%endless.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	%nights.visible = true
	$AnimationPlayer.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()
	%nights.text = str(Global.nights)

func victory() -> void:
	Global.wins += 1
	_on_save_pressed()
	hand.hide()
	gameover.show()
	
	%over.texture = load("res://UI/Assets/menus/gwj2win.png")
	%endless.process_mode = Node.PROCESS_MODE_INHERIT
	%nights.visible = false
	anim.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()

func _on_endless_pressed() -> void:
	%gameover.hide()
	hand.show()
	end_turn.show()
	pass # Replace with function body.

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
		
		# tutorial for decrees
		if rolltype == Card.ROLLTYPE.BLESSING and Global.tutorialDecree:
			%Tutorial.show()
			%TutorialTitle.text = "Decrees"
			%TutorialText.text = "Decrees are [color=yellow]active[/color] abilities that can be used during the night."
			%TutorialText.text += "\n\nOnce used they will be on cooldown for a number of nights but can greatly help your defense."
			%TutorialText.text += "\n\nAfter picking one, they will be displayed on the left."
			Global.tutorialDecree = false
			pass
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

	if Global.tutorial:
		%Tutorial.show()
		%TutorialTitle.text = "Cards"
		%TutorialText.text = "Every night you will be able to draw a card, click the deck and make your selection!"
		%TutorialText.text += "\n\nThe first night you will be able draw twice!"

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
	if pausemenu.visible:
		world.clear_world()
		get_tree().change_scene_to_file("res://World/Scenes/world.tscn")
		return
	SaveLoad._save_profile(self)
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
	if %DisableTutorial.button_pressed:
		Global.tutorial = false
		Global.tutorialCharm = false
		Global.tutorialDecree = false
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
	
	if Global.tutorial:
		%Tutorial.show()
		%TutorialTitle.text = "Commanding"
		%TutorialText.text = "Click on a unit group to select them! [color=yellow]Click a tile to move the group there.[/color]"
		%TutorialText.text += "\n\nEnemies will approach from all sides,[color=red] keep your houses safe[/color]!"
		%TutorialText.text += "\n\nMove your units, defeat enemies, survive!"
		await get_tree().create_timer(15).timeout
		
		%TutorialTitle.text = "Healing"
		%TutorialText.text = "If one of your unit groups has lost units. Click on them and click on your house to heal them."
		%TutorialText.text += "\n\nBe careful as they will be temporarily out of the battle."
		
		await world.night_ended
		%Tutorial.hide()
		Global.tutorial = false

func _on_newgame_pressed() -> void:
	Global.nights = 0
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
	world.dispatchDay = false
	dispatch.hide()
	dispatchAmt = 0
	
	var cardsInHand = get_tree().get_nodes_in_group("CARD")
	for c : Card in cardsInHand:
		if c.dispatchSelected:
			var newCard = preload("res://UI/Scenes/card.tscn").instantiate()
			newCard.type = c.type
			newCard.level = c.level
			Global.cardsDispatched.append(newCard)
			c.queue_free()
	
	refresh_positions()
	
func refresh_positions() -> void:
	# Add and remove dummy card to refresh positions
	var hCard : Card = preload("res://UI/Scenes/card.tscn").instantiate()
	hand_container.add_child(hCard)
	#hCard.set_owner(get_tree().get_current_scene())
	hCard.set_up()
	hCard.remove_self()
	
	var cardsInHand = hand_container.get_children()
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
	#return # disable saving
	world = get_tree().get_first_node_in_group("WORLD")
	var scene = PackedScene.new()
	scene.pack(world)
	
	var walls = world.tileWorld.wall.tile_map_data
	var ground = world.tileWorld.ground.tile_map_data
	var obstacles = world.tileWorld.obstacles.tile_map_data
	var ring = world.tileWorld.ring.tile_map_data
	
	SaveLoad._save(scene,rollArray,walls,ground,obstacles,ring,world.dispatchDay)
	
	# Save profile data
	SaveLoad._save_profile(self)
	
	#ResourceSaver.save(scene,"res://saves/savefile.tscn")

func _on_load_pressed() -> void:
	SaveLoad._load()

func load_world() -> void:
	# clear dead allies
	for unit : Ally in get_tree().get_nodes_in_group("ALLY"):
		if unit.dead or !unit.group: unit.queue_free()
	
	# load data from save
	world.on_night_ended()
	world.game.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.create_enemy_perimeter(12 + Global.expansions, true)
	world.create_enemy_perimeter(11 + Global.expansions, false)
	mainmenu.hide()
	night_counter.show()
	end_turn.show()
	hand.show()
	decrees.show()
	
	Global.cardsDispatched.clear()
	world.tileWorld.wall.tile_map_data = SaveLoad.SaveFileData.walls
	world.tileWorld.ground.tile_map_data = SaveLoad.SaveFileData.ground
	world.tileWorld.obstacles.tile_map_data = SaveLoad.SaveFileData.obstacles
	world.tileWorld.ring.tile_map_data  = SaveLoad.SaveFileData.ring
	world.dispatchDay = SaveLoad.SaveFileData.dispatchDay
	Global.nights = SaveLoad.SaveFileData.nights
	rollArray = SaveLoad.SaveFileData.rolls
	
	# load cards
	for card : Card in SaveLoad.SaveFileData.cardsInHand:
		var dupe : Card = preload("res://UI/Scenes/card.tscn").instantiate()
		dupe.type = card.type
		dupe.level = card.level
		dupe.charm = card.charm
		
		Global.cardsInHand.append(dupe)
		dupe.for_show = false
		hand_container.add_child(dupe) # container
		dupe.set_owner(get_tree().get_current_scene())
		
		if dupe.charm : 
			dupe.charm_pos.add_child(dupe.charm)
			dupe.charm.set_owner(get_tree().get_current_scene())
	await get_tree().process_frame
	for card : Card in hand_container.get_children():
		card.set_up()
		
	# load decrees
	for d : Decree in SaveLoad.SaveFileData.decreesEquipped:
		var dupe : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
		dupe.type = d.type
		dupe.time = d.time
		dupe.cooldown = d.cooldown
		%DecreeContainer.add_child(dupe)
	
	
	
	# verify data of units
	world.tileWorld.set_up_astar()
	for unit in get_tree().get_nodes_in_group("ALLY"):
		unit._ready()
		
	if !rollArray.is_empty():
		cards.show()
		hand.hide()
		end_turn.hide()
	elif world.dispatchDay:
		dispatch.show()
	#if !FileAccess.file_exists("res://saves/savefile.tscn"):
		#return
	#else:
		#var new_scene = ResourceLoader.load("res://saves/savefile.tscn")
		#get_tree().change_scene_to_packed(new_scene)


func _on_mainmenu_mouse_entered() -> void:
	# check if main menu in on screen
	if %unlock.visible: return
	if Global.wins -1 > Global.UNLOCK.size() or Global.wins <= 0 : return
	if Global.unlockedCards.has(Global.UNLOCK[Global.wins - 1][0]): return
	%unlock.visible = true
	anim.play("cardunlock")
	pass # Replace with function body.

func show_unlocks() -> void:
	var unlockCards = mainmenu.get_children()
	unlockCards = unlockCards.filter(func(e):return e is Card)
	var i : int  = 0 
	for card : Card in unlockCards:
		card.visible = true
		card.type = Global.UNLOCK[Global.wins - 1][i]
		card.match_sprite_type()
		
		Global.unlockedCards.append(Global.UNLOCK[Global.wins - 1][i])
		i += 1

func hide_unlocks() -> void:
	var unlockCards = mainmenu.get_children()
	unlockCards = unlockCards.filter(func(e):return e is Card)
	var i : int  = 0 
	for card : Card in unlockCards:
		card.visible = false
	unlock.hide()
