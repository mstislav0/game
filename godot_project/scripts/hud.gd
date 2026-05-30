extends CanvasLayer

@onready var prompt_label: Label = $InteractPrompt
@onready var dialog_panel: Panel = $DialogPanel
@onready var dialog_name: Label = $DialogPanel/VBox/NpcName
@onready var dialog_text: Label = $DialogPanel/VBox/Text
@onready var journal_panel: Panel = $JournalPanel
@onready var journal_list: VBoxContainer = $JournalPanel/Scroll/List
@onready var room_label: Label = $RoomLabel

var _local_player: Node = null
var _entries: Dictionary = {}  # key → Label (для обновления на месте)

func _ready() -> void:
	dialog_panel.hide()
	prompt_label.hide()
	QuestManager.journal_message.connect(_add_journal_line)
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_progress.connect(_on_quest_progress)
	QuestManager.quest_completed.connect(_on_quest_completed)
	NetworkManager.launch_progress.connect(_on_launch_progress)
	room_label.text = "Комната: %s" % NetworkManager.room_code

func bind_local_player(player: Node) -> void:
	_local_player = player
	player.interactable_changed.connect(_on_interactable_changed)
	player.dialog_requested.connect(_on_dialog_requested)

func _on_interactable_changed(target: Node) -> void:
	if target and "prompt_text" in target:
		prompt_label.text = target.prompt_text
		prompt_label.show()
	else:
		prompt_label.hide()

func _on_dialog_requested(npc_name: String, text: String) -> void:
	dialog_name.text = npc_name
	dialog_text.text = text
	dialog_panel.show()
	await get_tree().create_timer(4.0).timeout
	dialog_panel.hide()

# --- Журнал ---

func _on_quest_started(quest_id: String, title: String, target: int) -> void:
	_set_entry("quest:" + quest_id, "📋 %s: 0/%d" % [title, target], Color(1, 1, 1, 1))

func _on_quest_progress(quest_id: String, current: int, total: int) -> void:
	var title := QuestManager.get_quest_title(quest_id)
	_set_entry("quest:" + quest_id, "📋 %s: %d/%d" % [title, current, total], Color(1, 1, 1, 1))

func _on_quest_completed(quest_id: String, title: String) -> void:
	_set_entry("quest:" + quest_id, "✓ %s — выполнено" % title, Color(0.5, 1.0, 0.6, 1))

func _on_launch_progress(have: int, required: int) -> void:
	_set_entry("launch", "🚀 Готовы к запуску: %d/%d" % [have, required], Color(1, 0.85, 0.4, 1))

func _set_entry(key: String, text: String, color: Color) -> void:
	var lbl: Label = _entries.get(key)
	if lbl == null:
		lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		journal_list.add_child(lbl)
		_entries[key] = lbl
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)

# Одноразовые сообщения, добавляются строкой ниже
func _add_journal_line(text: String) -> void:
	var label := Label.new()
	label.text = "• " + text
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_list.add_child(label)
