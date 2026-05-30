extends Interactable

@export var required_quests: Array[String] = ["earth_tools", "earth_fuel", "earth_antenna"]
var _voted := false

func _ready() -> void:
	prompt_text = "[E] Запустить ракету"
	interacted.connect(_on_interacted)
	NetworkManager.launch_progress.connect(_on_launch_progress)
	NetworkManager.launch_now.connect(_on_launch_now)

func _on_interacted(_player: Node) -> void:
	if _voted:
		return
	for qid in required_quests:
		if not QuestManager.is_quest_complete(qid):
			QuestManager.emit_signal("journal_message", "Ещё не всё готово! Соберите инструменты, топливо и активируйте антенну.")
			return
	_voted = true
	NetworkManager.send_launch_vote()
	QuestManager.emit_signal("journal_message", "Вы готовы к запуску. Ждём остальных...")

func _on_launch_progress(have: int, required: int) -> void:
	QuestManager.emit_signal("journal_message", "К запуску готовы: %d/%d" % [have, required])

func _on_launch_now() -> void:
	# Сцену меняет game_world после анимации
	QuestManager.emit_signal("journal_message", "🚀 Запуск!")
