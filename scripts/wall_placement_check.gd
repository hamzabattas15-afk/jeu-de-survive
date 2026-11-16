class_name WallPlacementCheck
extends RefCounted


static func ground_at(point: Vector3, actor: CharacterBody3D) -> Dictionary:
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * 2.0, point + Vector3.DOWN * 3.0, 1
	)
	ray.exclude = [actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_ray(ray)


static func is_clear(base: Vector3, actor: CharacterBody3D) -> bool:
	var corners: Array[Vector3] = [
		Vector3(-0.98, 0, -0.14), Vector3(0.98, 0, -0.14),
		Vector3(-0.98, 0, 0.14), Vector3(0.98, 0, 0.14)
	]
	for corner in corners:
		var hit: Dictionary = ground_at(base + corner, actor)
		if hit.is_empty():
			return false
		var position: Vector3 = hit["position"]
		var normal: Vector3 = hit["normal"]
		if absf(position.y - base.y) > 0.05 or normal.dot(Vector3.UP) < 0.98:
			return false
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.96, 1.9, 0.28)
	shape.margin = 0.0
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, base + Vector3.UP * 1.05)
	query.collision_mask = 3
	query.collide_with_areas = true
	return actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
