extends Resource
class_name SaveDataResource

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
@export var buildings : Array = []

# resources
@export var resource_dict : Dictionary
# traits
@export var trait_dict : Dictionary
