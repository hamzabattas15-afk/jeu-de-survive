extends CanvasLayer

@onready var _resource_label: Label = $ResourceLabel
@onready var _interaction_prompt: Label = $InteractionPrompt
@onready var _time_label: Label = $TimeLabel
@onready var _action_status: Label = $ActionStatus
@onready var _action_status_timer: Timer = $ActionStatusTimer


func _ready() -> void:
	_interaction_prompt.hide()
	_action_status_timer.timeout.connect(_action_status.hide)
	Inventory.inventory_changed.connect(_update_resource_label)
	_update_resource_label()


func _update_resource_label() -> void:
	_resource_label.text = "Wood: %d\nStone: %d\nCampfires [F]: %d\nRaw meat: %d\nCooked meat [R]: %d\nFilters [H]: %d\nDirty water: %d\nClean water: %d\nDirt: %d | Straw: %d\nMud bricks [B]: %d" % [
		Inventory.get_amount("wood"),
		Inventory.get_amount("stone"),
		Inventory.get_amount("campfire"),
		Inventory.get_amount("raw_meat"),
		Inventory.get_amount("cooked_meat"),
		Inventory.get_amount("water_filter"),
		Inventory.get_amount("dirty_water"),
		Inventory.get_amount("clean_water"),
		Inventory.get_amount("dirt"),
		Inventory.get_amount("straw"),
		Inventory.get_amount("mud_brick")
	]


func _on_interaction_prompt_changed(prompt_text: String) -> void:
	_interaction_prompt.text = prompt_text
	_interaction_prompt.visible = not prompt_text.is_empty()


func _on_time_changed(hour: float) -> void:
	var minute_of_day: int = int(floorf(fposmod(hour, 24.0) * 60.0))
	var hours: int = int(minute_of_day / 60.0)
	var minutes: int = minute_of_day % 60
	_time_label.text = "%02d:%02d" % [hours, minutes]


func _on_placement_feedback(message: String) -> void:
	_action_status.text = message
	_action_status.show()
	_action_status_timer.start()
