extends CanvasLayer
class_name UI

signal game_over

enum CHALLENGE {
	NONE, JUICED, DOUBLETROUBLE, TOWERDEFENSE, MINIMALIST, CEASELESSWAR
}

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
@onready var info_overlay: InfoOverlay = %InfoOverlay
@onready var songs : Array = get_tree().get_nodes_in_group("MUSIC")
@onready var no_space: TextureRect = %noSpace
@onready var master: HSlider = %Master
@onready var music: HSlider = %Music
@onready var sfx: HSlider = %SFX
@onready var unlock: Sprite2D = %unlock
@onready var hand_container: HBoxContainer = %HandContainer
@onready var settB = settings.get_children()
@onready var ascensions: Control = %ascensions
@onready var shop: Control = %Shop
@onready var inspect_card: InspectControl = %InspectCard
@onready var tutorial: Tutorial = %Tutorial

@export var rollArray : Array = []
@export var currentAscn : int = 0
@export var currentChal : CHALLENGE = CHALLENGE.NONE

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
	info_overlay.handle_party_limit()
	
	%ScrollControl.custom_minimum_size.x = 128 * hand_container.get_children().size()
	%ScrollControl.custom_minimum_size.x += 20 * hand_container.get_children().size() - 1
		
func _ready() -> void:
	#get settings menu
	settB.append_array(%settingsMenu.get_children())
	settB = settB.filter(func(b):return b != %settingsback)
	settB = settB.filter(func(b):return b != %settingsMenu)
	settB = settB.filter(func(b):return b != %creditsB)
	%settingsMenu.frame = 3
	# connect signals
	game_over.connect(on_game_over)
	# hide all but show main menu
	for c in get_children():
		if !c is Control: continue
		c.hide()
	%playmenu.hide()
	ascensions.hide()
	mainmenu.show()
	
	# resource and trait labels
	info_overlay._update_resources()
	info_overlay._update_traits()
	
func play_song(song : AudioStreamPlayer) -> void:
	for s : AudioStreamPlayer in songs:
		s.stop()
	song.play()

func control_is_visible() -> bool:
	for c in get_children():
		if !c is Control: continue
		if c == info_overlay or c == %Decrees : continue
		if c.visible : return true
	return false
	
func _on_show_pressed() -> void:
	print(rollArray)
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
		tutorial.play_decrees_tutorial()
	anim.play("cardshow")
	
func display_cards(display : bool) -> void:
	# after deck of cards is clicked and frame 18 of the anim
	displaying_cards = true
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	for card : Card in cardSprites:
		if !card.for_show : continue
		if card.shop_card : continue
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
		if rollArray.front() == Card.ROLLTYPE.SHOP:
			cards.hide()
			display_shop()
			return
		cards.show()
		displaying_cards = false
		return
	
	cards.hide()
	
	tutorial.play_charms_tutorial()
	tutorial.play_day_basics_tutorial()

func display_shop() -> void:
	shop.show()
	for slot : CardPurchaseSlot in get_tree().get_nodes_in_group("CARDPURCHASE"):
		slot.card.visible = true
		slot.card.randomize_type()
		slot.price_label.visible = true

func display_hand() -> void:
	#%Tutorial.hide()
	
	hand.show()
	end_turn.show()
	decrees.show()
	info_overlay.show()
	displaying_cards = false
	await get_tree().create_timer(.05).timeout
	for c : Card in hand_container.get_children():
		c.set_up()
		c.refreshing = true
	
	if world.dispatchDay: 
		dispatch.show()
	
	refresh_positions()

func _on_shop_end_pressed() -> void:
	rollArray.pop_front()
	save_game_delayed()
	shop.hide()
	info_overlay._update_resources()
	display_hand()
	
	tutorial.play_charms_tutorial()
	tutorial.play_day_basics_tutorial()

func save_game_delayed() -> void:
	for i in range(5):
		if !get_tree(): break
		await get_tree().process_frame
	_on_save_pressed()

func on_game_over() -> void:
	# not clearing correctly, remove entities to keep files safe
	world.on_night_ended()
	hand.hide()
	end_turn.hide()
	info_overlay.hide()
	decrees.hide()
	cards.hide()
	
	gameover.show()
	%Tutorial.hide()
	%over.texture = load("res://UI/Assets/menus/gameover.png")
	%endless.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	%nights.visible = true
	$AnimationPlayer.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()
	%nights.text = str(Global.nights - 1)
	
	await get_tree().create_timer(.125).timeout
	_on_save_pressed(true)

