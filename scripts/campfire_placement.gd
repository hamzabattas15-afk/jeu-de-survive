extends Node

signal placement_feedback(message: String)

const CAMPFIRE_SCENE: PackedScene = preload("res://scenes/items/campfire.tscn")

@export var item_scene: PackedScene = CAMPFIRE_SCENE
@export var item_id: String = "campfire"
@export var placement_action: String = "place_campfire"
@export var player: CharacterBody3D
@export var facing: Node3D
@export_range(1.5, 4.0, 0.1) var placement_distance: float = 2.0

var _placement_requested: bool = false


func _ready() -> void:
	if player == null or facing == null:
		push_error("CampfirePlacement needs a player and a facing node.")
		set_process_unhandled_input(false)
		set_physics_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(placement_action):
		_placement_requested = true
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _placement_requested:
		_placement_requested = false
		_try_place()


func _try_place() -> void:
	if Inventory.get_amount(item_id) < 1:
		placement_feedback.emit("Craft the station first (C).")
		return
	if not player.is_on_floor():
		placement_feedback.emit("Stand on the ground to place a station.")
		return

	var forward: Vector3 = -facing.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var target: Vector3 = player.global_position + forward * placement_distance
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var ground_hit: Dictionary = _find_ground(target, space)
	if ground_hit.is_empty():
		placement_feedback.emit("No ground in front of you.")
		return
	var ground_position: Vector3 = ground_hit["position"]
	var ground_normal: Vector3 = ground_hit["normal"]
	if ground_normal.dot(Vector3.UP) < 0.98 or not _has_support(ground_position, space):
		placement_feedback.emit("Find a flat, fully supported spot.")
		return

	# Keep the clearance volume just above the floor so the ground is not an obstacle.
	var clearance: BoxShape3D = BoxShape3D.new()
	clearance.size = Vector3(1.8, 0.6, 1.8)
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = clearance
	query.transform = Transform3D(Basis.IDENTITY, ground_position + Vector3.UP * 0.4)
	query.collision_mask = 3
	query.collide_with_areas = true
	query.margin = 0.01
	var obstacles: Array[Dictionary] = space.intersect_shape(query, 1)
	if not obstacles.is_empty():
		placement_feedback.emit("Not enough room for a station here.")
		return

	var campfire: Node3D = item_scene.instantiate() as Node3D
	if not Inventory.remove_item(item_id, 1):
		campfire.free()
		return
	get_tree().current_scene.add_child(campfire)
	campfire.global_position = ground_position + Vector3.UP * 0.02
	campfire.global_rotation.y = facing.global_rotation.y
	placement_feedback.emit("Station placed. Approach and press E to use it.")


func _find_ground(position: Vector3, space: PhysicsDirectSpaceState3D) -> Dictionary:
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		position + Vector3.UP, position + Vector3.DOWN * 2.0, 1
	)
	ray.exclude = [player.get_rid()]
	return space.intersect_ray(ray)


func _has_support(center: Vector3, space: PhysicsDirectSpaceState3D) -> bool:
	var offsets: Array[Vector3] = [
		Vector3(-0.9, 0, -0.9), Vector3(0.9, 0, -0.9),
		Vector3(-0.9, 0, 0.9), Vector3(0.9, 0, 0.9)
	]
	for offset in offsets:
		var hit: Dictionary = _find_ground(center + offset, space)
		if hit.is_empty():
			return false
		var position: Vector3 = hit["position"]
		var normal: Vector3 = hit["normal"]
		if absf(position.y - center.y) > 0.05 or normal.dot(Vector3.UP) < 0.98:
			return false
	return true
