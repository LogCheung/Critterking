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

var second_roll : bool = false
var rolltype : Card.ROLLTYPE
var extraRolls : int = 0
var rollingExtraTime : bool = false


func _process(delta: float) -> void:
	Global.cardsInHand = hand.get_child(0).get_children()
	if mainmenu.visible and !%crtrMenu.playing:
		%crtrPause.stop()
		%crtrOver.stop()
		%crtrDay.stop()
		%crtrNight.stop()
		%crtrMenu.play()
	elif settings.visible and !%crtrPause.playing:
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrDay.stop()
		%crtrNight.stop()
		%crtrPause.play()
	elif help.visible and !%crtrPause.playing:
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrDay.stop()
		%crtrNight.stop()
		%crtrPause.play()
	elif end_turn.visible and !%crtrDay.playing:
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrNight.stop()
		%crtrPause.stop()
		%crtrDay.play()
	elif !end_turn.visible and !%crtrNight.playing and !control_is_visible():
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrDay.stop()
		%crtrPause.stop()
		%crtrNight.play()
	%NightCounter.show()
	%DayNight.text = str(Global.nights)
		
func _ready() -> void:
	# connect signals
	game_over.connect(on_game_over)
	# hide all but show main menu
	for c in get_children():
		if !c is Control: continue
		c.hide()
	mainmenu.show()
	
func control_is_visible() -> bool:
	for c in get_children():
		if !c is Control: continue
		if c.visible : return true
	return false
	
func display_cards(display : bool) -> void:
	# when deck of cards is clicked
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	
	for card : Card in cardSprites:
		if !card.for_show : continue
		if world.starting_roll or second_roll:
			card.rolltype = Card.ROLLTYPE.UNIT
		else:
			card.rolltype = rolltype
		card.randomize_type()
		card.visible = display
		card.choice_picked = !display
		
	if rollingExtraTime:
		extraRolls -= 1
		
func show_hand() -> void:
	# when card is chosen from deck of cards
	if world.starting_roll:
		cards.show()
		world.starting_roll = false
		second_roll = true
		return
	if second_roll:
		second_roll = false
	if extraRolls > 0:
		rollingExtraTime = true
		return
	
	rollingExtraTime = false
	cards.hide()
	hand.show()
	var container = %Hand.get_child(0) # Hboxcontainer
	await get_tree().create_timer(.05).timeout
	for c : Card in container.get_children():
		c.set_up()
	#for card : Card in Global.cardsInHand:
		#container.add_child(card)

func on_game_over() -> void:
	gameover.show()
	$AnimationPlayer.play("Lose")
	await anim.animation_finished
	%crtrNight.stop()
	%crtrDay.stop()
	%crtrOver.play()
	%nights.text = str(Global.nights)

func _on_show_pressed() -> void:
	if anim.is_playing():return
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	
	for card : Card in cardSprites:
		if !card.for_show : continue
		if card.visible: return
	$Shuffle
	%Shuffle.play()
	anim.play("cardshow")


func _on_play_pressed() -> void:
	%Button.play()
	$AnimationPlayer.play("MainToGame")
	await anim.animation_finished
	%crtrMenu.stop()
	mainmenu.hide()
	world.new_game()
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
	pass # Replace with function body.


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
	var units = get_tree().get_nodes_in_group("UNIT")
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
	handle_pause()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		handle_pause()
func handle_pause() -> void:
	if mainmenu.visible or gameover.visible or help.visible or settings.visible : return
	if pausemenu.visible:
		%Game.process_mode = Node.PROCESS_MODE_PAUSABLE
		crtr_pause.stop()
		pausemenu.hide()
		if world.is_combat_phase == false: end_turn.show()
		if world.is_combat_phase == true: crtr_night.play()
		return
	%Game.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pausemenu.show()
	end_turn.hide()
	get_tree().call_group("MUSIC", "stop")
	crtr_pause.play()
