extends Node

@export var expansions : int = 0
@export var nights : int = 0
@export var money : int = 0
@export var food : int = 0
@export var satisfaction : int = 0
@export var citizens : int = 0
@export var commerce : int = 0 
@export var culture : int = 0
@export var fame : int = 0
@export var productivity : int = 0

@export var maxAscension : int = 0
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
	[Card.CARDTYPE.FORT, Card.CARDTYPE.CAMPFIRE, Card.CARDTYPE.PONDER], # second win
	[Card.CARDTYPE.FUNGI, Card.CARDTYPE.TRAPJAW, Card.CARDTYPE.EXPLOSIVE], # third win
	[Card.CARDTYPE.PILLS, Card.CARDTYPE.BERRIES, Card.CARDTYPE.SABOTAGE] # 4
	#[Card.CARDTYPE.TUNNEL, Card.CARDTYPE.CLIFF, Card.CARDTYPE.FORTIFY], # 5
	
]
# unlocks from challenge
var UNLOCK_ACHIEVE : Array = [
	[] # 
]
