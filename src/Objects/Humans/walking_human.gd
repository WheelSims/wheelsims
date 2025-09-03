extends Node3D

@onready var footstep_player = $AudioStreamPlayer3D
@export var anim_tree: AnimationTree
@export var max_speed : float = 2
@export var acceleration : float = 1
var _current_speed : float
var _target_speed : float

@export var detection_area: Area3D
@onready var pathFollow: PathFollow3D = get_parent().get_parent()
var _nb_obstacle : int = 0

@onready var down_ray = $Raycasts/RayCast3DDown
@onready var up_ray = $Raycasts/RayCast3DUp
var y_offset = 0

func _ready():
	anim_tree.set("parameters/TimeScale/scale", max_speed / 1.8)
	anim_tree.active = true

func _process(delta):
	# There is speed lerp only for going on walk, not for stopping
	if (_nb_obstacle < 1):
		_target_speed = max_speed
		_current_speed = move_toward(_current_speed, _target_speed, delta * acceleration)
	else:
		_current_speed = 0
	
	_transform_correction()
	get_parent().position -= y_offset * Vector3.UP
	
	anim_tree.set("parameters/Blend2/blend_amount", _current_speed/_target_speed)
	pathFollow.progress += _current_speed * delta

func _on_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_obstacle += 1


func _on_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_obstacle -= 1
		
func play_footstep():
	if not footstep_player.playing:
		footstep_player.play()
		
func _transform_correction() -> void:
	var collision_point: Vector3 = Vector3.ZERO
	var collision_normal: Vector3

	if down_ray.is_colliding():
		collision_point = down_ray.get_collision_point()
		collision_normal = down_ray.get_collision_normal()
	elif up_ray.is_colliding():
		collision_point = up_ray.get_collision_point()
		collision_normal = up_ray.get_collision_normal()
	else:
		y_offset = 0
		return
		
	var offset = (global_position - collision_point).y
	y_offset = offset
	
