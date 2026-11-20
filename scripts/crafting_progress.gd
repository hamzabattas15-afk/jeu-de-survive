extends VBoxContainer

@onready var _label: Label = $Label
@onready var _bar: ProgressBar = $ProgressBar


func _ready() -> void:
	hide()
	Crafting.progress_changed.connect(_on_progress_changed)
	Crafting.busy_changed.connect(_on_busy_changed)


func _on_progress_changed(recipe_name: String, progress: float) -> void:
	_label.text = "Knapping flint..." if recipe_name == "Flint" else "Crafting %s..." % recipe_name
	_bar.value = progress
	show()


func _on_busy_changed(is_busy: bool) -> void:
	if not is_busy:
		hide()
