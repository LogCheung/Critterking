extends Node

@export var expansions : int = 0
@export var nights : int = 0
@export var wins : int = 0
@export var saveNights : int = 0
@export var cardsInHand : Array
@export var cardsDispatched : Array
@export var decreesEquipped : Array
@export var partyCount : int
@export var partyLimit : int
@export var tutorial : bool = true
@export var tutorialCharm : bool = true
@export var tutorialDecree : bool = true
@export var unlockedCards : Array = []

# unlocks after each win
var UNLOCK : Array = [
	[Card.CARDTYPE.STINGER, Card.CARDTYPE.RESILIENT,Card.CARDTYPE.PARALYTIC], # first win
	#[Card.CARDTYPE.TUNNEL, Card.CARDTYPE.CLIFF, Card.CARDTYPE.FORTIFY], # second win
	[Card.CARDTYPE.FUNGI, Card.CARDTYPE.TRAPJAW, Card.CARDTYPE.EXPLOSIVE], # third win
	#[Card.CARDTYPE.FORT, Card.CARDTYPE.CAMPFIRE, Card.CARDTYPE.REFRESH], # 4
	
]
