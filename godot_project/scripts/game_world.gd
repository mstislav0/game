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

@onready var rocket: Node3D = get_node_or_null("Rocket")

func _ready() -> void:
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.player_moved.connect(_on_player_moved)
	NetworkManager.launch_now.connect(_play_launch_animation)

	# Спаунимся сами ПЕРВЫМ ДЕЛОМ — чтобы любая последующая ошибка не лишила нас камеры
	_spawn_local_player()

	# Спауним всех остальных игроков комнаты, известных на этот момент
	for pid in NetworkManager.room_players.keys():
		_on_player_joined(pid, NetworkManager.room_players[pid])

	# Коллизии для ракеты и стартовых ферм (чтобы не проходить сквозь них)
	for nm in ["Rocket", "GantryA", "GantryB", "GantryC", "GantryD"]:
		var n = get_node_or_null(nm)
		if n:
			_build_collisions_for(n)

func _build_collisions_for(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh != null:
			child.create_trimesh_collision()
		else:
			_build_collisions_for(child)

func _play_launch_animation() -> void:
	# Запрашиваем у HUD кат-сцену (отсчёт + fade)
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("play_launch_cutscene"):
		hud.play_launch_cutscene()

	# Отключаем управление у локального игрока
	var local = players.get(NetworkManager.my_id)
	if local:
		local.set_physics_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Привязываем всех игроков к ракете — полетят вместе
	for pid in players:
		var p = players[pid]
		if p and p is Node3D:
			var world_xform: Transform3D = p.global_transform
			if p.get_parent() != rocket:
				p.reparent(rocket, true)
			p.global_transform = world_xform

	# Кокпит тоже летит с ракетой
	var cockpit = get_node_or_null("Cockpit")
	if cockpit:
		var c_xform: Transform3D = cockpit.global_transform
		cockpit.reparent(rocket, true)
		cockpit.global_transform = c_xform

	# Отсчёт 3-2-1 (HUD сам показывает), ракета стоит
	await get_tree().create_timer(3.5).timeout

	# Взлёт: ускоряющееся движение вверх
	var start_y := rocket.position.y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(rocket, "position:y", start_y + 300.0, 4.5)

	# Камера-шейк
	if local and local.has_node("CameraPivot/Camera3D"):
		_shake_camera(local.get_node("CameraPivot/Camera3D"), 4.5)

	await tween.finished
	await get_tree().create_timer(0.3).timeout

	# Переход на сцену Космоса
	get_tree().change_scene_to_file("res://scenes/space.tscn")

func _shake_camera(cam: Camera3D, duration: float) -> void:
	var orig := cam.position
	var t := 0.0
	while t < duration:
		var amp = lerp(0.05, 0.25, t / duration)
		cam.position = orig + Vector3(
			randf_range(-amp, amp),
			randf_range(-amp, amp),
			0
		)
		await get_tree().process_frame
		t += get_process_delta_time()
	cam.position = orig

func _spawn_local_player() -> void:
	var spawn_pos = spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1

	var p = Player.instantiate()
	p.setup(NetworkManager.my_id, NetworkManager.my_name, true, NetworkManager.my_character, NetworkManager.my_color)
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

	var ap = NetworkManager.get_appearance(player_id)
	var p = Player.instantiate()
	p.setup(player_id, player_name, false, ap.get("character", "boy"), ap.get("color", Color(0.3, 0.6, 1.0, 1)))
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
