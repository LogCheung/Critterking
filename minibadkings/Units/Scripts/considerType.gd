@tool
extends UtilityAiConsideration

@onready var node : Unit = self.owner

func score() -> float:
	if node.ranged:
		return 1.0
	return 0.0
