extends CharacterBody2D
class_name Unit

enum ACTION {
	NONE,FORM, FIGHT
}

signal selected
signal unselected

const HIGHLIGHT = preload("res://Units/Shaders/unitHighlight.tres")
@export var speed : float = 100
@export var formation_position : Node2D 
@export var group : UnitGroup

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")

var action : ACTION = ACTION.NONE
var in_combat : bool = false
var path_points : Array

func _ready() -> void:
	selected.connect(on_selected)
	unselected.connect(on_unselected)

func _process(delta: float) -> void:
	match action:
		ACTION.NONE:
			return
		ACTION.FORM:
			nav.target_position = formation_position.global_position
			if global_position.distance_to(nav.target_position) < 3:
				return
	
	move_to(self.global_position.direction_to(nav.get_next_path_position()), delta)

func on_selected() -> void:
	sprite_2d.material = HIGHLIGHT
func on_unselected() -> void:
	sprite_2d.material = null

func move_to(direction, _delta):
	if direction.x > 0:
		$Flip.scale.x = 1
	else:
		$Flip.scale.x = -1
		
	var new_velocity = direction * speed
	velocity = new_velocity
	
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
		
	move_and_slide()
	
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func _on_utility_ai_agent_top_score_action_changed(top_action_id: Variant) -> void:
	match top_action_id:
		"form":
			action = ACTION.FORM
		pass
