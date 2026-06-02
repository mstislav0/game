extends Node3D

# Дрейфующие облака: несколько плоских белых "ватных" мешей высоко в небе,
# медленно плывут по X и заворачиваются по кругу.

@export var count: int = 14
@export var area: float = 320.0
@export var height_min: float = 70.0
@export var height_max: float = 120.0
@export var drift_speed: float = 3.0
@export var seed_value: int = 13

var _clouds: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED

	for i in count:
		var cloud := Node3D.new()
		var puffs := rng.randi_range(3, 6)
		for p in puffs:
			var mi := MeshInstance3D.new()
			var s := SphereMesh.new()
			var rad := rng.randf_range(8.0, 16.0)
			s.radius = rad
			s.height = rad * 1.2
			mi.mesh = s
			mi.material_override = mat
			mi.position = Vector3(
				rng.randf_range(-18, 18),
				rng.randf_range(-2, 2),
				rng.randf_range(-8, 8)
			)
			mi.scale = Vector3(1.0, 0.45, 1.0)
			cloud.add_child(mi)
		cloud.position = Vector3(
			rng.randf_range(-area, area),
			rng.randf_range(height_min, height_max),
			rng.randf_range(-area, area)
		)
		add_child(cloud)
		_clouds.append(cloud)

func _process(delta: float) -> void:
	for c in _clouds:
		c.position.x += drift_speed * delta
		if c.position.x > area:
			c.position.x = -area
