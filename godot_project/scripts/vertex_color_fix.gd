class_name VertexColorFix
extends RefCounted

# Включает vertex_color_use_as_albedo для материалов, которые реально используют
# vertex colors (модели Kenney). Не трогает наши примитивы (BoxMesh, PlaneMesh
# и т.п.), у которых vertex colors нет — иначе они рендерятся чёрным.
static func apply(root: Node) -> void:
	_walk(root)

static func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		if mesh:
			for i in mesh.get_surface_count():
				var has_vertex_colors := (mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_COLOR) != 0
				if not has_vertex_colors:
					continue
				var mat = mesh.surface_get_material(i)
				if mat is StandardMaterial3D and not mat.vertex_color_use_as_albedo:
					mat.vertex_color_use_as_albedo = true
				var ov = node.get_surface_override_material(i)
				if ov is StandardMaterial3D and not ov.vertex_color_use_as_albedo:
					ov.vertex_color_use_as_albedo = true
	for child in node.get_children():
		_walk(child)
