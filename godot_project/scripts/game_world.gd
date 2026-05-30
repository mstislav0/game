extends Node3D

const Player = preload("res://scenes/player.tscn")

var players: Dictionary = {}  # player_id → Node

@onready var spawn_points := [
	Vector3(0, 0.5, 0),
	Vector3(3, 0.5, 0),
	Vector3(-3, 0.5, 0),
	Vector3(0, 0.5, 3),
]
var _spawn_index := 0

func _ready() -> void:
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.player_moved.connect(_on_player_moved)

	# Спаунимся сами
	_spawn_local_player()

	# Спауним всех остальных игроков комнаты, известных на этот момент
	for pid in NetworkManager.room_players.keys():
		_on_player_joined(pid, NetworkManager.room_players[pid])

func _spawn_local_player() -> void:
	var spawn_pos = spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1

	var p = Player.instantiate()
	p.setup(NetworkManager.my_id, NetworkManager.my_name, true)
	p.global_position = spawn_pos
	add_child(p)
	players[NetworkManager.my_id] = p

	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("bind_local_player"):
		hud.bind_local_player(p)

func _on_player_joined(player_id: String, player_name: String) -> void:
	if players.has(player_id):
		return
	var spawn_pos = spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1

	var p = Player.instantiate()
	p.setup(player_id, player_name, false)
	p.global_position = spawn_pos
	add_child(p)
	players[player_id] = p

func _on_player_left(player_id: String) -> void:
	if players.has(player_id):
		players[player_id].queue_free()
		players.erase(player_id)

func _on_player_moved(player_id: String, position: Vector3, rotation_y: float) -> void:
	if players.has(player_id) and player_id != NetworkManager.my_id:
		players[player_id].apply_remote_state(position, rotation_y)
