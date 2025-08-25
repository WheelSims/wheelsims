extends Node3D

### PATH & CURVE FOLLOWING ###
@onready var _path_follow: PathFollow3D = get_parent()
@export var _triggers_on_curve: Array[Area3D]
var _triggers_on_curve_offsets: Array[float]
@onready var _path: Path3D = _path_follow.get_parent()

### AUDIO ###
@onready var _motor_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

### MOVEMENT ###
@export var _max_speed: float
@export var _slow_speed: float
@export var _acceleration: float
var _current_speed: float = 0
var _target_speed: float = 0
var _nb_obstacle: int = 0
var _nb_front_obstacle: int = 0
var _nb_far_obstacle: int = 0
var _should_stop = false
var _should_be_slow = false

### WHEELS ###
var _wheel_radium: float = 1.0
@export var _wheels: Array[MeshInstance3D]
@export var _front_pivots: Array[Node3D]
var _wheels_angular_speed: float = 0.0

# Store the original Z offsets of the triggers before resetting their positions.
func _ready():
	for i in _triggers_on_curve.size():
		var offset = _triggers_on_curve[i].position.z
		_triggers_on_curve_offsets.append(offset)
		_triggers_on_curve[i].position = Vector3(0,0,0)

func _process(delta: float) -> void:
	_car_audio()
	_wheel_movements(delta)
		
	if _nb_obstacle < 1:
		if _should_be_slow:
			_target_speed = _slow_speed
		elif _should_stop:
			_target_speed = 0
		else:
			_target_speed = _max_speed
		_current_speed = move_toward(_current_speed, _target_speed, delta * _acceleration)
		_car_progress(delta)
	else:
		_current_speed = 0

func _car_progress(delta: float) -> void:
	_path_follow.progress += _current_speed * delta
	for i in _triggers_on_curve.size():
		var offset_progress = _path_follow.progress + _triggers_on_curve_offsets[i] + _current_speed / 2
		var position_on_curve = _path.curve.sample_baked(offset_progress)
		var global_position = position_on_curve + _path.position
		_triggers_on_curve[i].global_transform.origin = global_position
		
func _car_audio() -> void:
	_motor_sound.pitch_scale = lerpf(1, 1.5, _current_speed/_max_speed)

func _wheel_movements(delta: float) -> void:
	#Wheels rotation on x
	_wheels_angular_speed = _current_speed / _wheel_radium
	for wheel in _wheels:
		wheel.rotate_x(_wheels_angular_speed * delta)
	
	#Front Wheels rotation on y
	var curve_transform_on_front_wheels = _path.curve.sample_baked_with_rotation(_path_follow.progress + 3)
	var frontwheeldirection = -curve_transform_on_front_wheels.basis.z
	var angle_y = atan2(frontwheeldirection.x, frontwheeldirection.z)
	var desired_rotation = Vector3(0, angle_y, 0)
	for front_pivot in _front_pivots:
		front_pivot.global_rotation = desired_rotation
		
func _on_close_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("NPC") or area.is_in_group("Player") or area.is_in_group("Obstacle")) and not self.is_ancestor_of(area):
		_nb_obstacle += 1

func _on_close_trigger_area_exited(area: Area3D) -> void:
	if (area.is_in_group("NPC") or area.is_in_group("Player") or area.is_in_group("Obstacle")) and not self.is_ancestor_of(area):
		_nb_obstacle -= 1
		if _nb_obstacle < 0:
			printerr("_nb_obstacle negative.")
			_nb_obstacle = 0
		
func _on_front_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_front_obstacle += 1
	if _nb_front_obstacle > 0:
		_should_stop = true

func _on_front_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_front_obstacle -= 1
	if _nb_front_obstacle == 0:
		_should_stop = false
	elif _nb_front_obstacle < 0:
		printerr("_nb_front_obstacle negative.")
		_nb_front_obstacle = 0

func _on_far_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_far_obstacle += 1
	if _nb_far_obstacle > 0:
		_should_be_slow = true

func _on_far_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_far_obstacle -= 1
	if _nb_far_obstacle == 0:
		_should_be_slow = false
	elif _nb_far_obstacle < 0:
		printerr("nb_far_obstacle negative.")
		_nb_far_obstacle = 0
