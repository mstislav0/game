extends Interactable

@export var cockpit_position: Vector3 = Vector3(0, 30, -60)
@export var required_quests: Array[String] = ["earth_tools", "earth_fuel", "earth_antenna"]

func _ready() -> void:
	prompt_text = "[E] Зайти в ракету"
	interacted.connect(_on_interacted)

func _on_interacted(player: Node) -> void:
	for qid in required_quests:
		if not QuestManager.is_quest_complete(qid):
			QuestManager.emit_signal("journal_message", "Сначала выполните все 3 задания!")
			return
	if player is Node3D:
		player.global_position = cockpit_position
		QuestManager.emit_signal("journal_message", "Вы внутри ракеты. Нажмите кнопку запуска.")
