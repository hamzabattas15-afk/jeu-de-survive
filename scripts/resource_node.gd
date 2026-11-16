class_name ResourceNode
extends StaticBody3D

@export var resource_type: String = "wood"
@export_range(1, 100, 1, "or_greater") var amount_per_hit: int = 1
@export_range(1, 100, 1, "or_greater") var max_hits: int = 3
@export_range(0.1, 300.0, 0.1, "or_greater") var respawn_time: float = 10.0
@export_range(0.1, 10.0, 0.1, "or_greater") var hit_feedback_duration: float = 2.0

var _hits_remaining: int = 0
var _depleted: bool = false
var _base_scale: Vector3 = Vector3.ONE
var _hit_tween: Tween = null

@onready var _visuals: Node3D = $Visuals
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _respawn_timer: Timer = $RespawnTimer
@onready var _hits_label: Label3D = $HitsLabel
@onready var _feedback_timer: Timer = $FeedbackTimer


func _ready() -> void:
	_hits_remaining = maxi(max_hits, 1)
	_base_scale = _visuals.scale
	_respawn_timer.timeout.connect(_respawn)
	_feedback_timer.timeout.connect(_hide_hit_feedback)
	_hits_label.hide()


func is_available() -> bool:
	return not _depleted and is_visible_in_tree()


func get_interaction_prompt() -> String:
	match resource_type:
		"wood":
			return "[E] Gather Wood"
		"stone":
			return "[E] Mine Stone"
		_:
			return "[E] Gather %s" % resource_type.capitalize()


func interact(_player: Node3D) -> void:
	if not is_available():
		return

	_hits_remaining -= 1
	_show_hit_feedback()
	_play_hit_shake()
	if _hits_remaining <= 0:
		_depleted = true
		_collision_shape.set_deferred("disabled", true)
		# Finish the last hit's feedback before hiding and starting the respawn timer.
		_hit_tween.tween_callback(_finish_depletion)
	Inventory.add_item(resource_type, amount_per_hit)


func _show_hit_feedback() -> void:
	_hits_label.text = "Hits left: %d" % _hits_remaining
	_hits_label.show()
	_feedback_timer.start(maxf(hit_feedback_duration, 0.1))


func _hide_hit_feedback() -> void:
	_feedback_timer.stop()
	_hits_label.hide()


func _play_hit_shake() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	_visuals.scale = _base_scale
	_hit_tween = create_tween()
	_hit_tween.set_trans(Tween.TRANS_SINE)
	_hit_tween.set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(_visuals, "scale", _base_scale * Vector3(1.08, 0.92, 1.08), 0.06)
	_hit_tween.tween_property(_visuals, "scale", _base_scale * Vector3(0.97, 1.04, 0.97), 0.06)
	_hit_tween.tween_property(_visuals, "scale", _base_scale, 0.08)


func _finish_depletion() -> void:
	_hide_hit_feedback()
	hide()
	_respawn_timer.start(maxf(respawn_time, 0.1))


func _respawn() -> void:
	_hide_hit_feedback()
	_hits_remaining = maxi(max_hits, 1)
	_visuals.scale = _base_scale
	_depleted = false
	show()
	_collision_shape.set_deferred("disabled", false)
