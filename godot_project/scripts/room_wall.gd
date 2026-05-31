extends StaticBody3D

# Создаёт кольцо стен вокруг этажа кокпита.
# Каждый сегмент — BoxMesh + BoxShape3D с одной коллизией.
# Часть сегментов можно оставить без меша (open_visual_segments)
# для эффекта "окон" — коллизия там всё равно стоит, чтобы игрок не упал.

@export var radius: float = 6.0
@export var height: float = 3.6
@export var segments: int = 20
@export var color: Color = Color(0.55, 0.62, 0.72, 1)
@export var open_visual_segments: Array[int] = []  # индексы сегментов без меша (окна)

func _ready() -> void:
	var seg_arc: float = TAU / float(segments)
	var seg_width: float = 2.0 * radius * sin(seg_arc * 0.5) + 0.05
	var seg_thickness: float = 0.18

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(seg_width, height, seg_thickness)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.55
	box_mesh.material = mat

	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(seg_width, height, seg_thickness)

	for i in segments:
		var angle: float = float(i) * seg_arc
		var x: float = radius * cos(angle)
		var z: float = radius * sin(angle)
		var pos := Vector3(x, height * 0.5, z)
		# Стена должна быть лицом внутрь, поэтому ориентируем по углу
		var rot_y: float = -angle

		var col := CollisionShape3D.new()
		col.shape = box_shape
		col.position = pos
		col.rotation.y = rot_y
		add_child(col)

		if not open_visual_segments.has(i):
			var mi := MeshInstance3D.new()
			mi.mesh = box_mesh
			mi.position = pos
			mi.rotation.y = rot_y
			add_child(mi)
