extends CharacterBody3D

const SPEED := 5.0
const GRAVITY := -20.0
const JUMP_VELOCITY := 7.5
const SEND_INTERVAL := 0.05  # 20 раз в секунду
const MOUSE_SENSITIVITY := 0.0035
const PITCH_MIN := -1.0
const PITCH_MAX := 0.5

var _cam_pitch := -0.15

const INTERACT_RANGE := 2.5

var is_local := false
var player_id := ""
var player_name := ""
var _send_timer := 0.0
var _label: Label3D
var _nearest_interactable: Node = null

signal interactable_changed(interactable: Node)
signal dialog_requested(npc_name: String, text: String)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var astronaut: Node3D = $Astronaut

# Параметры процедурной анимации шагов
const STEP_FREQUENCY := 8.0   # сколько шагов в секунду на полной скорости
const STEP_BOB := 0.06        # высота "подпрыгивания"
const STEP_TILT := 0.12       # амплитуда наклона корпуса (радианы)
var _step_phase := 0.0
var _astro_base_y := 0.0

func _ready() -> void:
	if is_local:
		if camera:
			camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if camera:
			camera.current = false
	_create_name_label()
	if astronaut:
		_astro_base_y = astronaut.position.y

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw мыши поворачивает самого персонажа — тело всегда смотрит туда же, куда камера
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_cam_pitch -= event.relative.y * MOUSE_SENSITIVITY
		_cam_pitch = clamp(_cam_pitch, PITCH_MIN, PITCH_MAX)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_F11:
			var w := get_window()
			if w.mode == Window.MODE_FULLSCREEN:
				w.mode = Window.MODE_MAXIMIZED
			else:
				w.mode = Window.MODE_FULLSCREEN

func _create_name_label() -> void:
	_label = Label3D.new()
	_label.text = player_name
	_label.position = Vector3(0, 2.2, 0)
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 32
	add_child(_label)

func setup(p_id: String, p_name: String, local: bool) -> void:
	player_id = p_id
	player_name = p_name
	is_local = local

func _physics_process(delta: float) -> void:
	_animate_steps(delta)
	if not is_local:
		return

	# Pitch применяется к камере, yaw уже на самом теле
	camera.rotation.x = _cam_pitch

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y += GRAVITY * delta

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Движение относительно направления тела (которое = направлению камеры)
		var forward = -transform.basis.z
		var right = transform.basis.x
		var move_dir = (forward * -input_dir.y + right * input_dir.x).normalized()
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	_update_interactable()

	if Input.is_action_just_pressed("interact") and _nearest_interactable:
		_trigger_interact(_nearest_interactable)

	_send_timer += delta
	if _send_timer >= SEND_INTERVAL:
		_send_timer = 0.0
		NetworkManager.send_position(global_position, rotation.y)

func apply_remote_state(pos: Vector3, rot_y: float) -> void:
	global_position = global_position.lerp(pos, 0.3)
	rotation.y = lerp_angle(rotation.y, rot_y, 0.3)

func _animate_steps(delta: float) -> void:
	if not astronaut:
		return
	# Скорость по горизонтали — основа цикла шагов
	var horiz := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clamp(horiz / SPEED, 0.0, 1.0)
	if speed_ratio > 0.05:
		_step_phase += delta * STEP_FREQUENCY * speed_ratio
	# Bob (вертикальное подскакивание)
	var bob := abs(sin(_step_phase)) * STEP_BOB * speed_ratio
	astronaut.position.y = _astro_base_y + bob
	# Tilt (покачивание влево-вправо в такт)
	var tilt := sin(_step_phase) * STEP_TILT * speed_ratio
	astronaut.rotation.z = tilt

func _update_interactable() -> void:
	var best: Node = null
	var best_dist := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node3D):
			continue
		var d = global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	if best != _nearest_interactable:
		_nearest_interactable = best
		emit_signal("interactable_changed", best)

func _trigger_interact(target: Node) -> void:
	if target.has_signal("dialog_requested") and not target.is_connected("dialog_requested", _on_dialog_requested):
		target.dialog_requested.connect(_on_dialog_requested)
	if target.has_method("interact"):
		target.interact(self)

func _on_dialog_requested(npc_name: String, text: String) -> void:
	emit_signal("dialog_requested", npc_name, text)
