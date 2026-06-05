extends Control

@onready var name_input: LineEdit = $VBox/NameInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var create_btn: Button = $VBox/CreateBtn
@onready var join_btn: Button = $VBox/JoinBtn
@onready var room_input: LineEdit = $VBox/RoomInput
@onready var room_code_label: Label = $VBox/RoomCodeLabel

var _waiting_for_second := false
var _pending_action := ""  # "create" | "join"
var _pending_code := ""

var _character := "boy"
var _color := Color(0.3, 0.6, 1.0, 1)
var _char_btns := {}
var _color_btns := []
const COLORS := [
	Color(0.30, 0.60, 1.00),  # синий
	Color(0.95, 0.30, 0.30),  # красный
	Color(0.40, 0.85, 0.40),  # зелёный
	Color(1.00, 0.80, 0.25),  # жёлтый
	Color(0.80, 0.45, 0.95),  # фиолетовый
	Color(1.00, 0.55, 0.20),  # оранжевый
]

func _ready() -> void:
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.disconnected_from_server.connect(_on_disconnected)
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.error_occurred.connect(_on_error)

	_build_appearance_ui()
	_build_preview()
	_apply_appearance()
	_refresh_preview()
	_set_ui_enabled(true)
	status_label.text = "Введите имя, выберите героя и нажмите «Создать» или «Войти»"

const BOY_SCENE := preload("res://assets/characters/boy.glb")
const GIRL_SCENE := preload("res://assets/characters/girl.glb")
var _preview_pivot: Node3D
var _preview_anim: AnimationPlayer
var _preview_ring: MeshInstance3D

func _build_preview() -> void:
	# Рамка-панель слева
	var panel := Panel.new()
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 70
	panel.offset_top = -190
	panel.offset_right = 70 + 300
	panel.offset_bottom = 200
	panel.self_modulate = Color(0, 0, 0, 0.35)
	add_child(panel)

	var title := Label.new()
	title.text = "Твой герой"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_right = 1.0
	title.offset_top = 8
	title.offset_bottom = 34
	panel.add_child(title)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.anchor_right = 1.0
	svc.anchor_bottom = 1.0
	svc.offset_left = 10
	svc.offset_top = 40
	svc.offset_right = -10
	svc.offset_bottom = -10
	panel.add_child(svc)

	var sv := SubViewport.new()
	sv.transparent_bg = false
	sv.msaa_3d = Viewport.MSAA_4X
	sv.own_world_3d = true
	sv.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	svc.add_child(sv)

	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.look_at_from_position(Vector3(0, 1.0, 3.2), Vector3(0, 0.95, 0), Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.13, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.82, 0.95)
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	cam.environment = env
	sv.add_child(cam)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -130, 0)
	key.light_energy = 1.4
	sv.add_child(key)

	_preview_pivot = Node3D.new()
	sv.add_child(_preview_pivot)

func _refresh_preview() -> void:
	if _preview_pivot == null:
		return
	for c in _preview_pivot.get_children():
		c.queue_free()
	_preview_anim = null

	var scene: PackedScene = GIRL_SCENE if _character == "girl" else BOY_SCENE
	var model: Node3D = scene.instantiate()
	_preview_pivot.add_child(model)
	_normalize_preview(model)
	_preview_anim = _find_anim(model)
	if _preview_anim:
		for a in _preview_anim.get_animation_list():
			if a.to_lower().ends_with("idle"):
				_preview_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
				_preview_anim.play(a)
				break

	# Кольцо цвета у ног
	_preview_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.62
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 2.0
	torus.material = mat
	_preview_ring.mesh = torus
	_preview_ring.position = Vector3(0, 0.03, 0)
	_preview_pivot.add_child(_preview_ring)

func _normalize_preview(model: Node3D) -> void:
	var sk := _find_skel(model)
	if sk == null:
		return
	var to_local := model.global_transform.affine_inverse() * sk.global_transform
	var miny := INF
	var maxy := -INF
	for b in sk.get_bone_count():
		var lp: Vector3 = to_local * sk.get_bone_global_pose(b).origin
		miny = minf(miny, lp.y)
		maxy = maxf(maxy, lp.y)
	var h := maxy - miny
	if h <= 0.001:
		return
	var f := 1.7 / h
	model.scale = Vector3(f, f, f)
	model.position.y = -miny * f

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r = _find_skel(c)
		if r:
			return r
	return null

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r = _find_anim(c)
		if r:
			return r
	return null

func _process(delta: float) -> void:
	if _preview_pivot:
		_preview_pivot.rotation.y += delta * 0.6

