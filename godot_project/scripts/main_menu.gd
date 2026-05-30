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

func _ready() -> void:
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.disconnected_from_server.connect(_on_disconnected)
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.room_joined.connect(_on_room_joined)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.error_occurred.connect(_on_error)

	_set_ui_enabled(true)
	status_label.text = "Введите имя и нажмите «Создать» или «Войти»"

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
	status_label.text = "Комната создана! Ждём второго игрока..."
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
