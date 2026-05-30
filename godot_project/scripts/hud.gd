extends CanvasLayer

@onready var prompt_label: Label = $InteractPrompt
@onready var dialog_panel: Panel = $DialogPanel
@onready var dialog_name: Label = $DialogPanel/VBox/NpcName
@onready var dialog_text: Label = $DialogPanel/VBox/Text
@onready var journal_panel: Panel = $JournalPanel
@onready var journal_list: VBoxContainer = $JournalPanel/Scroll/List
@onready var room_label: Label = $RoomLabel

var _local_player: Node = null

func _ready() -> void:
	dialog_panel.hide()
	prompt_label.hide()
	QuestManager.journal_message.connect(_add_journal_line)
	QuestManager.quest_completed.connect(_on_quest_completed)
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
	# Автоскрытие через 4 секунды
	await get_tree().create_timer(4.0).timeout
	dialog_panel.hide()

func _add_journal_line(text: String) -> void:
	var label = Label.new()
	label.text = "• " + text
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_list.add_child(label)

func _on_quest_completed(_quest_id: String) -> void:
	pass