func _build_appearance_ui() -> void:
	var vbox := $VBox
	# --- Выбор пола ---
	var char_row := HBoxContainer.new()
	char_row.alignment = BoxContainer.ALIGNMENT_CENTER
	char_row.add_theme_constant_override("separation", 12)
	for key in [["boy", "👦 Мальчик"], ["girl", "👧 Девочка"]]:
		var b := Button.new()
		b.text = key[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(170, 46)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_character_chosen.bind(key[0]))
		char_row.add_child(b)
		_char_btns[key[0]] = b
	vbox.add_child(char_row)
	vbox.move_child(char_row, 1)

	# --- Выбор цвета ---
	var color_row := HBoxContainer.new()
	color_row.alignment = BoxContainer.ALIGNMENT_CENTER
	color_row.add_theme_constant_override("separation", 8)
	for i in COLORS.size():
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(46, 46)
		var sb := StyleBoxFlat.new()
		sb.bg_color = COLORS[i]
		sb.set_corner_radius_all(8)
		sw.add_theme_stylebox_override("normal", sb)
		sw.add_theme_stylebox_override("hover", sb)
		sw.add_theme_stylebox_override("pressed", sb)
		sw.pressed.connect(_on_color_chosen.bind(i))
		color_row.add_child(sw)
		_color_btns.append(sw)
	vbox.add_child(color_row)
	vbox.move_child(color_row, 2)

func _on_character_chosen(c: String) -> void:
	_character = c
	_apply_appearance()
	_refresh_preview()

func _on_color_chosen(i: int) -> void:
	_color = COLORS[i]
	_apply_appearance()
	_refresh_preview()

func _apply_appearance() -> void:
	for key in _char_btns:
		_char_btns[key].button_pressed = (key == _character)
	# подсветка выбранного цвета — рамка
	for i in _color_btns.size():
		var sw: Button = _color_btns[i]
		var sb: StyleBoxFlat = sw.get_theme_stylebox("normal")
		if COLORS[i] == _color:
			sb.border_width_bottom = 4
			sb.border_width_top = 4
			sb.border_width_left = 4
			sb.border_width_right = 4
			sb.border_color = Color.WHITE
		else:
			sb.border_width_bottom = 0
			sb.border_width_top = 0
			sb.border_width_left = 0
			sb.border_width_right = 0
	NetworkManager.set_appearance(_character, _color)

func _on_name_submitted(_text: String) -> void:
	_connect()

func _connect() -> void:
	var pname = name_input.text.strip_edges()
	if pname.is_empty():
		status_label.text = "Введите имя!"
		return
	status_label.text = "Подключаемся к серверу..."
	_set_ui_enabled(false)
	NetworkManager.connect_to_server(pname)

func _on_connected() -> void:
	status_label.text = "Подключено."
	_set_ui_enabled(true)
	# Если пользователь успел кликнуть до подключения — выполним отложенное действие
	if _pending_action == "create":
		NetworkManager.create_room()
		status_label.text = "Создаём комнату..."
	elif _pending_action == "join":
		NetworkManager.join_room(_pending_code)
		status_label.text = "Входим в комнату %s..." % _pending_code
	_pending_action = ""
	_pending_code = ""

func _on_disconnected() -> void:
	status_label.text = "Соединение разорвано."
	_set_ui_enabled(false)

func _on_create_pressed() -> void:
	var pname = name_input.text.strip_edges()
	if pname.is_empty():
		status_label.text = "Введите имя!"
		return
	if NetworkManager.is_connected:
		NetworkManager.create_room()
		status_label.text = "Создаём комнату..."
	else:
		_pending_action = "create"
		status_label.text = "Подключаемся к серверу..."
		NetworkManager.connect_to_server(pname)

func _on_join_pressed() -> void:
	var pname = name_input.text.strip_edges()
	if pname.is_empty():
		status_label.text = "Введите имя!"
		return
	var code = room_input.text.strip_edges().to_upper()
	if code.is_empty():
		status_label.text = "Введите код комнаты!"
		return
	if NetworkManager.is_connected:
		NetworkManager.join_room(code)
		status_label.text = "Входим в комнату %s..." % code
	else:
		_pending_action = "join"
		_pending_code = code
		status_label.text = "Подключаемся к серверу..."
		NetworkManager.connect_to_server(pname)

func _on_room_created(code: String) -> void:
	room_code_label.text = "Код комнаты: %s" % code
	room_code_label.show()
	# Сразу подставляем код в поле — удобно скопировать и продиктовать
	room_input.text = code
	status_label.text = "Комната создана! Передайте код: %s. Ждём второго игрока..." % code
	_waiting_for_second = true

func _on_room_joined(code: String, _players: Array) -> void:
	room_code_label.text = "Комната: %s" % code
	room_code_label.show()
	status_label.text = "Вошли в комнату! Загружаем мир..."
	_start_game()

func _on_player_joined(_id: String, pname: String) -> void:
	if _waiting_for_second:
		status_label.text = "%s присоединился! Загружаем мир..." % pname
		_waiting_for_second = false
		_start_game()

func _on_error(msg: String) -> void:
	status_label.text = "Ошибка: %s" % msg
	_set_ui_enabled(true)

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _set_ui_enabled(enabled: bool) -> void:
	create_btn.disabled = not enabled
	join_btn.disabled = not enabled
	room_input.editable = enabled
