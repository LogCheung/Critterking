extends CharacterBody2D
class_name Unit

enum ACTION {
	NONE,FORM, FIGHT
}

signal selected
signal unselected

const HIGHLIGHT = preload("res://Units/Shaders/unitHighlight.tres")
@export var health : int = 4
@export var damage : int = 2
@export var speed : float = 100
@export var formation_position : Node2D 
@export var group : UnitGroup

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var tileWorld : TileWorld = get_tree().get_first_node_in_group("TILEWORLD")
@onready var anim: AnimationPlayer = $AnimationPlayer

var action : ACTION = ACTION.NONE
var in_formation : bool = false
var in_combat : bool = false
var path_points : Array

var is_behind_wall : bool

func _ready() -> void:
	selected.connect(on_selected)
	unselected.connect(on_unselected)

func _process(delta: float) -> void:
	if action != ACTION.NONE:
		handle_behind_wall()
	
	if global_position.distance_to(formation_position.global_position) <= 2:
		# precheck if it is behind something
		is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
		if !is_behind_wall: wall_tile = null
		
		in_formation = true
	else:
		in_formation = false
	
	match action:
		ACTION.NONE:
			anim.play("idle")
			
			return
		ACTION.FORM:
			anim.stop()
			nav.target_position = formation_position.global_position
			if global_position.distance_to(nav.target_position) <= 2:
				# precheck if it is behind something
				is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
				if !is_behind_wall: wall_tile = null
				
				in_formation = true
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
		"none":
			tileWorld.replace_transparent_walls()
			action = ACTION.NONE
		"form":
			action = ACTION.FORM
		pass

var wall_tile # wall that it is behind
func handle_behind_wall() -> void:
	is_behind_wall = true if $behindWall.has_overlapping_bodies() else false
	# not liking but looks for closest tile by going all wall tiles and makes transparent
	if is_behind_wall:
		var walls = tileWorld.wall.get_used_cells_by_id(0,Vector2(0,2),2)
		walls.append_array(tileWorld.wall.get_used_cells_by_id(0,Vector2(0,2),1))
		
		wall_tile = walls.front()
		for w in walls:
			
			var w_local_pos = tileWorld.wall.map_to_local(w)
			var wall_tile_local_pos = tileWorld.wall.map_to_local(wall_tile)
			var cur_dist = global_position.distance_to(wall_tile_local_pos)
			var next_dist = global_position.distance_to(w_local_pos)
			if next_dist < cur_dist :
				wall_tile = w
		
		tileWorld.wall.set_cell(wall_tile,0,Vector2(0,2),1)
