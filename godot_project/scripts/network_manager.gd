extends Node

# Список адресов, которые клиент пробует по очереди.
# Первый, к которому удалось подключиться — побеждает.
# - localhost   → когда сервер запущен на этом же ПК
# - 192.168.1.72 → основной Mac в локальной сети (где сервер)
# - 194.85.251.132 → VPS (когда задеплоено)
const SERVER_URLS := [
	"ws://localhost:8765",
	"ws://192.168.1.72:8765",
	"ws://194.85.251.132:8765",
]
const CONNECT_TIMEOUT := 2.5  # сек на попытку

signal connected_to_server
signal disconnected_from_server
signal room_created(room_code: String)
signal room_joined(room_code: String, players: Array)
signal player_joined(player_id: String, player_name: String)
signal player_left(player_id: String)
signal player_moved(player_id: String, position: Vector3, rotation: float)
signal item_collected(quest_id: String, item_id: String, by_id: String)
signal initial_collected_received(items: Array)
signal launch_progress(have: int, required: int)
signal launch_now
signal error_occurred(message: String)

var socket := WebSocketPeer.new()
var my_id := ""
var my_name := ""
var room_code := ""
var is_connected := false
var initial_players: Array = []  # игроки, бывшие в комнате до нашего входа
var room_players: Dictionary = {}  # id → name, все известные игроки комнаты (кроме нас)
var initial_collected: Array = []  # ["quest_id:item_id", ...] на момент входа
var _state := WebSocketPeer.STATE_CLOSED
var _try_index := -1
var _try_started_at := 0.0
var _trying := false

func _ready() -> void:
	set_process(true)

func connect_to_server(player_name: String) -> void:
	my_name = player_name
	_try_index = -1
	_trying = true
	_try_next()

func _try_next() -> void:
	_try_index += 1
	if _try_index >= SERVER_URLS.size():
		_trying = false
		emit_signal("error_occurred", "Не удалось подключиться ни к одному серверу")
		return
	var url: String = SERVER_URLS[_try_index]
	print("[NET] Trying ", url, " ...")
	socket = WebSocketPeer.new()
	_state = WebSocketPeer.STATE_CLOSED
	var err = socket.connect_to_url(url)
	_try_started_at = Time.get_ticks_msec() / 1000.0
	if err != OK:
		print("[NET] connect_to_url failed for ", url, " err=", err)
		_try_next()

func create_room() -> void:
	_send({"action": "create_room", "name": my_name})

func join_room(code: String) -> void:
	_send({"action": "join_room", "code": code, "name": my_name})

func send_collect_item(quest_id: String, item_id: String) -> void:
	_send({"action": "collect_item", "quest_id": quest_id, "item_id": item_id})

func send_launch_vote() -> void:
	_send({"action": "launch_vote"})

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

	# Таймаут попытки подключения
	if _trying and state == WebSocketPeer.STATE_CONNECTING:
		var now = Time.get_ticks_msec() / 1000.0
		if now - _try_started_at > CONNECT_TIMEOUT:
			print("[NET] Timeout on ", SERVER_URLS[_try_index])
			socket.close()
			_try_next()
			return

	if state != _state:
		_on_state_changed(state)
		_state = state

	while socket.get_available_packet_count() > 0:
		var packet = socket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_message(text)

func _on_state_changed(state: int) -> void:
	print("[NET] State changed → ", state, " (", _state_name(state), ")")
	match state:
		WebSocketPeer.STATE_OPEN:
			is_connected = true
			_trying = false
			print("[NET] Connected to ", SERVER_URLS[_try_index])
			emit_signal("connected_to_server")
		WebSocketPeer.STATE_CLOSED:
			is_connected = false
			# Если соединение умерло во время попыток — пробуем следующий адрес
			if _trying:
				print("[NET] Closed while trying ", SERVER_URLS[_try_index], " — next")
				_try_next()
				return
			emit_signal("disconnected_from_server")

func _state_name(s: int) -> String:
	match s:
		WebSocketPeer.STATE_CONNECTING: return "CONNECTING"
		WebSocketPeer.STATE_OPEN: return "OPEN"
		WebSocketPeer.STATE_CLOSING: return "CLOSING"
		WebSocketPeer.STATE_CLOSED: return "CLOSED"
	return "?"

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
			initial_collected = data.get("collected", [])
			room_players.clear()
			for p in players:
				room_players[p.get("id", "")] = p.get("name", "Космонавт")
			emit_signal("room_joined", room_code, players)
			emit_signal("initial_collected_received", initial_collected)
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
		"item_collected":
			emit_signal("item_collected", data.get("quest_id", ""), data.get("item_id", ""), data.get("by", ""))
		"launch_progress":
			emit_signal("launch_progress", int(data.get("have", 0)), int(data.get("required", 0)))
		"launch_now":
			emit_signal("launch_now")
		"error":
			emit_signal("error_occurred", data.get("message", "Неизвестная ошибка"))
