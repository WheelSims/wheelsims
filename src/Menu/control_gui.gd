extends Control

@export var SIMULATOR_USERS_FILENAME = "user://simulator_users.json"

# --- UI users ---
@onready var patient_list := $Panel/UserManagement/UserManagement/ScrollContainer/UserList

# --- UI DBox ---
@onready var btn_dbox      := $Panel/DBox/Mode
@onready var btn_dbox_up   := $Panel/DBox/DBox/Down
@onready var btn_dbox_down := $Panel/DBox/DBox/Up

# --- DBox manuel ---
var dbox_manual_mode := false
var manual_heave := 0.0
var dbox_step := 0.02

# --- maintien appuyé ---
var dbox_hold_dir := 0
var dbox_speed := 0.2

# --- Scène de ligne patient ---
var user_row := preload("user.tscn")

func _ready() -> void:
	# Patients
	load_users()

	# DBox
	btn_dbox.pressed.connect(_on_btn_dbox_pressed)
	btn_dbox_up.button_down.connect(_on_dbox_up_button_down)
	btn_dbox_up.button_up.connect(_on_dbox_button_up)
	btn_dbox_down.button_down.connect(_on_dbox_down_button_down)
	btn_dbox_down.button_up.connect(_on_dbox_button_up)
	btn_dbox_up.visible = false
	btn_dbox_down.visible = false


func _process(delta: float) -> void:
	if dbox_manual_mode and dbox_hold_dir != 0:
		var new_heave := clampf(manual_heave + dbox_speed * dbox_hold_dir * delta, -0.5, 0.5)
		if absf(new_heave - manual_heave) > 0.0001:
			manual_heave = new_heave
			_send_heave_target()

# -------------------------------------------------------------------
# Helpers : récupération du player et du nœud DBox
# -------------------------------------------------------------------
func _get_player() -> Node:
	var root := get_tree().get_root()

	var n := root.get_node_or_null("ParkOnSimulator/PlayerOnSimulator")
	if n and n.has_node("DBox"):
		return n

	n = root.get_node_or_null("PlayerOnSimulator")
	if n and n.has_node("DBox"):
		return n

	for child in root.get_children():
		if child.name == "PlayerOnSimulator" and child.has_node("DBox"):
			return child
		if child.has_node("PlayerOnSimulator"):
			var p := child.get_node_or_null("PlayerOnSimulator")
			if p and p.has_node("DBox"):
				return p

	n = root.get_node_or_null("ParkOnKeyboard/PlayerOnKeyboard")
	if n and n.has_node("DBox"):
		return n
	n = root.get_node_or_null("PlayerOnKeyboard")
	if n and n.has_node("DBox"):
		return n

	return null

func _get_dbox_node() -> Node:
	var p := _get_player()
	if p:
		var d := p.get_node_or_null("DBox")
		if d:
			return d
	print("⚠️ DBox introuvable : player trouvé =", p)
	return null

# -------------------------------------------------------------------
# User management
# -------------------------------------------------------------------
func _on_btn_add_user_pressed() -> void:
	var new_row := user_row.instantiate()

	new_row.get_node("Name").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("Name").connect("focus_exited",   Callable(self, "save_users"))
	new_row.get_node("LineWheelDist").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("LineWheelDist").connect("focus_exited",   Callable(self, "save_users"))
	new_row.get_node("LineMass").connect("text_submitted", Callable(self, "save_users"))
	new_row.get_node("LineMass").connect("focus_exited",   Callable(self, "save_users"))

	# Sélection unique : bind de la row
	new_row.get_node("CheckBox").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))

	patient_list.add_child(new_row)

func _on_btn_remove_user_pressed() -> void:
	if patient_list.get_child_count() > 0:
		var last_row := patient_list.get_child(patient_list.get_child_count() - 1)
		patient_list.remove_child(last_row)
		last_row.queue_free()
		save_users()
		_enforce_single_selection()

func save_users() -> void:
	var data: Array[Dictionary] = []
	for row in patient_list.get_children():
		data.append({
			"name": (row.get_node("Name") as LineEdit).text,
			"wheel_distance": (row.get_node("LineWheelDist") as LineEdit).text.to_float(),
			"mass": (row.get_node("LineMass") as LineEdit).text.to_float(),
			"selected": (row.get_node("CheckBox") as CheckBox).button_pressed
		})
	var file := FileAccess.open(SIMULATOR_USERS_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("User saved.")

func load_users() -> void:
	if not FileAccess.file_exists(SIMULATOR_USERS_FILENAME):
		return

	var file := FileAccess.open(SIMULATOR_USERS_FILENAME, FileAccess.READ)
	var parsed_v: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed_v) != TYPE_ARRAY:
		print("User file " + SIMULATOR_USERS_FILENAME + " seems corrupted.")
		return
	var result: Array = parsed_v

	for user in result:
		var patient: Dictionary = user as Dictionary
		var new_row := user_row.instantiate()

		(new_row.get_node("Name") as LineEdit).text = str(patient.get("name", ""))
		(new_row.get_node("LineWheelDist") as LineEdit).text = str(patient.get("wheel_distance", ""))
		(new_row.get_node("LineMass") as LineEdit).text = str(patient.get("mass", ""))
		(new_row.get_node("CheckBox") as CheckBox).button_pressed = bool(patient.get("selected", false))

		new_row.get_node("Name").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("Name").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("LineWheelDist").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("LineWheelDist").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("LineMass").connect("text_submitted", Callable(self, "save_users"))
		new_row.get_node("LineMass").connect("focus_exited",   Callable(self, "save_users"))
		new_row.get_node("CheckBox").connect("toggled", Callable(self, "_on_row_checkbox_toggled").bind(new_row))

		patient_list.add_child(new_row)

	_enforce_single_selection()

