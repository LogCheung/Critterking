class_name InfoBox
extends TextureRect

enum TYPE {
	NONE, ADJACENT, ARMORED, AROUND, COMMERCE, CULTURE,
	DOORWAY, FAME, KNOCKBACK, PCENTCHANCE, PRODUCTIVITY,
	RANGED, STUN, UPGRADABLE
}

@export var type : TYPE

func match_type() -> void:
	var path = "res://UI/Assets/boxes/"+ TYPE.keys()[type] +"Box.png"
	texture = load(path)
