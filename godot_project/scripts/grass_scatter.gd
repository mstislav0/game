extends MultiMeshInstance3D

# Разбрасывает траву (мелкие конусы) случайно по прямоугольной области.
# Параметры настраиваются в инспекторе.

@export var count: int = 4000
@export var area_size: Vector2 = Vector2(150, 150)
@export var min_scale: float = 0.6
@export var max_scale: float = 1.4
@export var seed: int = 42

# Зоны, куда траву не сажать (XZ-радиус вокруг точки)
@export var exclusion_zones: Array[Vector3] = []  # (x, z, radius)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# Создаём меш-травинку: тонкий узкий конус
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 0.06
	blade.height = 0.45
	blade.radial_segments = 4
	blade.rings = 1

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.25, 1)
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	blade.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = count
	multimesh = mm

	for i in count:
		var x := rng.randf_range(-area_size.x * 0.5, area_size.x * 0.5)
		var z := rng.randf_range(-area_size.y * 0.5, area_size.y * 0.5)

		# Не сажать в исключённых зонах
		var skip := false
		for ez in exclusion_zones:
			var dx = x - ez.x
			var dz = z - ez.y
			if dx*dx + dz*dz < ez.z * ez.z:
				skip = true
				break
		if skip:
			# Просто поставим под землёй вместо continue, чтобы индексы не съезжали
			var hidden := Transform3D().scaled(Vector3(0.001, 0.001, 0.001))
			hidden.origin = Vector3(0, -100, 0)
			mm.set_instance_transform(i, hidden)
			continue

		var s := rng.randf_range(min_scale, max_scale)
		var rot_y := rng.randf_range(0.0, TAU)
		var t := Transform3D()
		t = t.rotated(Vector3.UP, rot_y)
		t = t.scaled_local(Vector3(s, s, s))
		t.origin = Vector3(x, 0.0, z)
		mm.set_instance_transform(i, t)