func victory() -> void:
	if currentChal == CHALLENGE.NONE: Global.wins += 1
	if currentAscn == Global.maxAscension: Global.maxAscension += 1
	
	hand.hide()
	end_turn.hide()
	%Tutorial.hide()
	info_overlay.hide()
	gameover.show()
	
	%over.texture = load("res://UI/Assets/menus/gwj2win.png")
	%endless.process_mode = Node.PROCESS_MODE_INHERIT
	%nights.visible = false
	anim.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrWin.play()
	match_challenge_unlock()
	_on_save_pressed()

func match_challenge_unlock() -> void:
	match currentChal:
		CHALLENGE.NONE:
			return
		CHALLENGE.JUICED:
			if !Global.unlockedCards.has(Card.CARDTYPE.EDRINK):
				%unlockC.show()
		CHALLENGE.MINIMALIST:
			if !Global.unlockedCards.has(Card.CARDTYPE.DOLLHOUSE):
				%unlockC.show()
		CHALLENGE.TOWERDEFENSE:
			if !Global.unlockedCards.has(Card.CARDTYPE.FORTITUDE):
				%unlockC.show()

func _on_endless_pressed() -> void:
	if %unlock.visible: return
	if Global.wins -1 > Global.UNLOCK.size() or Global.wins <= 0 : return
	if Global.unlockedCards.has(Global.UNLOCK[Global.wins - 1][0]): return
	%unlock.visible = true
	%gameover.hide()
	end_turn.show()
	info_overlay.show()
	pass # Replace with function body.



func _on_play_pressed() -> void:
	if anim.is_playing() : return
	info_overlay.show_containers()
	info_overlay.show()
	%Button.play()
	$AnimationPlayer.play("MainToGame")
	Global.nights = 0
	world.new_game()
	
	await anim.animation_finished
	%crtrMenu.stop()
	mainmenu.hide()
	world.start_day()
	gameover.hide()
	%crtrDay.play()
	$AnimationPlayer.play("RESET")
	
	# ascension 
	%AdaptLabel.text = str(currentAscn)
	tutorial.play_card_tutorial()
func _on_play_menu_pressed() -> void:
	%mainsprite.hide()
	%playmenu.show()
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
	%settingsMenu.frame = 3
	mainmenu.hide()
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	if pausemenu.visible:
		world.clear_world()
		world.clear_entities()
		get_tree().change_scene_to_file("res://World/Scenes/world.tscn")
		return
	
	world.clear_entities()
	await get_tree().create_timer(.125).timeout
	SaveLoad._save_profile(self)
	get_tree().quit()

# Help Menu
func _on_backhelp_pressed() -> void:
	%Button.play()
	help.hide()
	if !pausemenu.visible:
		mainmenu.show()

func _on_forward_pressed() -> void:
	%Button.play()
	if %Help/help.frame == 0: %Help/help.frame += 1
	else: %Help/help.frame -= 1


# Settings Menu

func _on_settingsback_pressed() -> void:
	%Button.play()
	if %settingsMenu.frame == 3: 
		settings.hide()
		if !pausemenu.visible: mainmenu.show()
	else:
		for b in settB: b.hide()
		%settingsMenu.frame = 3
		%audioB.show()
		%videoB.show()
		%gameplayB.show()
	if %DisableTutorial.button_pressed:
		Global.tutorial = true
		Global.tutorialCharm = true
		Global.tutorialDecree = true
	else:
		Global.tutorial = false
		Global.tutorialCharm = false
		Global.tutorialDecree = false

func _on_audio_b_pressed() -> void:
	for b in settB: b.hide()
	%settingsMenu.frame = 0
	%Master.show()
	%Music.show()
	%SFX.show()


func _on_video_b_pressed() -> void:
	for b in settB: b.hide()
	%settingsMenu.frame = 1
	%resolution.show()
	%format.show()


func _on_gameplay_b_pressed() -> void:
	for b in settB: b.hide()
	%settingsMenu.frame = 2
	%DisableTutorial.show()
	%camSpeed.show()

func _on_credits_b_pressed() -> void:
	%settingsMenu.frame = 4
	for b in settB: b.hide()

func _on_cam_speed_value_changed(new_value: float) -> void:
	world.camera.move_speed = new_value


	#Daytime Menu
	
func _on_endturn_pressed() -> void:
	# hide assign mode
	if info_overlay.assignMode:
		var event : InputEventAction = InputEventAction.new()
		event.action = "select"
		info_overlay._on_assign_toggle_gui_input(event)
	# hide dispatch
	if dispatch.visible: 
		_on_dispatch_end_pressed()
		return
	# run colony buildings
	for b : ColonyBuilding in get_tree().get_nodes_in_group("COLONY"):
		b.day_ended.emit()
		
	info_overlay._update_resources()
	
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
	
	tutorial.play_command_heal_tutorial()

