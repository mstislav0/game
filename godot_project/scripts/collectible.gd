extends Interactable

@export var quest_id: String = "earth_tools"
@export var item_id: String = ""

func _ready() -> void:
	if item_id.is_empty():
		item_id = name
	prompt_text = "[E] Подобрать"
	interacted.connect(_on_interacted)
	if QuestManager.is_item_collected(quest_id, item_id):
		queue_free()

func _on_interacted(_player: Node) -> void:
	if QuestManager.collect_item(quest_id, item_id):
		queue_free()
