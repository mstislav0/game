extends Node

# Адрес WebSocket-сервера
const SERVER_URL = "ws://localhost:8765"

signal connected_to_server
signal disconnected_from_server
signal room_created(room_code: String)
signal room_joined(room_code: String, players: Array)
signal player_joined(player_id: String, player_name: String)
signal player_left(player_id: String)
signal player_moved(player_id: String, position: Vector3, rotation: float)
signal error_occurred(message: String)

var socket := WebSocketPeer.new()
var my_id := ""
var my_name := ""
var room_code := ""
var is_connected := false
var initial_players: Array = []  # игроки, бывшие в комнате до нашего входа
var room_players: Dictionary = {}  # id → name, все известные игроки комнаты (кроме нас)
var _state := WebSocketPeer.STATE_CLOSED

func _ready() -> void:
	set_process(true)

func connect_to_server(player_name: String) -> void:
	my_name = player_name
	var err = socket.connect_to_url(SERVER_URL)
	if err != OK:
		emit_signal("error_occurred", "Не удалось подключиться к серверу")

func create_room() -> void:
	_send({"action": "create_room", "name": my_name})

func join_room(code: String) -> void:
	_send({"action": "join_room", "code": code, "name": my_name})

func send_position(position: Vector3, rotation_y: float) -> void:
	_send({
		"action": "move",
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"ry": rotation_y
	})

func _send(data: Dictionary) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))

func _process(_delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state != _state:
		_on_state_changed(state)
		_state = state

	while socket.get_available_packet_count() > 0:
		var packet = socket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_message(text)

func _on_state_changed(state: int) -> void:
	match state:
		WebSocketPeer.STATE_OPEN:
			is_connected = true
			emit_signal("connected_to_server")
		WebSocketPeer.STATE_CLOSED:
			is_connected = false
			emit_signal("disconnected_from_server")

func _handle_message(text: String) -> void:
	var data = JSON.parse_string(text)
	if data == null:
		return

	match data.get("event", ""):
		"connected":
			my_id = data.get("id", "")
		"room_created":
			room_code = data.get("code", "")
			room_players.clear()
			emit_signal("room_created", room_code)
		"room_joined":
			room_code = data.get("code", "")
			var players = data.get("players", [])
			initial_players = players
			room_players.clear()
			for p in players:
				room_players[p.get("id", "")] = p.get("name", "Космонавт")
			emit_signal("room_joined", room_code, players)
		"player_joined":
			var pid = data.get("id", "")
			var pname = data.get("name", "Космонавт")
			room_players[pid] = pname
			emit_signal("player_joined", pid, pname)
		"player_left":
			var pid = data.get("id", "")
			room_players.erase(pid)
			emit_signal("player_left", pid)
		"player_moved":
			var pos = Vector3(
				data.get("x", 0.0),
				data.get("y", 0.0),
				data.get("z", 0.0)
			)
			emit_signal("player_moved", data.get("id", ""), pos, data.get("ry", 0.0))
		"error":
			emit_signal("error_occurred", data.get("message", "Неизвестная ошибка"))
