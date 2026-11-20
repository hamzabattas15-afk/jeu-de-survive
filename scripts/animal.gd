class_name Animal
extends CharacterBody3D

enum State { WANDER, FLEE, CHASE, DEAD }

@export var drop_item: String = "raw_meat"
@export_range(0, 100, 1) var drop_amount: int = 1
@export var move_speed: float = 2.0
@export var flee_distance: float = 8.0
@export var wander_radius: float = 8.0
@export var wander_interval: float = 2.5

var state: State = State.WANDER
var _wander_origin: Vector3
var _wander_direction: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _dying: bool = false

@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
	_wander_origin = global_position
	_health.died.connect(_die)
	_choose_wander_direction()


func take_damage(amount: int, source: Node3D) -> void:
	if state == State.DEAD:
		return
	_health.take_damage(amount, source)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		player = get_tree().root.find_child("Player", true, false) as Node3D
	if player != null and global_position.distance_to(player.global_position) < flee_distance:
		state = State.FLEE
		var away: Vector3 = global_position - player.global_position
		away.y = 0.0
		_wander_direction = away.normalized() if not away.is_zero_approx() else Vector3.FORWARD
	else:
		state = State.WANDER
		_wander_timer -= delta
		if _wander_timer <= 0.0 or global_position.distance_to(_wander_origin) > wander_radius:
			_choose_wander_direction()

	velocity.x = _wander_direction.x * move_speed * (1.7 if state == State.FLEE else 1.0)
	velocity.z = _wander_direction.z * move_speed * (1.7 if state == State.FLEE else 1.0)
	move_and_slide()


func _choose_wander_direction() -> void:
	var angle: float = randf_range(0.0, TAU)
	_wander_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	_wander_timer = maxf(wander_interval, 0.1)


func _die() -> void:
	if _dying:
		return
	_dying = true
	state = State.DEAD
	if not drop_item.is_empty() and drop_amount > 0:
		Inventory.add_item(drop_item, drop_amount)
	set_physics_process(false)
	set_collision_layer_value(1, false)
	set_collision_layer_value(3, false)
	set_collision_mask(0)
	for child in find_children("*", "CollisionShape3D", true, false):
		(child as CollisionShape3D).set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.35)
	tween.tween_callback(queue_free)
