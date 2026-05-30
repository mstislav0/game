class_name VertexColorFix
extends RefCounted

# Включает vertex_color_use_as_albedo для всех StandardMaterial3D в поддереве.
# Нужно для моделей Kenney (Space Kit и т.п.), которые используют vertex colors
# вместо текстур.
static func apply(root: Node) -> void:
	_walk(root)

static func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		if mesh:
			for i in mesh.get_surface_count():
				var mat = mesh.surface_get_material(i)
				if mat is StandardMaterial3D and not mat.vertex_color_use_as_albedo:
					mat.vertex_color_use_as_albedo = true
				# Также проверяем surface_override
				var ov = node.get_surface_override_material(i)
				if ov is StandardMaterial3D and not ov.vertex_color_use_as_albedo:
					ov.vertex_color_use_as_albedo = true
	for child in node.get_children():
		_walk(child)