func _on_newgame_pressed() -> void:
	if anim.is_playing() : return
	Global.nights = 0
	anim.play("playAgain")
	world.new_game()
	
	await anim.animation_finished
	
	%crtrOver.stop()
	gameover.hide()
	world.start_day()
	%crtrDay.play()
	$AnimationPlayer.play("RESET")
	
	
	# ascension 
	%AdaptLabel.text = str(currentAscn)
	

func _on_title_pressed() -> void:
	%Button.play()
	mainmenu.show()
	gameover.hide()
	$AnimationPlayer.play("LoseToTitle")
	await anim.animation_finished
	%crtrOver.stop()
	%crtrMenu.play()
	$AnimationPlayer.play("RESET")
	_on_mainmenu_mouse_entered()

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

func _on_back_pressed() -> void:
	%playmenu.hide()
	%mainsprite.show()

# lights for play menu
func _on_adapt_pressed() -> void:
	if anim.is_playing() : return
	%ascensions.show()
	pass

func _on_adapt_mouse_entered() -> void:
	%playmenu.frame = 3
	pass # Replace with function body.

func _on_button_mouse_exited() -> void:
	%playmenu.frame = 0
	pass # Replace with function body.

func _on_load_mouse_entered() -> void:
	%playmenu.frame = 2

func _on_play_mouse_entered() -> void:
	%playmenu.frame = 1

# ascn menu
func _on_ascnback_pressed() -> void:
	%ascensions.hide()
	pass # Replace with function body.


func _on_resolution_item_selected(index: int) -> void:
	if get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		return
	match index:
		0:
			get_window().size = Vector2i(1920,1080)
		1:
			get_window().size = Vector2i(1600,900)
		2:
			get_window().size = Vector2i(1280,720)

func _on_format_item_selected(index: int) -> void:
	match index:
		0:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		1:
			get_window().mode = Window.MODE_WINDOWED
		2:
			get_window().mode = Window.MODE_FULLSCREEN
			get_window().borderless = true


func _on_unlock_c_button_pressed() -> void:
	if anim.is_playing():return
	if !%Card4.visible:
		anim.play("unlockC")
	

func _on_unlock_button_pressed() -> void:
	if anim.is_playing():return
	if !%Card4.visible:
		anim.play("cardunlock")
	
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
	if %Card7.visible and %unlockC.visible and event.is_action_pressed("select"):
		anim.play("unlockChide")
		await anim.animation_finished
		%unlockC.hide()
		%Card7.hide()
	if %Card4.visible and unlock.visible and event.is_action_pressed("select"):
		anim.play("cardunlockhide")
		hide_unlocks()
		await anim.animation_finished
		unlock.hide()
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


func _on_save_pressed(lost : bool = false) -> void:
	if pausemenu.visible: return
	
	world.clear_entities()
	# pause buildings
	for b in get_tree().get_nodes_in_group("BUILDING"):
		b.process_mode = Node.PROCESS_MODE_DISABLED
	
	# delay
	for i in range(5):
		if !get_tree() : break
		await get_tree().process_frame
	#return # disable saving
	world = get_tree().get_first_node_in_group("WORLD")
	
	var walls = world.tileWorld.wall.tile_map_data
	var ground = world.tileWorld.ground.tile_map_data
	var obstacles = world.tileWorld.obstacles.tile_map_data
	var ring = world.tileWorld.ring.tile_map_data
	var defeated = lost
	
	Global.decreesEquipped.clear()
	for d in %DecreeContainer.get_children():
		if !d is Decree : continue
		Global.decreesEquipped.append(d)
	
	SaveLoad._save(#scene,
	rollArray,walls,ground,obstacles,
	ring,world.dispatchDay,defeated,currentAscn,currentChal)
	
	# Save profile data
	SaveLoad._save_profile(self)
	
	#unpause buildings
	for b in get_tree().get_nodes_in_group("BUILDING"):
		b.process_mode = Node.PROCESS_MODE_INHERIT

func _on_load_pressed() -> void:
	if anim.is_playing() : return
	SaveLoad._load()

