extends Node3D

# Собирает интерьер ракеты из Quaternius Modular Sci-Fi MegaKit.
# Сетка кита: тайлы 4×4 м, стены высотой ~3 м.

const KIT := "res://assets/scifi_kit/"
const TILE := 4.0
const GRID := [-6.0, -2.0, 2.0, 6.0]   # 4×4 тайла → комната 16×16 м

const Floor := preload(KIT + "Platform_Metal.gltf")
const WallSolid := preload(KIT + "WallAstra_Straight.gltf")
const WallWindow := preload(KIT + "WallAstra_Straight_Window.gltf")
const DoorFrame := preload(KIT + "Door_Frame_Square.gltf")
const Computer := preload(KIT + "Prop_Computer.gltf")
const LightWide := preload(KIT + "Prop_Light_Wide.gltf")
const Crate := preload(KIT + "Prop_Crate3.gltf")
const Column := preload(KIT + "Column_Simple.gltf")
const LaunchConsole := preload("res://scenes/launch_zone.tscn")

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_props()
	_build_collisions()
	_build_lights()

func _spawn(scene: PackedScene, pos: Vector3, rot_y_deg := 0.0) -> Node3D:
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation.y = deg_to_rad(rot_y_deg)
	add_child(n)
	return n

func _build_floor() -> void:
	for x in GRID:
		for z in GRID:
			_spawn(Floor, Vector3(x, 0, z))

func _build_walls() -> void:
	var lo: float = GRID[0]
	var hi: float = GRID[GRID.size() - 1]
	for v in GRID:
		# Запад (-X), восток (+X)
		_spawn(WallSolid, Vector3(lo, 0, v), 0.0)
		_spawn(WallSolid, Vector3(hi, 0, v), 180.0)
		# Север (-Z) — окна-иллюминаторы; Юг (+Z) — сплошные, в центре дверь
		_spawn(WallWindow, Vector3(v, 0, lo), -90.0)
		if is_equal_approx(v, 2.0):
			_spawn(DoorFrame, Vector3(v, 0, hi), 90.0)
		else:
			_spawn(WallSolid, Vector3(v, 0, hi), 90.0)
	# Колонны по углам
	for cx in [lo, hi]:
		for cz in [lo, hi]:
			_spawn(Column, Vector3(cx, 0, cz))

func _build_props() -> void:
	# Консоль управления у северной стены (с иллюминаторами) + кнопка пуска
	var console := _spawn(Computer, Vector3(0, 0, GRID[0] + 1.2), 0.0)
	var btn := LaunchConsole.instantiate()
	btn.position = Vector3(0, 1.2, GRID[0] + 1.2)
	add_child(btn)
	# Ящики для антуража
	_spawn(Crate, Vector3(GRID[hi_i()] - 1.5, 0, GRID[0] + 1.5))
	_spawn(Crate, Vector3(GRID[hi_i()] - 1.5, 0, GRID[0] + 2.6))
	_spawn(Crate, Vector3(GRID[hi_i()] - 2.4, 0, GRID[0] + 1.5))

func hi_i() -> int:
	return GRID.size() - 1

func _build_lights() -> void:
	# Потолочные лампы-модели + реальные источники света
	for x in [-4.0, 4.0]:
		for z in [-4.0, 4.0]:
			_spawn(LightWide, Vector3(x, 2.95, z), 0.0)
			var l := OmniLight3D.new()
			l.position = Vector3(x, 2.7, z)
			l.light_energy = 1.6
			l.omni_range = 10.0
			l.light_color = Color(0.85, 0.92, 1.0)
			add_child(l)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 2.5, 0)
	fill.light_energy = 1.2
	fill.omni_range = 16.0
	add_child(fill)

func _build_collisions() -> void:
	var lo: float = GRID[0] - TILE * 0.5
	var hi: float = GRID[GRID.size() - 1] + TILE * 0.5
	var span: float = hi - lo
	var mid: float = (lo + hi) * 0.5
	# Пол
	_add_box(Vector3(mid, -0.1, mid), Vector3(span, 0.4, span))
	# Стены (4 короба по периметру)
	var t := 0.4
	var h := 3.0
	_add_box(Vector3(lo, h * 0.5, mid), Vector3(t, h, span))   # запад
	_add_box(Vector3(hi, h * 0.5, mid), Vector3(t, h, span))   # восток
	_add_box(Vector3(mid, h * 0.5, lo), Vector3(span, h, t))   # север
	_add_box(Vector3(mid, h * 0.5, hi), Vector3(span, h, t))   # юг

func _add_box(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	add_child(body)
