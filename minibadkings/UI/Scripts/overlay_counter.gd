class_name OverlayCounter
extends Control

@export var resourceType : Global.RESOURCETYPE
@export var army : bool = false
@export var traitType : Global.TRAITTYPE

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var overhead_info: TextureRect = $overheadInfo
@onready var label: Label = %Label
@onready var pos_proj: TextureRect = $posProj
@onready var neg_proj: TextureRect = $negProj
@onready var pos_proj_label: Label = %posProjLabel
@onready var neg_proj_label: Label = %negProjLabel
@onready var world : World = get_tree().get_first_node_in_group("WORLD")

func _ready() -> void:
	overhead_info.hide()
	match_info_box()
	if resourceType != Global.RESOURCETYPE.NONE:
		match_sprite_resource()
	else:
		pos_proj.hide()
		neg_proj.hide()
		match_sprite_trait()
		
	if army:
		sprite_2d.frame = 7
		
	world.night_ended.connect(show_projections.bind(true))
	world.night_started.connect(show_projections.bind(false))
		
func match_info_box() -> void:
	if army:
		overhead_info.texture = load("res://UI/Assets/overheadInfo/armyOSTS.png")
		return
	
	var path = "res://UI/Assets/overheadInfo/"
	if resourceType != Global.RESOURCETYPE.NONE:
		path += Global.RESOURCETYPE.keys()[resourceType] +"OSTS.png"
	else:
		path += Global.TRAITTYPE.keys()[traitType] +"OSTS.png"
	overhead_info.texture = load(path)

func match_sprite_resource() -> void:
	match resourceType:
		Global.RESOURCETYPE.SATISFACTION:
			sprite_2d.frame = 8
		Global.RESOURCETYPE.FOOD:
			sprite_2d.frame = 9
		Global.RESOURCETYPE.MONEY:
			sprite_2d.frame = 10
		Global.RESOURCETYPE.CITIZEN:
			sprite_2d.frame = 6
		Global.RESOURCETYPE.HOUSE:
			pos_proj.hide()
			neg_proj.hide()
			sprite_2d.frame = 4
func match_sprite_trait() -> void:
	match traitType:
		Global.TRAITTYPE.FAME:
			sprite_2d.frame = 0
		Global.TRAITTYPE.CULTURE:
			sprite_2d.frame = 1
		Global.TRAITTYPE.PRODUCTIVITY:
			sprite_2d.frame = 2
		Global.TRAITTYPE.COMMERCE:
			sprite_2d.frame = 3

func set_value(value : int, showAnim : bool = true) -> void:
	if resourceType == Global.RESOURCETYPE.SATISFACTION and value > 100: 
		# satisfaction max
		Global.resource_dict[Global.RESOURCETYPE.SATISFACTION] = 100
		return
	if resourceType == Global.RESOURCETYPE.MONEY and value < 0: 
		# money min
		Global.resource_dict[Global.RESOURCETYPE.MONEY] = 0
		return
		
	if army or value == int(label.text): return
	var children = get_children().filter(func(e):return e is Pop)
	if !children.is_empty():
		# first child will be another pop scene
		await get_tree().create_timer(.5).timeout
	# if isn't army counter or value doesn't change or not max then continue 
	
	# show change animation
	if value != int(label.text) and showAnim:
		var pop : Pop = preload("res://UI/Scenes/pop.tscn").instantiate()
		add_child(pop)
		pop.global_position = global_position + Vector2(8,140)
		pop.show_value(value - int(label.text))
	
	label.text = str(value)

func set_projection_value(value : int, positive : bool) -> void:
	%posAsterisk.visible = false
	if positive:
		pos_proj.visible = value != 0
		pos_proj_label.text = str(abs(value))
	else:
		neg_proj.visible = value != 0
		neg_proj_label.text = str(abs(value))
	
	# check if pcent chance present for resourcetype
	var builds = get_tree().get_nodes_in_group("COLONY")
	builds = builds.filter(func(b:ColonyBuilding): return b.resourceType == resourceType)
	for b : ColonyBuilding in builds:
		if b.chance < 100 and b.active:
			value -= b.resourceAmt # don't account/guarantee amt 
			pos_proj_label.text = str(abs(value))
			%posAsterisk.visible = true
			pos_proj.visible = true

func show_projections(condition : bool) -> void:
	await get_tree().create_timer(1).timeout
	pos_proj.visible = condition and int(pos_proj_label.text) != 0
	neg_proj.visible = condition and int(neg_proj_label.text) != 0
	
	# exception for chance 
	pos_proj.visible = %posAsterisk.visible and condition
	pass

func _on_mouse_entered() -> void:
	overhead_info.visible = true
	
func _on_mouse_exited() -> void:
	overhead_info.visible = false
