extends Interactable

const QUEST_ID := "earth_antenna"
const ITEM_ID := "antenna_main"

func _ready() -> void:
	prompt_text = "[E] Активировать антенну"
	interacted.connect(_on_interacted)
	NetworkManager.item_collected.connect(_on_item_collected)
	# Регистрируем квест заранее с target=1 (одно действие)
	QuestManager.ensure_quest(QUEST_ID, "Активировать антенну связи", 1)
	if NetworkManager.initial_collected.has("%s:%s" % [QUEST_ID, ITEM_ID]):
		_mark_done()
	var model := get_node_or_null("Model")
	if model:
		Util.center_model_xz(model)

func _on_interacted(_player: Node) -> void:
	NetworkManager.send_collect_item(QUEST_ID, ITEM_ID)

func _on_item_collected(qid: String, iid: String, _by: String) -> void:
	if qid == QUEST_ID and iid == ITEM_ID:
		QuestManager.collect_item(QUEST_ID, ITEM_ID)
		_mark_done()

func _mark_done() -> void:
	prompt_text = "Антенна активирована"
	# Зажигаем индикатор
	var light = get_node_or_null("ActiveLight")
	if light:
		light.visible = true
	# Удаляем из группы interactable чтобы больше не подсвечивалось
	remove_from_group("interactable")
