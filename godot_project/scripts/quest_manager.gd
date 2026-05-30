extends Node

signal quest_started(quest_id: String, title: String, target: int)
signal quest_progress(quest_id: String, current: int, total: int)
signal quest_completed(quest_id: String, title: String)
signal journal_message(text: String)

var active_quests: Dictionary = {}  # quest_id → { title, target, current, items_collected }

func start_quest(quest_id: String, title: String, target: int) -> void:
	if active_quests.has(quest_id):
		return
	active_quests[quest_id] = {
		"title": title,
		"target": target,
		"current": 0,
		"items": {}
	}
	emit_signal("quest_started", quest_id, title, target)

func ensure_quest(quest_id: String, title: String, target: int) -> void:
	if not active_quests.has(quest_id):
		start_quest(quest_id, title, target)

func collect_item(quest_id: String, item_id: String) -> bool:
	if not active_quests.has(quest_id):
		start_quest(quest_id, "Собрать предметы", 3)
	var q = active_quests[quest_id]
	if q.items.has(item_id):
		return false
	q.items[item_id] = true
	q.current += 1
	emit_signal("quest_progress", quest_id, q.current, q.target)
	if q.current >= q.target:
		emit_signal("quest_completed", quest_id, q.title)
	return true

func is_quest_complete(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	var q = active_quests[quest_id]
	return q.current >= q.target

func is_item_collected(quest_id: String, item_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	return active_quests[quest_id].items.has(item_id)

func get_quest_title(quest_id: String) -> String:
	if active_quests.has(quest_id):
		return active_quests[quest_id].title
	return quest_id
