extends Area3D

@export var player: CharacterBody3D
@export var hand_socket: Node3D
@export var build_mode: BuildMode
@export_range(0.15, 5.0, 0.01) var attack_cooldown: float = 0.6
@export_range(0.01, 0.5, 0.01) var hit_duration: float = 0.15
@export var bare_hand_damage: int = 3

var _cooldown_remaining: float = 0.0
var _hit_time_remaining: float = 0.0
var _attack_damage: int = 0
var _hit_bodies: Array[int] = []
var _rest_rotation: Vector3
var _swing: Tween = null

@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_rest_rotation = hand_socket.rotation
	body_entered.connect(_try_hit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and _can_attack_here():
		try_attack()
		get_viewport().set_input_as_handled()


func try_attack() -> bool:
	if _cooldown_remaining > 0.0 or _hit_time_remaining > 0.0 or not _can_attack_here():
		return false
	# Snapshot damage: changing hotbar slots cannot change a swing already in progress.
	_attack_damage = bare_hand_damage if Equipment.get_equipped_item().is_empty() else Equipment.get_equipped_damage()
	_cooldown_remaining = attack_cooldown
	_hit_time_remaining = hit_duration
	_hit_bodies.clear()
	set_deferred("monitoring", true)
	_shape.set_deferred("disabled", false)
	if _swing != null and _swing.is_valid():
		_swing.kill()
	hand_socket.rotation = _rest_rotation
	_swing = create_tween()
	_swing.tween_property(hand_socket, "rotation", _rest_rotation + Vector3(-1.2, 0.3, -0.65), 0.075)
	_swing.tween_property(hand_socket, "rotation", _rest_rotation, 0.18)
	return true


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _hit_time_remaining <= 0.0:
		return
	_hit_time_remaining = maxf(_hit_time_remaining - delta, 0.0)
	if _hit_time_remaining <= 0.0 or not _can_attack_here():
		_end_hit_window()
		return
	if not monitoring:
		return
	# Also catch bodies already inside when monitoring starts; hit each body once.
	var bodies: Array[Node3D] = get_overlapping_bodies()
	for body in bodies:
		_try_hit(body)


func _can_attack_here() -> bool:
	return (
		not get_tree().paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		and not bool(player.get("is_busy")) and not build_mode.is_active()
	)


func _try_hit(body: Node3D) -> void:
	if _hit_time_remaining <= 0.0 or _attack_damage <= 0 or not _can_attack_here():
		return
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return
	if body == player or player.is_ancestor_of(body) or not body.has_method("take_damage"):
		return
	var body_id: int = body.get_instance_id()
	if _hit_bodies.has(body_id):
		return
	_hit_bodies.append(body_id)
	body.call("take_damage", _attack_damage, player)


func _end_hit_window() -> void:
	_hit_time_remaining = 0.0
	set_deferred("monitoring", false)
	_shape.set_deferred("disabled", true)
