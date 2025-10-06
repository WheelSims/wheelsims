extends Node3D

var player: Node3D
var current_race_objects: Array[Node3D] = []
@export var restart_pos: Node3D
@export var end_offset_to_restart: float
@export var race_data: Array[RaceData]
var current_race_data_indice := 0
var current_race_data
var default_border_sample: PackedScene
var default_obstacle_sample: PackedScene
@export var border_sample: PackedScene
@export var obstacle_sample: PackedScene

var race_length: int = 100
var race_width: float = 10
var object_size_range: Vector2 = Vector2(0.5,3)
var depth_dist_btw_object_range: Vector2 = Vector2(5,20)
var horiz_dist_btw_object_range: Vector2 = Vector2(3,5)
var min_passage_size = 2

var _rng = RandomNumberGenerator.new()
var _depth_dist: float
var _horiz_dist: float
var _object_size: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_border_sample = border_sample
	default_obstacle_sample = obstacle_sample
	if race_data.size()>0:
		current_race_data = race_data[0]
		_change_current_parameters()
	_border_generation()
	_border_generation(-1)
	_obstacle_generation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		if player.position.distance_to(position) > race_length:
			player.global_position = restart_pos.global_position
			_next_level()

func _border_generation(direction := 1) -> void:
		for i in race_length + end_offset_to_restart*3:
			var leftBorderSample: Node3D = default_border_sample.instantiate()
			current_race_objects.append(leftBorderSample)
			leftBorderSample.position.x = i * direction
			leftBorderSample.position.z = - race_width/2 - leftBorderSample.scale.z
			add_child(leftBorderSample)
			var rightBorderSample: Node3D = default_border_sample.instantiate()
			current_race_objects.append(rightBorderSample)
			rightBorderSample.position.x = i * direction
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
	current_race_objects.append(obstacle)
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
			
func _next_level() -> void:
	current_race_data_indice += 1
	if race_data.size()<=current_race_data_indice:
		print("fin")
		return
	_destroy_current_race_objects()
	_change_current_parameters()
	_border_generation()
	_border_generation(-1)
	_obstacle_generation()

func _destroy_current_race_objects()->void:
	for i in range(current_race_objects.size() - 1, -1, -1):
		current_race_objects[i].queue_free()
		current_race_objects.remove_at(i)

func _change_current_parameters() -> void:
	current_race_data = race_data[current_race_data_indice]
	race_length = current_race_data.race_length
	race_width = current_race_data.race_width
	object_size_range = current_race_data.object_size_range
	depth_dist_btw_object_range = current_race_data.depth_dist_btw_object_range
	horiz_dist_btw_object_range = current_race_data.horiz_dist_btw_object_range
	min_passage_size = current_race_data.min_passage_size
	if current_race_data.border_sample == null:
		current_race_data.border_sample = default_border_sample
	if current_race_data.obstacle_sample == null:
		current_race_data.obstacle_sample = default_obstacle_sample
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player = body
