extends Node

# Фоновая музыка через автозагрузку: играет на всех сценах,
# не прерывается при переключении.

const TRACK_PATH := "res://assets/audio/cosmic_priest.ogg"
const VOLUME_DB := -14.0  # тихо, чтобы не забивать диалоги

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = VOLUME_DB
	var stream: AudioStream = load(TRACK_PATH)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_player.stream = stream
	add_child(_player)
	_player.play()

func set_muted(muted: bool) -> void:
	_player.stream_paused = muted

func set_volume_db(db: float) -> void:
	_player.volume_db = db
