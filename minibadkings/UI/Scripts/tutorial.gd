class_name Tutorial
extends Control

@onready var tutorial_title: RichTextLabel = %TutorialTitle
@onready var tutorial_text: RichTextLabel = %TutorialText
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var ui : UI = get_tree().get_first_node_in_group("UI")
#@onready var choices: Control = %Choices

func play_card_tutorial() -> void:
	if Global.tutorial:
		%Tutorial.show()
		%TutorialTitle.text = "Cards"
		%TutorialText.text = "Every night you will be able to draw a card, click the deck and make your selection!"
		%TutorialText.text += "\n\nThe first night you will be able draw twice!"

func play_command_heal_tutorial() -> void:
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

func play_day_basics_tutorial() -> void:
	if Global.tutorial:
		%Tutorial.show()
		%TutorialTitle.text = "Placing"
		%TutorialText.text = "Place your cards by dragging them from your hand onto the map!"
		%TutorialText.text += "\n\nIf you have two of the same unit card, you can merge them!"
		
		await ui.card_placed
		await ui.card_placed
		
		%TutorialTitle.text = "Unit Types"
		%TutorialText.text = "Units tend to fall into categories, offensive, defensive, and ranged"
		%TutorialText.text += "\n\nDuring battle, strategize carefully to ensure a favorable matchup!"
		
		await ui.card_placed
		%TutorialTitle.text = "Camera"
		%TutorialText.text = "\nUse WASD to move your camera. Hold down shift to speed up the camera!"

func play_charms_tutorial() -> void:
	if world.dispatchDay and Global.tutorialCharm:
		%Tutorial.show()
		%TutorialTitle.text = "Discoveries"
		%TutorialText.text = "Units sent out will be disabled for a night, but will come back tomorrow with an upgrade"
		%TutorialText.text += "\n\nYou can continue without selecting if you choose."
		Global.tutorialCharm = false
		return

func play_decrees_tutorial() -> void:
	if ui.rolltype == Card.ROLLTYPE.BLESSING and Global.tutorialDecree:
		%Tutorial.show()
		%TutorialTitle.text = "Decrees"
		%TutorialText.text = "Decrees are [color=yellow]active[/color] abilities that can be used during the night."
		%TutorialText.text += "\n\nOnce used they will be on cooldown for a number of nights but can greatly help your defense."
		%TutorialText.text += "\n\nAfter picking one, they will be displayed on the left."
		Global.tutorialDecree = false
		pass
