extends Resource
class_name SaveDataResource

@export var scene : PackedScene
@export var nights : int
@export var rolls : Array
@export var expansions : int
@export var cardtypeArray : Array
@export var cardsInHand : Array = []
@export var decreesEquipped : Array = []
@export var walls : PackedByteArray
@export var ground : PackedByteArray
@export var obstacles : PackedByteArray
@export var ring : PackedByteArray
@export var dispatchDay : bool
@export var defeated : bool
@export var ascension : int
@export var challenge : int

# resources
@export var money : int = 0
@export var food : int = 0
@export var satisfaction : int = 0
@export var citizens : int = 0
# traits
@export var commerce : int = 0 
@export var culture : int = 0
@export var fame : int = 0
@export var productivity : int = 0
