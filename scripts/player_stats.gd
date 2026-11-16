class_name PlayerStats
extends Node

signal health_changed(value: float)
signal hunger_changed(value: float)
signal thirst_changed(value: float)
signal player_died

@export_range(0.0, 100.0, 0.1) var health: float = 100.0:
	set(value):
		var next_value: float = clampf(value, 0.0, 100.0)
		if health == next_value:
			return
		health = next_value
		if is_node_ready():
			health_changed.emit(health)
			_check_for_death()

@export_range(0.0, 100.0, 0.1) var hunger: float = 100.0:
	set(value):
		var next_value: float = clampf(value, 0.0, 100.0)
		if hunger == next_value:
			return
		hunger = next_value
		if is_node_ready():
			hunger_changed.emit(hunger)

@export_range(0.0, 100.0, 0.1) var thirst: float = 100.0:
	set(value):
		var next_value: float = clampf(value, 0.0, 100.0)
		if thirst == next_value:
			return
		thirst = next_value
		if is_node_ready():
			thirst_changed.emit(thirst)

@export_range(0.0, 10.0, 0.05, "or_greater") var hunger_drain_per_second: float = 0.2
@export_range(0.0, 10.0, 0.05, "or_greater") var thirst_drain_per_second: float = 0.3
@export_range(0.0, 100.0, 0.5, "or_greater") var deprivation_damage_per_second: float = 5.0
@export_range(0.0, 100.0, 1.0) var cooked_meat_hunger_restore: float = 35.0

var _dead: bool = false
var _is_eating: bool = false


func _ready() -> void:
	_publish_initial_state.call_deferred()


func _process(delta: float) -> void:
	if _dead:
		return
	var hunger_rate: float = maxf(hunger_drain_per_second, 0.0)
	var thirst_rate: float = maxf(thirst_drain_per_second, 0.0)
	var time_until_empty: float = INF
	if hunger <= 0.0 or thirst <= 0.0:
		time_until_empty = 0.0
	else:
		if hunger_rate > 0.0:
			time_until_empty = minf(time_until_empty, hunger / hunger_rate)
		if thirst_rate > 0.0:
			time_until_empty = minf(time_until_empty, thirst / thirst_rate)
	hunger -= hunger_rate * delta
	thirst -= thirst_rate * delta
	# Damage only covers the part of this frame spent at zero, without double damage.
	var damage_duration: float = maxf(delta - time_until_empty, 0.0)
	if damage_duration > 0.0:
		health -= maxf(deprivation_damage_per_second, 0.0) * damage_duration


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("eat"):
		eat_cooked_meat()
		get_viewport().set_input_as_handled()


func eat_cooked_meat() -> bool:
	if _dead or _is_eating or hunger >= 100.0 or cooked_meat_hunger_restore <= 0.0:
		return false
	_is_eating = true
	if not Inventory.remove_item("cooked_meat", 1):
		_is_eating = false
		return false
	hunger += cooked_meat_hunger_restore
	_is_eating = false
	return true


func _publish_initial_state() -> void:
	health_changed.emit(health)
	hunger_changed.emit(hunger)
	thirst_changed.emit(thirst)
	_check_for_death()


func _check_for_death() -> void:
	if _dead or health > 0.0:
		return
	_dead = true
	set_process(false)
	set_process_unhandled_input(false)
	player_died.emit()
