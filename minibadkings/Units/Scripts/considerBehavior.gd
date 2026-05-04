@tool
extends UtilityAiConsideration

@onready var node : Enemy = self.owner

@export var behaviorToBeChecked : Enemy.BEHAVIOR

func score() -> float:
	if node.behaviorType == behaviorToBeChecked:
		return 1.0
	return 0.0