func load_world() -> void:
	# clear dead allies
	for unit : Ally in get_tree().get_nodes_in_group("ALLY"):
		if unit.dead or !unit.group: unit.queue_free()
	
	# load data from save
	currentChal = SaveLoad.SaveFileData.challenge
	currentAscn = SaveLoad.SaveFileData.ascension
	world.on_night_ended()
	world.game.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.create_enemy_perimeter(12 + Global.expansions, true)
	world.create_enemy_perimeter(11 + Global.expansions, false)
	
	mainmenu.hide()
	info_overlay.show()
	end_turn.show()
	hand.show()
	decrees.show()
	
	Global.cardsDispatched.clear()
	if rollArray.has(Card.ROLLTYPE.CHARM) : rollArray.remove_at(rollArray.find(Card.ROLLTYPE.CHARM))
	world.tileWorld.wall.tile_map_data = SaveLoad.SaveFileData.walls
	world.tileWorld.ground.tile_map_data = SaveLoad.SaveFileData.ground
	world.tileWorld.obstacles.tile_map_data = SaveLoad.SaveFileData.obstacles
	world.tileWorld.ring.tile_map_data  = SaveLoad.SaveFileData.ring
	world.dispatchDay = SaveLoad.SaveFileData.dispatchDay
	Global.nights = SaveLoad.SaveFileData.nights
	Global.expansions = SaveLoad.SaveFileData.expansions
	rollArray = SaveLoad.SaveFileData.rolls
	
	Global.resource_dict = SaveLoad.SaveFileData.resource_dict.duplicate()
	Global.trait_dict = SaveLoad.SaveFileData.trait_dict.duplicate()
	
	# reset workers to zero, buildings will correctly set workers on their own
	Global.resource_dict[Global.RESOURCETYPE.WORKER] = 0
	
	info_overlay._update_resources()
	info_overlay._update_traits()
	
	# load enemy party count
	world.enemy_parties = int(Global.nights / 2) + 3
	world.upgraded_parties = int(Global.nights / 4)
	world.night_is_expansion = Global.nights % 6 == 0
	
	world.tileWorld.draw_build_area()
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
		
	# load decrees
	for d : Decree in SaveLoad.SaveFileData.decreesEquipped:
		var dupe : Decree = load("res://UI/Scenes/decree.tscn").instantiate()
		dupe.type = d.type
		dupe.time = d.time
		dupe.cooldown = d.cooldown
		dupe.update_cooldown()
		%DecreeContainer.add_child(dupe)
	
	# load buildings
	for b : Building in SaveLoad.SaveFileData.buildings:
		var bNode = get_tree().get_first_node_in_group("BUILDINGSNODE")
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
		
		building.type = b.type
		building.global_position = b.global_position
		building.health = b.health
		building.time = b.time
		
		if isColony:
			building.workers = b.workers
			
		bNode.add_child(building)
		
		if b.active:
			building.toggle.button_pressed = true
	
	#Change time
	if currentChal == CHALLENGE.JUICED: Engine.time_scale = 2.5
	else: Engine.time_scale = 1
	
	info_overlay._update_resources()
	info_overlay._update_traits()

	# verify data of units
	world.tileWorld.set_up_astar()
	for unit in get_tree().get_nodes_in_group("ALLY"):
		unit._ready()
		
	if !rollArray.is_empty():
		info_overlay.hide()
		hand.hide()
		end_turn.hide()
		if rollArray.front() == Card.ROLLTYPE.CHARM: display_shop()
		elif rollArray.front() == Card.ROLLTYPE.SHOP: display_shop()
		else: cards.show()
	elif world.dispatchDay:
		dispatch.show()
		
	for b in get_tree().get_nodes_in_group("BUILDING"):
		b.process_mode = Node.PROCESS_MODE_INHERIT
	
	# load cards
	await get_tree().process_frame
	for card : Card in hand_container.get_children():
		card.set_up()
		
	%AdaptLabel.text = str(currentAscn)
	info_overlay.load_overlay()
	# load tileWorld data for restrictions
	world.tileWorld.find_restricted_tiles()
	world.tileWorld.find_blocked_entry_tiles()
	
	
# unlocking new cards
func _on_mainmenu_mouse_entered() -> void:
	# check if main menu in on screen
	if %unlock.visible: return
	if Global.wins > Global.UNLOCK.size() or Global.wins <= 0 : return
	if Global.unlockedCards.has(Global.UNLOCK[Global.wins - 1][0]): return
	%unlock.visible = true
	pass # Replace with function body.

func show_unlocks() -> void:
	if gameover.visible:
		%Card7.visible = true
		match currentChal:
			CHALLENGE.JUICED:
				%Card7.type = Card.CARDTYPE.EDRINK
			CHALLENGE.MINIMALIST:
				%Card7.type = Card.CARDTYPE.DOLLHOUSE
			CHALLENGE.TOWERDEFENSE:
				%Card7.type = Card.CARDTYPE.FORTITUDE
		%Card7.match_sprite_type()
		Global.unlockedCards.append(%Card7.type)
		SaveLoad._save_profile(self)
	if mainmenu.visible:
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
		card.type = Card.CARDTYPE.NONE
