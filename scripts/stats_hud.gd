extends VBoxContainer

@onready var _health_bar: ProgressBar = $Health/Bar
@onready var _hunger_bar: ProgressBar = $Hunger/Bar
@onready var _thirst_bar: ProgressBar = $Thirst/Bar
@onready var _health_label: Label = $Health/ValueLabel
@onready var _hunger_label: Label = $Hunger/ValueLabel
@onready var _thirst_label: Label = $Thirst/ValueLabel


func _on_health_changed(value: float) -> void:
	_health_bar.value = value
	_health_label.text = "Health: %d / 100" % int(ceilf(value))


func _on_hunger_changed(value: float) -> void:
	_hunger_bar.value = value
	_hunger_label.text = "Hunger: %d / 100" % int(ceilf(value))


func _on_thirst_changed(value: float) -> void:
	_thirst_bar.value = value
	_thirst_label.text = "Thirst: %d / 100" % int(ceilf(value))
