extends Node

signal busy_changed(is_busy: bool)
signal progress_changed(recipe_name: String, progress: float)
signal craft_completed(recipe_name: String, amount: int)

var _is_crafting: bool = false
var _pending_recipe: Recipe = null
var _reserved_costs: Dictionary = {}
var _elapsed: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	progress_changed.emit(
		_pending_recipe.name, minf(_elapsed / _pending_recipe.duration_seconds, 1.0)
	)
	if _elapsed >= _pending_recipe.duration_seconds:
		_finish_timed_craft(true)


func can_craft(recipe: Recipe) -> bool:
	if _is_crafting or recipe == null or recipe.result_item.is_empty() or recipe.amount <= 0:
		return false
	return Inventory.has_items(recipe.ingredients)


func craft(recipe: Recipe) -> bool:
	if _is_crafting or not can_craft(recipe):
		return false

	_is_crafting = true
	# Reserve all ingredients atomically; timed recipes award their result later.
	var signals_were_blocked: bool = Inventory.is_blocking_signals()
	Inventory.set_block_signals(true)
	var ingredient_ids: Array[String] = []
	ingredient_ids.assign(recipe.ingredients.keys())
	var paid_costs: Dictionary = {}
	var succeeded: bool = true
	for item_id in ingredient_ids:
		var required_amount: int = int(recipe.ingredients[item_id])
		if required_amount == 0:
			continue
		if not Inventory.remove_item(item_id, required_amount):
			succeeded = false
			break
		paid_costs[item_id] = required_amount

	if succeeded:
		if recipe.duration_seconds > 0.0:
			_pending_recipe = recipe.duplicate(true) as Recipe
			_reserved_costs = paid_costs
			_elapsed = 0.0
		else:
			Inventory.add_item(recipe.result_item, recipe.amount)
	else:
		for item_id in ingredient_ids:
			if paid_costs.has(item_id):
				Inventory.add_item(item_id, int(paid_costs[item_id]))
	Inventory.set_block_signals(signals_were_blocked)
	_is_crafting = _pending_recipe != null
	if _is_crafting:
		busy_changed.emit(true)
		progress_changed.emit(_pending_recipe.name, 0.0)
		set_process(true)
	if succeeded and not signals_were_blocked:
		Inventory.inventory_changed.emit()
	if succeeded and not _is_crafting:
		craft_completed.emit(recipe.name, recipe.amount)
	return succeeded


func cancel_craft() -> void:
	if _pending_recipe != null:
		_finish_timed_craft(false)


func _finish_timed_craft(completed: bool) -> void:
	set_process(false)
	var recipe: Recipe = _pending_recipe
	var signals_were_blocked: bool = Inventory.is_blocking_signals()
	Inventory.set_block_signals(true)
	if completed:
		Inventory.add_item(recipe.result_item, recipe.amount)
	else:
		var item_ids: Array[String] = []
		item_ids.assign(_reserved_costs.keys())
		for item_id in item_ids:
			Inventory.add_item(item_id, int(_reserved_costs[item_id]))
	_pending_recipe = null
	_reserved_costs.clear()
	_elapsed = 0.0
	_is_crafting = false
	Inventory.set_block_signals(signals_were_blocked)
	busy_changed.emit(false)
	if not signals_were_blocked:
		Inventory.inventory_changed.emit()
	if completed:
		craft_completed.emit(recipe.name, recipe.amount)
