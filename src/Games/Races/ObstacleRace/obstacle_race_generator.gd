extends Node3D

@export var border_sample_scene: PackedScene
@export var obstacle_sample: PackedScene
@export var race_length: int = 100
@export var race_width: float = 10
@export var object_size_range: Vector2 = Vector2(0.5,3)
@export var depth_dist_btw_object_range: Vector2 = Vector2(5,20)
@export var horiz_dist_btw_object_range: Vector2 = Vector2(3,5)
@export var min_passage_size = 2

var _rng = RandomNumberGenerator.new()
var _depth_dist: float
var _horiz_dist: float
var _object_size: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_border_generation()
	_obstacle_generation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _border_generation() -> void:
		for i in race_length:
			var leftBorderSample: Node3D = border_sample_scene.instantiate()
			leftBorderSample.position.x = i
			leftBorderSample.position.z = - race_width/2 - leftBorderSample.scale.z
			add_child(leftBorderSample)
			var rightBorderSample: Node3D = border_sample_scene.instantiate()
			rightBorderSample.position.x = i
			rightBorderSample.position.z = race_width/2 + rightBorderSample.scale.z
			add_child(rightBorderSample)
		
func _obstacle_generation() -> void:
	var _cursor_pos = 0
	_depth_dist = _rng.randf_range(depth_dist_btw_object_range.x, depth_dist_btw_object_range.y)
	_cursor_pos += _depth_dist
	while _cursor_pos < race_length:
		_obstacles_pos_and_scale(_cursor_pos, -race_width/2, race_width/2, 5)
		
		_depth_dist = _rng.randf_range(depth_dist_btw_object_range.x, depth_dist_btw_object_range.y)
		_cursor_pos += _depth_dist
		
func _obstacles_pos_and_scale(pos_x: float, left_border_pos, right_border_pos, nb_obs)->void:
	if (nb_obs == 0):
		return 
	var obstacle: Node3D = obstacle_sample.instantiate()
	obstacle.position.x = pos_x
	while true:
		var pos_z = _rng.randf_range(left_border_pos, right_border_pos)
		var size_z = _rng.randf_range(object_size_range.x, object_size_range.y)

		var in_race_space = pos_z - size_z/2 > left_border_pos and pos_z + size_z/2 < right_border_pos
		var enough_space = pos_z - size_z/2 - left_border_pos < min_passage_size or pos_z + size_z/2 - right_border_pos < min_passage_size

		if in_race_space and enough_space:
			obstacle.position.z = pos_z
			obstacle.scale.z = size_z
			break
	add_child(obstacle)
		
	var dist_right = right_border_pos - (obstacle.position.z + obstacle.scale.z/2)
	var dist_left = (obstacle.position.z - obstacle.scale.z/2) - left_border_pos

	if (dist_right > dist_left):
		if dist_right > min_passage_size + object_size_range.x:
			_obstacles_pos_and_scale(pos_x, obstacle.position.z + obstacle.scale.z/2, right_border_pos, nb_obs - 1)
	else:
		if dist_left > min_passage_size + object_size_range.x:
			_obstacles_pos_and_scale(pos_x, left_border_pos, obstacle.position.z - obstacle.scale.z/2, nb_obs - 1)
	
	
	
