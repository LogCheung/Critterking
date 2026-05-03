class_name Citizen
extends Ally

@export var workplace : Building
@export var home : Building
@export var at_destination : bool = false

func _ready() -> void:
	if !nav.velocity_computed.is_connected(_on_navigation_agent_2d_velocity_computed):
		nav.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	if !%NavDelay.timeout.is_connected(on_nav_delay):
		%NavDelay.timeout.connect(on_nav_delay)
	
	nav.target_position = workplace.entrance.global_position
	action = ACTION.WALK
	pass

func _process(delta: float) -> void:
	super._process(delta)
func match_type() -> void:
	sprite_2d.texture = load("res://Units/Assets/AllyCitizen/AllyNormalCitizen.png")

func handle_action(delta) -> void:
	var distToTarget = global_position.distance_to(nav.target_position)
	at_destination = distToTarget <= .5
	match action:
		ACTION.NONE:
			if target == workplace and !workplace.active : 
				target = home
				action = ACTION.WALK
			if global_position.distance_to(home.entrance.global_position) < 2:
				queue_free()
			
			anim.play("idle")
			visible = true
			return
		
		ACTION.WALK:
			target = home if !workplace else workplace
			if !target: return
			print(target == workplace and !workplace.active )
			if target == workplace and !workplace.active : target = home
			
			anim.play("walk")
			nav.target_position = target.entrance.global_position
			pass
	
	if next_path_pos:
		move_to(self.global_position.direction_to(next_path_pos), delta)

# overwrite unused functions
func _on_behind_wall_mouse_entered() -> void:
	pass
func _on_behind_wall_mouse_exited() -> void:
	pass
func _on_behind_wall_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass
