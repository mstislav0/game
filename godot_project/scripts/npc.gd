extends Interactable

@export var npc_name: String = "Профессор Звёздочкин"
@export_multiline var intro_line: String = "Привет! Помоги собрать инструменты — найди 3 ящика на космодроме."
@export_multiline var progress_line: String = "Молодец, ищи дальше!"
@export_multiline var complete_line: String = "Отлично! Все детали собраны. Можем запускать ракету!"
@export var quest_id: String = "earth_tools"
@export var quest_title: String = "Собрать инструменты"
@export var quest_target: int = 3

signal dialog_requested(npc_name: String, text: String)

var _quest_given := false

func _ready() -> void:
	prompt_text = "[E] Поговорить с %s" % npc_name
	interacted.connect(_on_interacted)

func _on_interacted(_player: Node) -> void:
	var line: String
	if not _quest_given:
		QuestManager.start_quest(quest_id, quest_title, quest_target)
		_quest_given = true
		line = intro_line
	elif QuestManager.is_quest_complete(quest_id):
		line = complete_line
	else:
		line = progress_line
	emit_signal("dialog_requested", npc_name, line)
