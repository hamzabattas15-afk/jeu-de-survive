extends Control

@onready var _restart_button: Button = $Content/RestartButton
@onready var _status_label: Label = $Content/StatusLabel


func _ready() -> void:
	hide()
	_restart_button.pressed.connect(_restart)


func _on_player_died() -> void:
	if visible:
		return
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_restart_button.grab_focus()


func _restart() -> void:
	_restart_button.disabled = true
	var tree: SceneTree = get_tree()
	var restart_error: Error = tree.reload_current_scene()
	if restart_error != OK:
		_restart_button.disabled = false
		_status_label.text = "Restart failed. Please try again."
		push_error("Could not restart the current scene: %s" % error_string(restart_error))
		return
	# Keep old timers paused until the queued reload and inventory reset have finished.
	Inventory.reset.call_deferred()
	tree.set_deferred("paused", false)
