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
	elif world.is_combat_phase == true and !%crtrNight.playing and !control_is_visible():
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrDay.stop()
		%crtrPause.stop()
		%crtrNight.play()
	elif world.is_combat_phase == false and !%crtrDay.playing and !control_is_visible():
		%crtrMenu.stop()
		%crtrOver.stop()
		%crtrNight.stop()
		%crtrPause.stop()
		%crtrDay.play()
		
		
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
	var cardSprites = get_tree().get_nodes_in_group("CARD")
	
	for card : Card in cardSprites:
		if !card.for_show : continue
		card.randomize_type()
		card.visible = display
		card.choice_picked = !display
func show_hand() -> void:
	if world.starting_roll:
		cards.show()
		world.starting_roll = false
		return
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
	mainmenu.hide()
	%crtrMenu.stop()
	world.start_day()

func _on_help_pressed() -> void:
	%Button.play()
	%crtrPause.play()
	help.show()
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	%Button.play()
	%crtrPause.play()
	settings.show()
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_backhelp_pressed() -> void:
	%Button.play()
	if !%crtrPause.playing:
		%crtrPause.play()
	help.hide()
	pass # Replace with function body.

func _on_settingsback_pressed() -> void:
	%Button.play()
	if !%crtrPause.playing:
		%crtrPause.play()
	settings.hide()
	pass # Replace with function body.

func _on_endturn_pressed() -> void:
	# check if house is not placed
	%Button.play()
	for card : Card in Global.cardsInHand:
		if card.type == Card.CARDTYPE.HOUSE: 
			%noHouse.show()
			return
	world.night_started.emit()
	%noHouse.hide()

func _on_newgame_pressed() -> void:
	print("ok")
	gameover.hide()
	world.new_game()
	world.start_day()

func _on_title_pressed() -> void:
	gameover.hide()
	mainmenu.show()


func _on_continue_pressed() -> void:
	pausemenu.hide()
