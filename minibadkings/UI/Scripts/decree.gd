extends Control 
class_name Decree

enum TYPE  {
	INSPIRATION, DECARE, RECON, DEFENSE, RENOVATE, WAR, 
	CONSCRIPTION, MASTERY, INFLUENCE, CONSTRUCTION
}

@export var type : TYPE

var under_mouse : bool = false

@onready var sprite: Sprite2D = $ConscriptionIco

func _ready() -> void:
	match_sprite()

func _on_mouse_entered() -> void:
	under_mouse = true
	sprite.scale = Vector2(1.5,1.5)
	custom_minimum_size *= 1.5
	sprite.material = preload("res://Units/Shaders/houseHighlight.tres")
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	under_mouse = false
	sprite.material = null
	custom_minimum_size /= 1.5
	sprite.scale = Vector2(1,1)
	pass # Replace with function body.

func match_sprite() -> void:
	match type:
		TYPE.INSPIRATION:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.DECARE:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.RECON:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.DEFENSE:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.RENOVATE:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.WAR:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.CONSCRIPTION:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.MASTERY:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.INFLUENCE:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.CONSTRUCTION:
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		
