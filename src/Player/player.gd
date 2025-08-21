extends RigidBody3D

# ------------------
# Editable constants
# ------------------

@export_group("Keyboard Control")
@export var KB_LINEAR_SPEED: float = 2  # m/s
@export var KB_ANGULAR_SPEED: float = 1  # rad/s

# -----------------------
# Caméras
# -----------------------
@onready var main_camera := $Camera3DFace  # Caméra pour la fenêtre principale
@onready var tracked_camera := $Camera3DBas  # Caméra que la seconde va suivre
@onready var second_camera := $SecondDisplayWindow/SubViewportContainer/SubViewport/SecondCamera  # Caméra dans SubViewport
@onready var third_camera := $ThirdDisplayWindow/SubViewportContainer/SubViewport/ThirdCamera  # Caméra dans SubViewport

# -----------------------
# Custom nodes
# -----------------------
@onready var motors = get_node_or_null("Motors")
@onready var player_text_node: Label = get_node_or_null(
	"ThirdDisplayWindow/SubViewportContainer/SubViewport/UI/PlayerText"
)

# -----------------------
# Godot lifecycle
# -----------------------
func _ready():
	# Active la caméra principale
	if second_camera:
		second_camera.current = true 
	if third_camera:
		third_camera.current = true


func _process(_delta):
	# Synchronise la caméra du SubViewport avec une caméra du joueur
	if second_camera and tracked_camera:
		second_camera.global_transform = tracked_camera.global_transform
	if third_camera and main_camera:
		third_camera.global_transform = main_camera.global_transform

func _physics_process(delta: float) -> void:
	var desired_linear_velocity := 0.0
	var desired_angular_velocity := 0.0

	# Contrôle clavier
	var keyboard_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_velocities[0]
	desired_angular_velocity += keyboard_velocities[1]

	# Contrôle simulateur (rollers)
	if motors:
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
