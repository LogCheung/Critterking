extends UtilityAiConsideration

@export var type : Unit.TYPE
@export var secondType : Unit.TYPE

@onready var node : Unit = self.owner

func score() -> float:
	if node.type == type or node.type == secondType:
		return 1.0
	return 0.0
