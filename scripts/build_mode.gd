extends Node

signal build_feedback(message: String)

const WALL: PackedScene = preload("res://scenes/items/wall.tscn")
@export var player: CharacterBody3D
@export var camera_pivot: Node3D
@export_range(1, 100, 1) var bricks_per_wall: int = 5

var _active: bool = false
var _place_requested: bool = false
var _ghost: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(2, 2, 0.3)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost = MeshInstance3D.new()
	_ghost.mesh = mesh
	_ghost.material_override = _material
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)
	_ghost.top_level = true
	_ghost.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_active = not _active
		_place_requested = false
		_ghost.visible = _active
		build_feedback.emit("Build: aim with mouse, click to place (%d bricks). B / Esc exits." % bricks_per_wall if _active else "Build mode off")
		get_viewport().set_input_as_handled()
	elif _active and event.is_action_pressed("ui_cancel"):
		_active = false
		_ghost.hide()
		get_viewport().set_input_as_handled()
	elif _active and event.is_action_pressed("build_place"):
		_place_requested = true
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_active = false
		_place_requested = false
		_ghost.hide()
	if not _active:
		return
	var forward: Vector3 = -camera_pivot.global_transform.basis.z
	forward.y = 0.0
	var target: Vector3 = player.global_position + forward.normalized() * 4.0
	target.x = snappedf(target.x, 2.0)
	target.z = snappedf(target.z, 2.0)
	var hit: Dictionary = WallPlacementCheck.ground_at(target, player)
	var valid: bool = false
	if not hit.is_empty():
		target = hit["position"]
		valid = player.is_on_floor() and WallPlacementCheck.is_clear(target, player)
	valid = valid and Inventory.get_amount("mud_brick") >= bricks_per_wall
	_ghost.global_position = target + Vector3.UP
	_material.albedo_color = Color(0.2, 1.0, 0.3, 0.45) if valid else Color(1.0, 0.15, 0.1, 0.45)
	if not _place_requested:
		return
	_place_requested = false
	if not valid:
		build_feedback.emit("Need %d mud bricks and clear, supported ground." % bricks_per_wall)
		return
	if Inventory.remove_item("mud_brick", bricks_per_wall):
		var wall: Node3D = WALL.instantiate() as Node3D
		get_tree().current_scene.add_child(wall)
		wall.global_position = target
		_material.albedo_color = Color(1.0, 0.15, 0.1, 0.45)
		build_feedback.emit("Wall placed.")
