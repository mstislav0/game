extends Node

# Утилиты, доступные как Util.foo(...) из любого места.

# Сдвигает узел (обычно — GLB-инстанс из Kenney) так, чтобы XZ-центр его
# видимой геометрии совпал с origin родителя. Y не трогаем, чтобы модель
# не уходила под землю / в воздух.
func center_model_xz(target: Node3D) -> void:
	# Дожидаемся, пока дети встанут на свои места в дереве
	await target.get_tree().process_frame

	var aabb := AABB()
	var first := true
	var visuals := _find_visual_instances(target)
	for vi in visuals:
		var local_aabb: AABB = vi.get_aabb()
		# Переводим AABB из локальных координат vi в координаты target
		var rel: Transform3D = target.global_transform.affine_inverse() * vi.global_transform
		local_aabb = rel * local_aabb
		if first:
			aabb = local_aabb
			first = false
		else:
			aabb = aabb.merge(local_aabb)

	if first:
		return  # ничего не нашли

	var center := aabb.position + aabb.size * 0.5
	# Сдвигаем target, чтобы центр меша оказался в (0, _, 0) родителя.
	# Координаты центра — в локальном пространстве target (без его scale),
	# поэтому домножаем на scale, чтобы получить смещение в координатах родителя.
	var s := target.scale
	target.position -= Vector3(center.x * s.x, 0, center.z * s.z)

func _find_visual_instances(node: Node) -> Array:
	var result: Array = []
	if node is VisualInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_visual_instances(child))
	return result
