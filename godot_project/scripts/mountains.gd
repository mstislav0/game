extends Node3D

# Кольцо далёких низкополигональных гор вокруг карты — даёт ощущение масштаба.
# Горы стоят за пределами игровой зоны и читаются сквозь туман.

@export var count: int = 26
@export var ring_radius: float = 280.0
@export var radius_jitter: float = 40.0
@export var min_height: float = 35.0
@export var max_height: float = 90.0
@export var seed_value: int = 7

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.5, 0.62, 1)
	mat.roughness = 1.0
	# Лёгкое свечение, чтобы горы не «съедались» туманом полностью
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.38, 0.52, 1)
	mat.emission_energy_multiplier = 0.15

	var snow := StandardMaterial3D.new()
	snow.albedo_color = Color(0.92, 0.95, 1.0, 1)
	snow.roughness = 0.9

	for i in count:
		var ang := (float(i) / float(count)) * TAU + rng.randf_range(-0.06, 0.06)
		var r := ring_radius + rng.randf_range(-radius_jitter, radius_jitter)
		var x := cos(ang) * r
		var z := sin(ang) * r
		var h := rng.randf_range(min_height, max_height)
		var base := rng.randf_range(h * 0.7, h * 1.1)

		# Гора — конус (CylinderMesh с нулевым верхом)
		var peak := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = base
		cone.height = h
		cone.radial_segments = rng.randi_range(5, 7)
		peak.mesh = cone
		peak.material_override = mat
		peak.position = Vector3(x, h * 0.5, z)
		peak.rotation.y = rng.randf_range(0, TAU)
		add_child(peak)

		# Снежная шапка
		var cap := MeshInstance3D.new()
		var capcone := CylinderMesh.new()
		capcone.top_radius = 0.0
		capcone.bottom_radius = base * 0.4
		capcone.height = h * 0.3
		capcone.radial_segments = cone.radial_segments
		cap.mesh = capcone
		cap.material_override = snow
		cap.position = Vector3(x, h * 0.85, z)
		cap.rotation.y = peak.rotation.y
		add_child(cap)
