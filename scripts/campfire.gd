class_name Campfire
extends StaticBody3D

@export var is_lit: bool = true

var _is_cooking: bool = false

@onready var _fire: CPUParticles3D = $Fire
@onready var _light: OmniLight3D = $OmniLight3D
@onready var _cooking_timer: Timer = $CookingTimer


func _ready() -> void:
	_fire.emitting = is_lit
	_light.visible = is_lit
	_cooking_timer.timeout.connect(_finish_cooking)


func interact(_player: Node3D) -> void:
	if not is_lit or _is_cooking:
		return
	# Reserve the slot before Inventory emits its change signal.
	_is_cooking = true
	if not Inventory.remove_item("raw_meat", 1):
		_is_cooking = false
		return
	_cooking_timer.start()


func get_interaction_prompt() -> String:
	if not is_lit:
		return "Campfire is unlit"
	if _is_cooking:
		return "Cooking... %ds" % maxi(int(ceilf(_cooking_timer.time_left)), 1)
	if Inventory.get_amount("raw_meat") == 0:
		return "Raw meat needed to cook"
	return "[E] Cook Raw Meat (5s)"


func _finish_cooking() -> void:
	if not _is_cooking:
		return
	_is_cooking = false
	Inventory.add_item("cooked_meat", 1)
