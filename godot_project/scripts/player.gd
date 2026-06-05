extends CharacterBody3D

const SPEED := 5.0
const RUN_SPEED := 8.0
const GRAVITY := -20.0
const JUMP_VELOCITY := 7.5
const SEND_INTERVAL := 0.05  # 20 раз в секунду
const MOUSE_SENSITIVITY := 0.0035
const PITCH_MIN := -1.0
const PITCH_MAX := 0.5
const INTERACT_RANGE := 2.5

const BOY_SCENE := preload("res://assets/characters/boy.glb")
const GIRL_SCENE := preload("res://assets/characters/girl.glb")
const TARGET_HEIGHT := 1.7  # рост персонажа в метрах (автонормализация модели)

var _cam_pitch := -0.15

var is_local := false
var player_id := ""
var player_name := ""
var character_type := "boy"
var player_color := Color(0.3, 0.6, 1.0, 1)

var _send_timer := 0.0
var _label: Label3D
var _nearest_interactable: Node = null

# Анимация
var _model: Node3D
var _anim: AnimationPlayer
var _a_idle := ""
var _a_walk := ""
var _a_run := ""
var _a_jump := ""
var _cur_anim := ""
# Для удалённых игроков — скорость считаем из дельты позиции
var _remote_prev_pos := Vector3.ZERO
var _remote_speed := 0.0

signal interactable_changed(interactable: Node)
signal dialog_requested(npc_name: String, text: String)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

func setup(p_id: String, p_name: String, local: bool, p_character := "boy", p_color := Color(0.3, 0.6, 1.0, 1)) -> void:
	player_id = p_id
	player_name = p_name
	is_local = local
	character_type = p_character
	player_color = p_color

func _ready() -> void:
	if is_local:
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
	_spawn_model()
	_create_name_label()
	_create_color_ring()
	_remote_prev_pos = global_position

func _spawn_model() -> void:
	var scene: PackedScene = GIRL_SCENE if character_type == "girl" else BOY_SCENE
	_model = scene.instantiate()
	add_child(_model)
	# Модели Quaternius смотрят в +Z, а "перёд" тела игрока — это -Z,
	# поэтому разворачиваем модель на 180°, иначе персонаж "идёт задом наперёд".
	_model.rotation.y = PI
	_normalize_model_height()
	_anim = _find_anim_player(_model)
	if _anim:
		for a in _anim.get_animation_list():
			var la := a.to_lower()
			if _a_idle == "" and la.ends_with("idle"):
				_a_idle = a
			elif _a_walk == "" and la.contains("walk"):
				_a_walk = a
			elif _a_run == "" and la.contains("run"):
				_a_run = a
			elif _a_jump == "" and la.contains("jump"):
				_a_jump = a
		for a in [_a_idle, _a_walk, _a_run]:
			if a != "" and _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_play_anim(_a_idle)

func _normalize_model_height() -> void:
	# Приводим любую модель к росту TARGET_HEIGHT и ставим ступни на y=0,
	# измеряя реальный размер по костям скелета (надёжно для skinned-мешей).
	var sk := _find_skeleton(_model)
	if sk == null:
		return
	var to_local := _model.global_transform.affine_inverse() * sk.global_transform
	var miny := INF
	var maxy := -INF
	for b in sk.get_bone_count():
		var lp: Vector3 = to_local * sk.get_bone_global_pose(b).origin
		miny = minf(miny, lp.y)
		maxy = maxf(maxy, lp.y)
	var h := maxy - miny
	if h <= 0.001:
		return
	var f := TARGET_HEIGHT / h
	_model.scale = Vector3(f, f, f)
	_model.position.y = -miny * f

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var r = _find_skeleton(c)
		if r:
			return r
	return null

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r = _find_anim_player(c)
		if r:
			return r
	return null

func _play_anim(anim_name: String) -> void:
	if _anim == null or anim_name == "" or anim_name == _cur_anim:
		return
	if not _anim.has_animation(anim_name):
		return
	_cur_anim = anim_name
	_anim.play(anim_name, 0.15)

func _create_name_label() -> void:
	_label = Label3D.new()
	_label.text = player_name
	_label.position = Vector3(0, 2.1, 0)
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 32
	_label.outline_size = 6
	_label.modulate = player_color.lightened(0.3)
	add_child(_label)

func _create_color_ring() -> void:
	# Светящееся кольцо у ног — отметка цвета игрока (видно в кооперативе)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = player_color
	mat.emission_enabled = true
	mat.emission = player_color
	mat.emission_energy_multiplier = 1.5
	torus.material = mat
	ring.mesh = torus
	ring.position = Vector3(0, 0.05, 0)
	add_child(ring)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
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

func _physics_process(delta: float) -> void:
	if not is_local:
		_animate_remote(delta)
		return

	camera.rotation.x = _cam_pitch

	var on_floor := is_on_floor()
	if on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	elif not on_floor:
		velocity.y += GRAVITY * delta

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	var running := Input.is_key_pressed(KEY_SHIFT)
	var spd := RUN_SPEED if running else SPEED

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var forward := -transform.basis.z
		var right := transform.basis.x
		var move_dir := (forward * -input_dir.y + right * input_dir.x).normalized()
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0, spd)
		velocity.z = move_toward(velocity.z, 0, spd)

	move_and_slide()

	_update_animation(on_floor, running)
	_update_interactable()

	if Input.is_action_just_pressed("interact") and _nearest_interactable:
		_trigger_interact(_nearest_interactable)

	_send_timer += delta
	if _send_timer >= SEND_INTERVAL:
		_send_timer = 0.0
		NetworkManager.send_position(global_position, rotation.y)

func _update_animation(on_floor: bool, running: bool) -> void:
	if not on_floor and _a_jump != "":
		_play_anim(_a_jump)
		return
	var horiz := Vector2(velocity.x, velocity.z).length()
	if horiz < 0.3:
		_play_anim(_a_idle)
	elif running and _a_run != "":
		_play_anim(_a_run)
	else:
		_play_anim(_a_walk)

func apply_remote_state(pos: Vector3, rot_y: float) -> void:
	global_position = global_position.lerp(pos, 0.3)
	rotation.y = lerp_angle(rotation.y, rot_y, 0.3)

func _animate_remote(delta: float) -> void:
	# Скорость удалённого игрока — из перемещения за кадр
	var moved := (global_position - _remote_prev_pos).length()
	_remote_prev_pos = global_position
	var inst_speed: float = moved / maxf(delta, 0.0001)
	_remote_speed = lerpf(_remote_speed, inst_speed, 0.3)
	if _remote_speed < 0.4:
		_play_anim(_a_idle)
	elif _remote_speed > 6.0 and _a_run != "":
		_play_anim(_a_run)
	else:
		_play_anim(_a_walk)

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
