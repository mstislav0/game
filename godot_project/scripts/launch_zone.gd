extends Interactable

# Кнопка запуска на приборной панели внутри ракеты.
# Игрок попадает сюда через Entrance.

var _voted: bool = false

func _ready() -> void:
	prompt_text = "[E] Запустить ракету"
	interacted.connect(_on_interacted)
	NetworkManager.launch_now.connect(_on_launch_now)

func _on_interacted(_player: Node) -> void:
	if _voted:
		return
	_voted = true
	NetworkManager.send_launch_vote()
	QuestManager.emit_signal("journal_message", "Вы готовы! Ждём остальных...")

func _on_launch_now() -> void:
	# Анимацию проигрывает game_world
	pass
