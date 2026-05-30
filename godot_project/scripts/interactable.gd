class_name Interactable
extends Area3D

@export var prompt_text: String = "Взаимодействовать"

signal interacted(player: Node)

func interact(player: Node) -> void:
	emit_signal("interacted", player)
