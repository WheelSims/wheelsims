extends Node3D
@export var traffic_lights : Array[Node3D] = []


enum Direction {NS, EW}
var _currentDirection : Direction = Direction.NS

@export var green_light_duration = 30
@export var yellow_light_duration = 2
var yellow_on = false
var _timer : float

@export var pedestian_traffic_lights : Array[PedestrianTrafficLight] = []

func _ready() -> void:
	_timer = 0
	for traffic_light in traffic_lights:
		traffic_light.green_light_duration = green_light_duration
		if (traffic_light.direction == Direction.NS):
			traffic_light.set_light_state(traffic_light.LightState.GREEN)
		else:
			traffic_light.set_light_state(traffic_light.LightState.RED)

func _process(delta: float) -> void:
	_timer += delta

	if _timer > green_light_duration:
		if not yellow_on:
			_set_yellow()
		if _timer > green_light_duration + yellow_light_duration:
			_timer = 0
			yellow_on = false
			_set_green_red()

func _pedestrian_traffic_light(delta : float) -> void:
	for pedestian_traffic_light in pedestian_traffic_lights:
		if (pedestian_traffic_light.direction == _currentDirection):
			pedestian_traffic_light.change_state(true)
			pedestian_traffic_light.counter(ceil(green_light_duration - _timer))
		else:
			pedestian_traffic_light.change_state(false)
			

func _set_yellow():
	yellow_on = true
	_currentDirection = opposite(_currentDirection)

	for traffic_light in traffic_lights:
		if traffic_light.direction == opposite(_currentDirection):
			traffic_light.set_light_state(traffic_light.LightState.YELLOW)
			
func _set_green_red():
	for traffic_light in traffic_lights:
		if traffic_light.direction == opposite(_currentDirection):
			traffic_light.set_light_state(traffic_light.LightState.RED)
		else:
			traffic_light.set_light_state(traffic_light.LightState.GREEN)

func opposite(direction : Direction) -> Direction:
	return Direction.EW if direction == Direction.NS else Direction.NS
