extends CharacterBody3D

signal interaction_prompt_changed(prompt_text: String)

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.0
@export var turn_speed: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var min_camera_pitch_degrees: float = -65.0
@export var max_camera_pitch_degrees: float = 45.0

@onready var _visual: MeshInstance3D = $Visual
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _interact_area: Area3D = $InteractArea

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var _interaction_prompt: String = ""
var is_busy: bool = false


func _ready() -> void:
	Crafting.busy_changed.connect(func(busy: bool) -> void: is_busy = busy)
	_spring_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_interact_with_nearest()
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		_camera_pivot.rotate_y(-mouse_motion.relative.x * mouse_sensitivity)
		_spring_arm.rotation.x = clampf(
			_spring_arm.rotation.x - mouse_motion.relative.y * mouse_sensitivity,
			deg_to_rad(min_camera_pitch_degrees),
			deg_to_rad(max_camera_pitch_degrees)
		)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	if is_busy:
		input_direction = Vector2.ZERO
	# The pivot only rotates in yaw, so camera pitch cannot affect movement speed.
	var move_direction: Vector3 = _camera_pivot.global_transform.basis * Vector3(
		input_direction.x, 0.0, input_direction.y
	)
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * input_direction.length()
	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif not is_busy and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

	if not move_direction.is_zero_approx():
		# Godot's forward direction is -Z; rotate only the visual, leaving the camera free.
		var target_yaw: float = atan2(-move_direction.x, -move_direction.z)
		var turn_weight: float = 1.0 - exp(-turn_speed * delta)
		_visual.global_rotation.y = lerp_angle(
			_visual.global_rotation.y, target_yaw, turn_weight
		)
	_update_interaction_prompt()


func _interact_with_nearest() -> void:
	var closest_body: Node3D = _get_closest_interactable()
	if closest_body != null:
		closest_body.call("interact", self)
	_update_interaction_prompt()


func _update_interaction_prompt() -> void:
	var closest_body: Node3D = _get_closest_interactable()
	var prompt_text: String = ""
	if closest_body != null and closest_body.has_method("get_interaction_prompt"):
		prompt_text = str(closest_body.call("get_interaction_prompt"))
	if prompt_text != _interaction_prompt:
		_interaction_prompt = prompt_text
		interaction_prompt_changed.emit(prompt_text)


func _get_closest_interactable() -> Node3D:
	var closest_body: Node3D = null
	var closest_distance_squared: float = INF
	var nearby_bodies: Array[Node3D] = _interact_area.get_overlapping_bodies()
	var nearby_areas: Array[Area3D] = _interact_area.get_overlapping_areas()
	for area in nearby_areas:
		nearby_bodies.append(area)
	# The typed array also makes the loop variable a statically typed Node3D.
	for body in nearby_bodies:
		if not is_instance_valid(body) or not body.is_visible_in_tree():
			continue
		if not body.has_method("interact"):
			continue
		if body is ResourceNode and not (body as ResourceNode).is_available():
			continue
		var distance_squared: float = global_position.distance_squared_to(body.global_position)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_body = body

	return closest_body
