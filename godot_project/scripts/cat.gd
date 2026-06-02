extends Node3D

# Бродячий кот-NPC: ходит по случайным точкам вокруг "дома",
# проигрывает Walk/Idle анимации, иногда мяукает (текст-облако "Мяу!").

@export var fur_color: Color = Color(0.9, 0.5, 0.2, 1)  # рыжий по умолчанию
@export var wander_radius: float = 12.0
@export var walk_speed: float = 1.6
@export var run_speed: float = 4.0

enum State { IDLE, WALK }

var _state: int = State.IDLE
var _home: Vector3
var _target: Vector3
var _state_timer: float = 0.0
var _meow_timer: float = 0.0
var _anim: AnimationPlayer
var _walk_anim: String = ""
var _idle_anim: String = ""
var _model: Node3D
var _meow_label: Label3D
var _meow_sound: AudioStreamPlayer3D

func _ready() -> void:
	_home = global_position
	_model = get_node_or_null("Model")
	_tint_fur()
	_find_animation_player()
	_make_meow_label()
	_make_meow_sound()
	_meow_timer = randf_range(4.0, 10.0)
	_enter_idle()

func _tint_fur() -> void:
	if _model == null:
		return
	# Находим меш и красим поверхность "Main" в нужный цвет, не трогая глаза.
	var mi: MeshInstance3D = _find_mesh(_model)
	if mi == null or mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var mat = mi.mesh.surface_get_material(i)
		var mat_name := ""
		if mat:
			mat_name = mat.resource_name
		var override := StandardMaterial3D.new()
		if mat is StandardMaterial3D:
			override.albedo_color = mat.albedo_color
			override.roughness = mat.roughness
		# Главный мех — перекрашиваем; вторичный — чуть темнее; глаза/уши не трогаем
		var lname := mat_name.to_lower()
		if lname.find("main") != -1:
			override.albedo_color = fur_color
			mi.set_surface_override_material(i, override)
		elif lname.find("secondary") != -1:
			override.albedo_color = fur_color.darkened(0.25)
			mi.set_surface_override_material(i, override)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for c in node.get_children():
		var r = _find_mesh(c)
		if r:
			return r
	return null

func _find_animation_player() -> void:
	_anim = _search_anim_player(self)
	if _anim == null:
		return
	for a in _anim.get_animation_list():
		var la := a.to_lower()
		if la.ends_with("walk") and _walk_anim == "":
			_walk_anim = a
		elif la.ends_with("idle") and _idle_anim == "":
			_idle_anim = a
	# Анимации зацикливаем
	for a in [_walk_anim, _idle_anim]:
		if a != "" and _anim.has_animation(a):
			var anim := _anim.get_animation(a)
			anim.loop_mode = Animation.LOOP_LINEAR

func _search_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r = _search_anim_player(c)
		if r:
			return r
	return null

func _make_meow_label() -> void:
	_meow_label = Label3D.new()
	_meow_label.text = "Мяу!"
	_meow_label.position = Vector3(0, 1.0, 0)
	_meow_label.pixel_size = 0.006
	_meow_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_meow_label.modulate = Color(1, 1, 1, 1)
	_meow_label.outline_size = 6
	_meow_label.font_size = 40
	_meow_label.visible = false
	add_child(_meow_label)

func _make_meow_sound() -> void:
	# Звук опционален: если файла нет, кот всё равно показывает "Мяу!"
	if ResourceLoader.exists("res://assets/cats/meow.ogg"):
		_meow_sound = AudioStreamPlayer3D.new()
		_meow_sound.stream = load("res://assets/cats/meow.ogg")
		_meow_sound.unit_size = 6.0
		_meow_sound.max_distance = 25.0
		add_child(_meow_sound)

func _process(delta: float) -> void:
	_state_timer -= delta
	_meow_timer -= delta

	if _meow_timer <= 0.0:
		_meow()
		_meow_timer = randf_range(6.0, 14.0)

	match _state:
		State.IDLE:
			if _state_timer <= 0.0:
				_enter_walk()
		State.WALK:
			_do_walk(delta)

func _enter_idle() -> void:
	_state = State.IDLE
	_state_timer = randf_range(2.0, 5.0)
	if _anim and _idle_anim != "":
		_anim.play(_idle_anim)

func _enter_walk() -> void:
	_state = State.WALK
	# случайная точка в радиусе вокруг дома
	var ang := randf() * TAU
	var dist := randf_range(2.0, wander_radius)
	_target = _home + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
	if _anim and _walk_anim != "":
		_anim.play(_walk_anim)

func _do_walk(delta: float) -> void:
	var to_target := _target - global_position
	to_target.y = 0
	var dist := to_target.length()
	if dist < 0.3:
		_enter_idle()
		return
	var dir := to_target / dist
	global_position += dir * walk_speed * delta
	# плавный поворот мордой по направлению
	var target_angle := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)

func _meow() -> void:
	if _meow_label:
		_meow_label.visible = true
		await get_tree().create_timer(1.3).timeout
		if is_instance_valid(_meow_label):
			_meow_label.visible = false
	if _meow_sound:
		_meow_sound.pitch_scale = randf_range(0.9, 1.2)
		_meow_sound.play()
