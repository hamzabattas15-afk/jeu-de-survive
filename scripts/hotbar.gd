extends HBoxContainer

const ITEM_NAMES: Dictionary = {
	"wooden_spear": "Wooden\nSpear", "stone_axe": "Stone\nAxe", "torch": "Torch"
}
const ITEM_COLORS: Dictionary = {
	"wooden_spear": Color(0.9, 0.76, 0.5), "stone_axe": Color(0.7, 0.85, 0.95),
	"torch": Color(1.0, 0.73, 0.25)
}

var _buttons: Array[Button] = []
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func _ready() -> void:
	_normal_style = _make_style(Color(0.055, 0.075, 0.065, 0.85), Color(0.35, 0.4, 0.35))
	_selected_style = _make_style(Color(0.22, 0.22, 0.12, 0.95), Color(1.0, 0.8, 0.35))
	var index: int = 0
	while index < Equipment.SLOT_COUNT:
		var button: Button = Button.new()
		button.name = "Slot%d" % (index + 1)
		button.custom_minimum_size = Vector2(84, 76)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(Equipment.select_slot.bind(index))
		add_child(button)
		_buttons.append(button)
		index += 1
	Equipment.hotbar_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var index: int = 0
	while index < _buttons.size():
		var item: String = Equipment.slots[index]
		var button: Button = _buttons[index]
		button.text = "%d\n%s" % [index + 1, str(ITEM_NAMES.get(item, "Empty"))]
		button.tooltip_text = item.capitalize() if not item.is_empty() else "Empty slot"
		var color: Color = ITEM_COLORS.get(item, Color(0.65, 0.68, 0.65))
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_hover_color", color)
		var style: StyleBoxFlat = _selected_style if index == Equipment.selected_slot else _normal_style
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		index += 1


func _make_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
