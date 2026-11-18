extends CanvasLayer

const ITEM_COLORS: Dictionary = {
	"wood": Color(0.65, 0.4, 0.2), "stone": Color(0.6, 0.65, 0.7),
	"campfire": Color(1.0, 0.45, 0.15), "raw_meat": Color(0.9, 0.35, 0.4),
	"cooked_meat": Color(0.65, 0.3, 0.18), "water_filter": Color(0.35, 0.75, 0.7),
	"dirty_water": Color(0.5, 0.55, 0.25), "clean_water": Color(0.3, 0.7, 1.0),
	"dirt": Color(0.45, 0.3, 0.2), "straw": Color(0.9, 0.8, 0.35),
	"mud_brick": Color(0.75, 0.4, 0.25), "wooden_spear": Color(0.8, 0.65, 0.4),
	"stone_axe": Color(0.7, 0.8, 0.85), "torch": Color(1.0, 0.8, 0.25)
}
const ITEM_LABELS: Dictionary = {
	"campfire": "Campfires [F]", "water_filter": "Filters [H]",
	"cooked_meat": "Cooked meat [R]", "mud_brick": "Mud bricks [B]"
}

var _inventory_rows: Dictionary = {}
var _visible_item_count: int = 0

@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _inventory_scroll: ScrollContainer = $InventoryPanel/Content/InventoryScroll
@onready var _inventory_list: VBoxContainer = $InventoryPanel/Content/InventoryScroll/ItemList
@onready var _interaction_prompt: Label = $InteractionPrompt
@onready var _time_label: Label = $TimeLabel
@onready var _action_status: Label = $ActionStatus
@onready var _action_status_timer: Timer = $ActionStatusTimer


func _ready() -> void:
	_interaction_prompt.hide()
	_action_status_timer.timeout.connect(_action_status.hide)
	Inventory.inventory_changed.connect(_update_inventory)
	get_viewport().size_changed.connect(_resize_inventory_panel)
	_update_inventory()


func _update_inventory() -> void:
	var children: Array[Node] = _inventory_list.get_children()
	for child in children:
		(child as Control).hide()
	var item_ids: Array[String] = ["wood", "stone"]
	var stored_ids: Array[String] = []
	stored_ids.assign(Inventory.items.keys())
	stored_ids.sort()
	for item_id in stored_ids:
		if not item_ids.has(item_id):
			item_ids.append(item_id)
	_visible_item_count = 0
	for item_id in item_ids:
		var amount: int = Inventory.get_amount(item_id)
		if amount <= 0 and item_id != "wood" and item_id != "stone":
			continue
		var row: HBoxContainer = _get_inventory_row(item_id)
		var count_label: Label = row.get_node("Amount") as Label
		count_label.text = str(amount)
		row.show()
		_inventory_list.move_child(row, _visible_item_count)
		_visible_item_count += 1
	_resize_inventory_panel()


func _get_inventory_row(item_id: String) -> HBoxContainer:
	if _inventory_rows.has(item_id):
		return _inventory_rows[item_id] as HBoxContainer
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(14, 14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.color = ITEM_COLORS.get(item_id, Color(0.7, 0.7, 0.75))
	row.add_child(icon)
	var title: Label = Label.new()
	title.text = str(ITEM_LABELS.get(item_id, item_id.capitalize()))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 16)
	row.add_child(title)
	var count_label: Label = Label.new()
	count_label.name = "Amount"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.custom_minimum_size.x = 32.0
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.add_theme_font_size_override("font_size", 16)
	row.add_child(count_label)
	_inventory_list.add_child(row)
	_inventory_rows[item_id] = row
	return row


func _resize_inventory_panel() -> void:
	# Reserve space for the existing bottom-left stat bars, header, and margins.
	var available_height: float = maxf(48.0, get_viewport().get_visible_rect().size.y - 272.0)
	var content_height: float = float(_visible_item_count * 28 - 4)
	_inventory_scroll.custom_minimum_size.y = minf(content_height, available_height)
	_inventory_panel.reset_size.call_deferred()


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
