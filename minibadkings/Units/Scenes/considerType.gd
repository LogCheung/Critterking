extends UtilityAiConsideration

@export var type : Unit.TYPE

@onready var node : Unit = self.owner

func score() -> float:
	if node.type == type:
		return 1.0
	return 0.0
