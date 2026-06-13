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

func _ready() -> void:
	%dim2.hide()
	Global.dialogue_closed.connect(on_dialogue_closed)
	
	for i in range(TYPE.size()):
		Global.tutArr.append(i)

func set_advisor_expression(s : STATE) -> void:
	var ad : TextureRect = get_tree().get_first_node_in_group("ADVISOR")
	var expr : String = STATE.keys()[s].substr(0,1) + STATE.keys()[s].substr(1).to_lower()
	ad.texture = load("res://UI/Assets/dialogue/advise" + expr + ".png")

func play_tutorial(t : TYPE) -> void:
	if !Global.tutorial or !Global.tutArr.has(t): return
	
	var dia = load("res://UI/Dialogue/"+ TYPE.keys()[t].to_lower() +".dialogue")
	DialogueManager.show_dialogue_balloon_scene(BALLOON,dia)
	
	Global.tutArr.remove_at(Global.tutArr.find(t))
	%dim2.show()

func highlight_cards(con : bool) -> void:
	%CardShow.material = preload("res://Units/Shaders/cardHighlight.tres") if con else null
	%CardShow.z_index = 60 if con else 0
	%CardShow.z_as_relative = !con

func highlight_overlay(con : bool) -> void:
	%OverlayTexture.modulate = Color(1.353, 1.353, 1.353, 1.0) if con else Color(1.0, 1.0, 1.0, 1.0)
	%InfoOverlay.z_index = 60 if con else 0
	%InfoOverlay.z_as_relative = !con

func highlight_work_button(con : bool) -> void:
	%AssignToggleSprite.modulate = Color(1.353, 1.353, 1.353, 1.0) if con else Color(1.0, 1.0, 1.0, 1.0)
	%AssignToggleSprite.z_index = 60 if con else 0
	%AssignToggleSprite.z_as_relative = !con

func turn_off_tutorial() -> void:
	Global.tutorial = false

func on_dialogue_closed() -> void:
	%dim2.hide()
