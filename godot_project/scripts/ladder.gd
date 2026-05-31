extends Interactable

@export var delta_y: float = 4.0
@export var direction_label: String = "вверх"  # "вверх" или "вниз"

func _ready() -> void:
	prompt_text = "[E] " + direction_label.capitalize()
	interacted.connect(_on_interacted)

func _on_interacted(player: Node) -> void:
	if player is Node3D:
		player.global_position.y += delta_y
