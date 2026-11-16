extends StaticBody3D

@export_range(0.1, 60.0, 0.1) var purification_seconds: float = 5.0
var _busy: bool = false
@onready var _timer: Timer = $PurificationTimer


func _ready() -> void:
	_timer.timeout.connect(_finish)


func interact(_player: Node3D) -> void:
	if _busy:
		return
	_busy = true
	if not Inventory.remove_item("dirty_water", 1):
		_busy = false
		return
	_timer.start(maxf(purification_seconds, 0.1))


func _finish() -> void:
	if not _busy:
		return
	_busy = false
	Inventory.add_item("clean_water", 1)


func get_interaction_prompt() -> String:
	if _busy:
		return "Filtering... %ds" % maxi(int(ceilf(_timer.time_left)), 1)
	if Inventory.get_amount("dirty_water") == 0:
		return "Collect dirty water at the pond first"
	return "[E] Purify Water"
