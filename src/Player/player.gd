extends RigidBody3D

# ------------------
# Editable constants
# ------------------

@export_group("Keyboard Control")
@export var KB_LINEAR_SPEED: float = 2  # m/s
@export var KB_ANGULAR_SPEED: float = 1  # rad/s

# -----------------------
# Cameras
# -----------------------
@onready var front_camera = get_node_or_null("FrontProjector/FrontCamera")
@onready var floor_camera = get_node_or_null("FloorProjector/FloorCamera")
@onready var front_camera_pose = get_node_or_null("FrontCameraPose")
@onready var floor_camera_pose := get_node_or_null("FloorCameraPose")

# -----------------------
# Custom nodes
# -----------------------
@onready var motors = get_node_or_null("Motors")
@onready var player_text_node: Label = get_node_or_null(
	"FrontProjector/UI/PlayerText"
)

# -----------------------
# Godot lifecycle
# -----------------------
func _ready():
	pass
	# Active la caméra principale
	#if second_camera:
		#second_camera.current = true 
	#if third_camera:
		#third_camera.current = true


func _process(_delta):
	if front_camera_pose:
		front_camera.global_transform = front_camera_pose.global_transform
	if floor_camera_pose:
		floor_camera.global_transform = floor_camera_pose.global_transform

func _physics_process(delta: float) -> void:
	var desired_linear_velocity := 0.0
	var desired_angular_velocity := 0.0

	# Keyboard navigation
	var keyboard_desired_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_desired_velocities[0]
	desired_angular_velocity += keyboard_desired_velocities[1]
	
	# Rollers navigation
	if motors != null:
		motors.receive()
		motors.send()
		desired_linear_velocity += motors.linear_velocity
		desired_angular_velocity += motors.angular_velocity

	# Appliquer les mouvements
	translate(Vector3(0, 0, -1) * desired_linear_velocity * delta)
	rotate(Vector3.UP, desired_angular_velocity * delta)

	# Affichage vitesse
	if motors and player_text_node:
		var text: String
		if motors.emergency_stop:
			text = "\nMotors OFF"
		else:
			text = str(abs(desired_linear_velocity)).pad_decimals(1) + " m/s"
		set_player_text(text)

# -----------------------
# Fonctions auxiliaires
# -----------------------
func get_keyboard_velocities() -> Array[float]:
	var linear := 0.0
	var angular := 0.0

	if Input.is_action_pressed("ui_up"):
		linear += KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_down"):
		linear -= KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_left"):
		angular += KB_ANGULAR_SPEED
	if Input.is_action_pressed("ui_right"):
		angular -= KB_ANGULAR_SPEED

	return [linear, angular]

func set_player_text(text: String):
	if player_text_node:
		player_text_node.text = text
