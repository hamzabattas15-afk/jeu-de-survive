extends PanelContainer

@export var recipes: Array[Recipe] = []

var _recipe_buttons: Array[Button] = []
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

@onready var _recipe_list: VBoxContainer = $Content/RecipeScroll/RecipeList
@onready var _close_button: Button = $Content/Header/CloseButton
@onready var _status_label: Label = $Content/StatusLabel


func _ready() -> void:
	hide()
	for recipe in recipes:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		# Mouse-only buttons leave movement/jump keys available while the world runs.
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_recipe_pressed.bind(recipe))
		_recipe_list.add_child(button)
		_recipe_buttons.append(button)
	_close_button.pressed.connect(_set_open.bind(false))
	Inventory.inventory_changed.connect(_refresh_buttons)
	Crafting.busy_changed.connect(_on_busy_changed)
	Crafting.craft_completed.connect(_on_craft_completed)
	_refresh_buttons()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crafting"):
		_set_open(not visible)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		_set_open(false)
		# Consume Escape before the player's mouse-capture toggle receives it.
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	Inventory.inventory_changed.disconnect(_refresh_buttons)
	Crafting.busy_changed.disconnect(_on_busy_changed)
	Crafting.craft_completed.disconnect(_on_craft_completed)
	# Scene exit/restart cancels the job; merely closing the menu does not.
	Crafting.cancel_craft()
	if visible:
		Input.mouse_mode = _previous_mouse_mode


func _set_open(open: bool) -> void:
	if open == visible:
		return
	if open:
		_previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_status_label.text = ""
		_refresh_buttons()
		show()
	else:
		hide()
		Input.mouse_mode = _previous_mouse_mode


func _refresh_buttons() -> void:
	var index: int = 0
	while index < recipes.size():
		var recipe: Recipe = recipes[index]
		var button: Button = _recipe_buttons[index]
		button.disabled = not Crafting.can_craft(recipe)
		if recipe == null:
			button.text = "Missing recipe"
		else:
			button.text = "%s x%d | %s | Owned: %d" % [
				recipe.name, recipe.amount, _get_cost_text(recipe),
				Inventory.get_amount(recipe.result_item)
			]
		index += 1


func _get_cost_text(recipe: Recipe) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var item_ids: Array = recipe.ingredients.keys()
	var index: int = 0
	while index < item_ids.size():
		parts.append("%s %s" % [
			str(recipe.ingredients[item_ids[index]]), str(item_ids[index]).capitalize()
		])
		index += 1
	return " + ".join(parts) if not parts.is_empty() else "No ingredients"


func _on_recipe_pressed(recipe: Recipe) -> void:
	if Crafting.craft(recipe):
		if recipe.duration_seconds > 0.0:
			_status_label.text = "Crafting %s..." % recipe.name
	else:
		_status_label.text = "Busy or not enough ingredients to craft."
		_refresh_buttons()


func _on_busy_changed(_is_busy: bool) -> void:
	_refresh_buttons()


func _on_craft_completed(recipe_name: String, amount: int) -> void:
	_status_label.text = "Crafted %s x%d." % [recipe_name, amount]
