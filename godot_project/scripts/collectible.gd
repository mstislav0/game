extends Interactable

@export var quest_id: String = "earth_tools"
@export var item_id: String = ""

func _ready() -> void:
	if item_id.is_empty():
		item_id = name
	prompt_text = "[E] Подобрать"
	interacted.connect(_on_interacted)
	NetworkManager.item_collected.connect(_on_item_collected)
	# Если предмет уже собран кем-то (мы только что вошли в комнату), уничтожаемся сразу
	var key = "%s:%s" % [quest_id, item_id]
	if NetworkManager.initial_collected.has(key):
		queue_free()

func _on_interacted(_player: Node) -> void:
	# Просим сервер. Реальное удаление произойдёт в _on_item_collected
	NetworkManager.send_collect_item(quest_id, item_id)

func _on_item_collected(qid: String, iid: String, _by: String) -> void:
	if qid == quest_id and iid == item_id:
		QuestManager.collect_item(quest_id, item_id)
		queue_free()
