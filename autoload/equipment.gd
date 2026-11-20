extends Node

signal equipped_changed(item: String)
signal hotbar_changed

const SLOT_COUNT: int = 5
const DAMAGE_VALUES: Dictionary = {"wooden_spear": 15, "stone_axe": 10, "torch": 0}
const EQUIPPABLE_ITEMS: Array[String] = ["wooden_spear", "stone_axe", "torch"]

var slots: Array[String] = ["", "", "", "", ""]
var selected_slot: int = 0
var _published_item: String = ""


func _ready() -> void:
	Inventory.inventory_changed.connect(_sync_inventory)
	_sync_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var index: int = 0
	while index < SLOT_COUNT:
		if event.is_action_pressed("hotbar_%d" % (index + 1)):
			select_slot(index)
			get_viewport().set_input_as_handled()
			return
		index += 1
	# Leave wheel scrolling available to the crafting/inventory UI.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("hotbar_next"):
		select_slot((selected_slot + 1) % SLOT_COUNT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hotbar_previous"):
		select_slot((selected_slot + SLOT_COUNT - 1) % SLOT_COUNT)
		get_viewport().set_input_as_handled()


func select_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT or index == selected_slot:
		return
	selected_slot = index
	hotbar_changed.emit()
	_publish_equipped()


func get_equipped_item() -> String:
	var item: String = slots[selected_slot]
	return item if Inventory.get_amount(item) > 0 else ""


func get_equipped_damage() -> int:
	return int(DAMAGE_VALUES.get(get_equipped_item(), 0))


func get_gather_multiplier(resource_type: String) -> int:
	return 2 if resource_type == "wood" and get_equipped_item() == "stone_axe" else 1


func _sync_inventory() -> void:
	var changed: bool = false
	var index: int = 0
	while index < SLOT_COUNT:
		if not slots[index].is_empty() and Inventory.get_amount(slots[index]) <= 0:
			slots[index] = ""
			changed = true
		index += 1
	# Inventory publishes each completed craft, so new tools occupy the first free slot.
	for item in EQUIPPABLE_ITEMS:
		if Inventory.get_amount(item) <= 0 or slots.has(item):
			continue
		var free_slot: int = slots.find("")
		if free_slot == -1:
			break
		slots[free_slot] = item
		changed = true
	if slots.count("") == SLOT_COUNT and selected_slot != 0:
		selected_slot = 0
		changed = true
	if changed:
		hotbar_changed.emit()
	_publish_equipped()


func _publish_equipped() -> void:
	var item: String = get_equipped_item()
	if item != _published_item:
		_published_item = item
		equipped_changed.emit(item)
