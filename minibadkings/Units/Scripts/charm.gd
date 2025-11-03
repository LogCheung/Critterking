extends Sprite2D
class_name Charm

enum TYPE {
	HEARTLOCKET, RING, SWORD, FLAG, 
	SODA, ROLLERSKATE, MEDKIT, GLASSES,BERRIES, PILLS, DOLLHOUSE, EDRINK,NAIL,
	
}

@export var type : TYPE

func _ready() -> void:
	match type:
		TYPE.HEARTLOCKET:
			texture = preload("res://UI/Assets/charms/locketIcon.png")
		TYPE.RING:
			texture = preload("res://UI/Assets/charms/ringIcon.png")
		TYPE.SWORD:
			texture = preload("res://UI/Assets/charms/swordIcon.png")
		TYPE.FLAG:
			texture = preload("res://UI/Assets/charms/flagIcon.png")
		TYPE.SODA:
			texture = preload("res://UI/Assets/charms/sodaIcon.png")
		TYPE.ROLLERSKATE:
			texture = preload("res://UI/Assets/charms/skateIcon.png")
		TYPE.MEDKIT:
			texture = preload("res://UI/Assets/charms/medkitIcon.png")
		TYPE.GLASSES:
			texture = preload("res://UI/Assets/charms/glassesIcon.png")
		TYPE.NAIL:
			texture = preload("res://UI/Assets/charms/nailsIcon.png")
		TYPE.BERRIES:
			texture = preload("res://UI/Assets/charms/berriesIcon.png")
		TYPE.PILLS:
			texture = preload("res://UI/Assets/charms/pillsIcon.png")
		TYPE.DOLLHOUSE:
			texture = preload("res://UI/Assets/charms/dollhouseIcon.png")
		TYPE.EDRINK:
			texture = preload("res://UI/Assets/charms/edrinkIcon.png")
