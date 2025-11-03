extends Control 
class_name Decree

enum TYPE  {
	NONE, INSPIRATION, DECARE, RECON, DEFENSE, RENOVATE, WAR, 
	CONSCRIPTION, MASTERY, TERROR, SABOTAGE, FORTITUDE, #INFLUENCE,
	CONSTRUCTION
}

@export var type : TYPE
@export var time : float = 0
@export var cooldown : float = 3

@onready var sprite: Sprite2D = $Icon
@onready var tile : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var world : World = get_tree().get_first_node_in_group("WORLD")
@onready var bar: TextureProgressBar = %TextureProgressBar

var under_mouse : bool = false

func _ready() -> void:
	match_sprite()
	update_cooldown()

func update_cooldown() -> void:
	if !bar : 
		bar = %TextureProgressBar
		return
	bar.max_value = cooldown
	bar.value = time
	bar.visible = bar.value > 0

func _on_mouse_entered() -> void:
	if time > 0 or !world.is_combat_phase: return
	
	
	under_mouse = true
	sprite.scale = Vector2(1.5,1.5)
	custom_minimum_size *= 1.5
	sprite.material = preload("res://Units/Shaders/houseHighlight.tres")
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	if time > 0 or !world.is_combat_phase: return
	under_mouse = false
	sprite.material = null
	custom_minimum_size /= 1.5
	sprite.scale = Vector2(1,1)
	
	pass # Replace with function body.

func _on_pressed() -> void:
	if time > 0 : return
	tile.decree = self
	tile.activeDecree = type

func match_sprite() -> void:
	match type:
		TYPE.INSPIRATION:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/inspirationIco.png")
		TYPE.DECARE:
			cooldown = 2
			sprite.texture = preload("res://UI/Assets/decrees/decareIco.png")
		TYPE.RECON:
			cooldown = 2
			sprite.texture = preload("res://UI/Assets/decrees/reconIco.png")
		TYPE.DEFENSE:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/defenseIco.png")
		TYPE.RENOVATE:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/renovateIco.png")
		TYPE.WAR:
			cooldown = 2
			sprite.texture = preload("res://UI/Assets/decrees/warIco.png")
		TYPE.CONSCRIPTION:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/conscriptionIco.png")
		TYPE.MASTERY:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/masteryIco.png")
 		#TYPE.INFLUENCE:
			#sprite.texture = preload("res://UI/Assets/decrees/influenceIco.png")
		TYPE.CONSTRUCTION:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/constructionIco.png")
		TYPE.SABOTAGE:
			cooldown = 2
			sprite.texture = preload("res://UI/Assets/decrees/sabotageIco.png")
		TYPE.TERROR:
			cooldown = 2
			sprite.texture = preload("res://UI/Assets/decrees/terrorIco.png")
		TYPE.FORTITUDE:
			cooldown = 3
			sprite.texture = preload("res://UI/Assets/decrees/fortitudeIco.png")
