class_name BoxInfoContainer
extends VBoxContainer

const boxTypeDict : Dictionary = {
	"COMMERCE" : [
		Card.CARDTYPE.CASINO, Card.CARDTYPE.HALL, Card.CARDTYPE.GARDEN,
		Card.CARDTYPE.TRADINGPOST
	],
	"CULTURE" :[
		Card.CARDTYPE.TAVERN, Card.CARDTYPE.MONUMENT, Card.CARDTYPE.THEATRE,
		Card.CARDTYPE.POND, Card.CARDTYPE.CARE
	],
	"FAME" : [
		Card.CARDTYPE.HOUSE, Card.CARDTYPE.CUSTOMS, Card.CARDTYPE.PANTRY,
		Card.CARDTYPE.GUILD
	],
	"PRODUCTIVITY" : [
		Card.CARDTYPE.FIELD, Card.CARDTYPE.SCHOOL, Card.CARDTYPE.STORAGE
	],
	"ADJACENT" : [
		Card.CARDTYPE.FORT, Card.CARDTYPE.FARM, Card.CARDTYPE.POND
	],
	"AROUND" : [
		Card.CARDTYPE.CAMPFIRE, Card.CARDTYPE.SAPSTORE
	],
	"ARMORED" : [
		Card.CARDTYPE.PLATED, Card.CARDTYPE.RESILIENT
	],
	"DOORWAY" : [
		Card.CARDTYPE.BAKERY, Card.CARDTYPE.CARE, Card.CARDTYPE.CASINO,
		Card.CARDTYPE.GUILD, Card.CARDTYPE.HALL, Card.CARDTYPE.HOUSE,
		Card.CARDTYPE.NURSERY, Card.CARDTYPE.PANTRY, Card.CARDTYPE.SCHOOL,
		Card.CARDTYPE.STORAGE, Card.CARDTYPE.TAVERN, Card.CARDTYPE.TRADINGPOST,
		
	],
	"KNOCKBACK" : [
		Card.CARDTYPE.TRAPJAW, 
	],
	"PCENTCHANCE" : [
		Card.CARDTYPE.STORAGE, Card.CARDTYPE.NURSERY, Card.CARDTYPE.BAKERY, Card.CARDTYPE.MARKETPLACE, Card.CARDTYPE.CUSTOMS, Card.CARDTYPE.GUILD
	],
	"RANGED" : [
		Card.CARDTYPE.SPITTER, Card.CARDTYPE.ACIDIC, Card.CARDTYPE.FUNGI
	],
	"STUN" : [
		Card.CARDTYPE.PARALYTIC, Card.CARDTYPE.NAIL
	],
	"UPGRADABLE" : [
		Card.CARDTYPE.BITER, Card.CARDTYPE.PLATED, Card.CARDTYPE.SPITTER,
		Card.CARDTYPE.TRAPJAW, Card.CARDTYPE.EXPLOSIVE, Card.CARDTYPE.FUNGI,
		Card.CARDTYPE.PARALYTIC, Card.CARDTYPE.RESILIENT, Card.CARDTYPE.STINGER,
		Card.CARDTYPE.ACIDIC, Card.CARDTYPE.BOMBER, Card.CARDTYPE.FLYING, 
		Card.CARDTYPE.CRAZED
	],
}


@export var boxTypes : Array = []

@onready var card : Card = get_parent()

func match_type() -> void:
	boxTypes.clear()
	for key in boxTypeDict:
		if boxTypeDict[key].has(card.type) : 
			boxTypes.append(InfoBox.TYPE.get(key))

	create_boxes()

func create_boxes() -> void:
	for c in get_children():
		c.queue_free()
	
	for t in boxTypes:
		var infoBox : InfoBox = load("res://UI/Scenes/infoBox.tscn").instantiate()
		infoBox.type = t
		infoBox.match_type()
		add_child(infoBox)