# -------------------------------------------------------------------
# Lancement PARK + plein écran sans bordure
# -------------------------------------------------------------------
func _kill_existing_simulators() -> void:
	var root := get_tree().get_root()
	var prefixes := ["ParkOnSimulator", "PlayerOnSimulator", "ParkOnKeyboard", "PlayerOnKeyboard"]
	for child in root.get_children():
		for p in prefixes:
			if child.name.begins_with(p):
				child.queue_free()
				break

func _on_button_park_pressed() -> void:
	_kill_existing_simulators()

	await get_tree().process_frame
	await get_tree().process_frame

	var park_instance := preload("res://park_on_simulator.tscn").instantiate()
	park_instance.name = "ParkOnSimulator"
	get_tree().get_root().add_child(park_instance)

	var screen_count: int = DisplayServer.get_screen_count()

	var second_window := park_instance.get_node_or_null("PlayerOnSimulator/SecondDisplayWindow") as Window
	if second_window and screen_count > 1:
		_prepare_display_window(second_window, 1)

	var third_window := park_instance.get_node_or_null("PlayerOnSimulator/ThirdDisplayWindow") as Window
	if third_window and screen_count > 2:
		_prepare_display_window(third_window, 2)

# Met la Window en plein écran exclusif sur l'écran demandé
# et adapte SubViewportContainer/SubViewport pour remplir la fenêtre.
func _prepare_display_window(win: Window, screen_index: int) -> void:
	win.set_current_screen(screen_index)
	win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	_fit_subviewport_to_window(win)
	if not win.is_connected("size_changed", Callable(self, "_on_display_window_resized")):
		win.size_changed.connect(_on_display_window_resized.bind(win))

func _fit_subviewport_to_window(win: Window) -> void:
	var container := win.get_node_or_null("SubViewportContainer") as SubViewportContainer
	if container:
		# Godot 4 -> utiliser set_anchors_preset, pas anchors_preset(...)
		container.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		container.offset_left = 0
		container.offset_top = 0
		container.offset_right = 0
		container.offset_bottom = 0

	var sv := win.get_node_or_null("SubViewportContainer/SubViewport") as SubViewport
	if sv:
		sv.size = Vector2i(win.size.x, win.size.y)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sv.disable_3d = false
		sv.own_world_3d = false

func _on_display_window_resized(win: Window) -> void:
	var sv := win.get_node_or_null("SubViewportContainer/SubViewport") as SubViewport
	if sv:
		sv.size = Vector2i(win.size.x, win.size.y)


func _on_button_stop_pressed() -> void:
	get_tree().quit()

# -------------------------------------------------------------------
# Masse du patient sélectionné
# -------------------------------------------------------------------
func update_selected_patient_mass() -> void:
	for row in patient_list.get_children():
		if (row.get_node("CheckBox") as CheckBox).button_pressed:
			var player := _get_player()
			if player:
				player.mass = (row.get_node("LineMass") as LineEdit).text.to_float()
				print("Updated user mass to ", player.mass)
			else:
				print("Player not found.")

# -------------------------------------------------------------------
# DBox : manuel + maintien
# -------------------------------------------------------------------
func _on_btn_dbox_pressed() -> void:
	dbox_manual_mode = !dbox_manual_mode
	btn_dbox.text = "DBox : Manual" if dbox_manual_mode else "DBox : Auto"
	btn_dbox_up.visible = dbox_manual_mode
	btn_dbox_down.visible = dbox_manual_mode
	dbox_hold_dir = 0
	var dbox := _get_dbox_node()
	print("Toggle DBox manual ->", dbox_manual_mode, " | dbox=", dbox)
	if dbox:
		dbox.manual_mode = dbox_manual_mode
		if not dbox_manual_mode:
			manual_heave = 0.0
			dbox.manual_target_heave = 0.0

func _on_dbox_up_button_down() -> void:
	if dbox_manual_mode:
		dbox_hold_dir = +1

func _on_dbox_down_button_down() -> void:
	if dbox_manual_mode:
		dbox_hold_dir = -1

func _on_dbox_button_up() -> void:
	dbox_hold_dir = 0
	_send_heave_target()

func _send_heave_target() -> void:
	var dbox := _get_dbox_node()
	if dbox:
		dbox.manual_target_heave = manual_heave
		dbox.send(7, manual_heave, 0.0, 0.0)
		print("DBox MANUAL heave =", manual_heave, "  path=", dbox.get_path())
	else:
		print("DBox introuvable (chemin) — scène/chemins à vérifier")


# =========================
# Sélection unique patients
# =========================
func _on_row_checkbox_toggled(pressed: bool, row: Node) -> void:
	if pressed:
		for other in patient_list.get_children():
			if other != row:
				var ocb := other.get_node("CheckBox") as CheckBox
				if ocb.button_pressed:
					ocb.button_pressed = false
	save_users()
	update_selected_patient_mass()

func _enforce_single_selection(preferred_row: Node = null) -> void:
	var found := false
	for row in patient_list.get_children():
		var cb := row.get_node("CheckBox") as CheckBox
		if preferred_row and row == preferred_row:
			if cb.button_pressed and not found:
				found = true
			elif cb.button_pressed and found:
				cb.button_pressed = false
			continue
		if cb.button_pressed:
			if found:
				cb.button_pressed = false
			else:
				found = true
