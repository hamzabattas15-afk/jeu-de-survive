extends Node

var _is_crafting: bool = false


func can_craft(recipe: Recipe) -> bool:
	if recipe == null or recipe.result_item.is_empty() or recipe.amount <= 0:
		return false
	return Inventory.has_items(recipe.ingredients)


func craft(recipe: Recipe) -> bool:
	if _is_crafting or not can_craft(recipe):
		return false

	_is_crafting = true
	# Publish one inventory change after the entire synchronous transaction finishes.
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
		Inventory.add_item(recipe.result_item, recipe.amount)
	else:
		for item_id in ingredient_ids:
			if paid_costs.has(item_id):
				Inventory.add_item(item_id, int(paid_costs[item_id]))
	Inventory.set_block_signals(signals_were_blocked)
	if succeeded and not signals_were_blocked:
		Inventory.inventory_changed.emit()
	_is_crafting = false
	return succeeded
