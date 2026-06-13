class_name Tutorial
extends Control

enum STATE {
	NORM, HAPPY, NERV, PROUD
}
enum TYPE {
	GREETING, UNITS, DECREE, EXPLORATION, NIGHT, SHOP, MORNING, BUILDING
}

const BALLOON = preload("res://UI/Scenes/dialogue_balloon.tscn")

@onready var tutorial_title: RichTextLabel = %TutorialTitle
@onready var tutorial_text: RichTextLabel = %TutorialText
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var ui : UI = get_tree().get_first_node_in_group("UI")
#@onready var choices: Control = %Choices

func set_advisor_expression(s : STATE) -> void:
	var ad : TextureRect = get_tree().get_first_node_in_group("ADVISOR")
	var expr : String = STATE.keys()[s].substr(0,1) + STATE.keys()[s].substr(1).to_lower()
	ad.texture = load("res://UI/Assets/dialogue/advise" + expr + ".png")

func play_tutorial(t : TYPE) -> void:
	if !Global.tutorial : return
	var dia = load("res://UI/Dialogue/"+ TYPE.keys()[t].to_lower() +".dialogue")
	DialogueManager.show_dialogue_balloon_scene(BALLOON,dia)
