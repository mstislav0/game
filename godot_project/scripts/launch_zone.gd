extends Interactable

@export var required_quests: Array[String] = ["earth_tools", "earth_fuel", "earth_antenna"]
# Куда телепортировать игрока, когда он входит в ракету (мировые координаты).
# Высота ~30м соответствует кабине внутри 40-метровой ракеты.
@export var cockpit_position: Vector3 = Vector3(0, 30, -60)

var _entered: bool = false

func _ready() -> void:
	prompt_text = "[E] Зайти в ракету"
	interacted.connect(_on_interacted)
	NetworkManager.launch_now.connect(_on_launch_now)

func _on_interacted(player: Node) -> void:
	if _entered:
		return
	for qid in required_quests:
		if not QuestManager.is_quest_complete(qid):
			QuestManager.emit_signal("journal_message", "Сначала выполните все 3 задания!")
			return
	_entered = true
	# Поднимаем игрока внутрь ракеты
	if player is Node3D:
		player.global_position = cockpit_position
	NetworkManager.send_launch_vote()

func _on_launch_now() -> void:
	# Анимацию делает game_world
	pass
