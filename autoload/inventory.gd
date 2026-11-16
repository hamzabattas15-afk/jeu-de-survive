extends Node

signal inventory_changed

# Item IDs are Strings and amounts are ints. Use the methods below to notify the HUD.
var items: Dictionary = {"raw_meat": 0, "cooked_meat": 0}


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_give_raw_meat"):
		add_item("raw_meat", 1)
		get_viewport().set_input_as_handled()


func add_item(item_id: String, amount: int = 1) -> void:
	if item_id.is_empty() or amount <= 0:
		return

	items[item_id] = get_amount(item_id) + amount
	inventory_changed.emit()


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or get_amount(item_id) < amount:
		return false

	var remaining_amount: int = get_amount(item_id) - amount
	if remaining_amount == 0:
		items.erase(item_id)
	else:
		items[item_id] = remaining_amount
	inventory_changed.emit()
	return true


func has_items(costs: Dictionary) -> bool:
	var item_ids: Array = costs.keys()
	var index: int = 0
	while index < item_ids.size():
		# Validate the untyped Dictionary before reading its keys and amounts.
		if typeof(item_ids[index]) != TYPE_STRING:
			return false
		var item_id: String = item_ids[index]
		if item_id.is_empty() or typeof(costs[item_id]) != TYPE_INT:
			return false
		var required_amount: int = int(costs[item_id])
		if required_amount < 0 or get_amount(item_id) < required_amount:
			return false
		index += 1
	return true


func get_amount(item_id: String) -> int:
	return int(items.get(item_id, 0))


func reset() -> void:
	items.clear()
	items["raw_meat"] = 0
	items["cooked_meat"] = 0
	inventory_changed.emit()
