extends Node3D
class_name PedestrianTrafficLight

@export var pedestrian_priority : bool = false
@export var _hand_sprite : Sprite3D
@export var _character_sprite : Sprite3D
@export var _blink_timer : Timer
@onready var counter_label : Label3D = $pedestrianLightCounter/Label3D

var duration : float = 25.0
var _elapsed : float = 0.0
var _countdown : int = 0
var _hand_blink : bool = false

func _ready() -> void:
	_blink_timer.timeout.connect(_on_blink)

func _process(delta: float) -> void:
	if not pedestrian_priority:
		reset_light()
		return

	if _blink_timer.is_stopped():
		_blink_timer.start()

	_elapsed += delta
	_countdown = int(duration - _elapsed)

	if _countdown > 20:
		show_walk()
	elif _countdown > 0:
		show_hand_blink()
	else:
		reset_light()

	update_counter(_countdown)

func show_walk() -> void:
	_character_sprite.visible = true
	_hand_sprite.visible = false
	counter_label.visible = false
	_hand_blink = false

func show_hand_blink() -> void:
	_character_sprite.visible = false
	counter_label.visible = true
	_hand_blink = true

func reset_light() -> void:
	_elapsed = 0
	_hand_blink = false
	_hand_sprite.visible = true
	pedestrian_priority = false
	update_counter(0)
	_blink_timer.stop()

func update_counter(value: int) -> void:
	counter_label.text = str(value)

func _on_blink() -> void:
	if _hand_blink:
		_hand_sprite.visible = not _hand_sprite.visible
