class_name Recipe
extends Resource

@export var name: String = ""
@export var ingredients: Dictionary = {}
@export var result_item: String = ""
@export_range(1, 100, 1, "or_greater") var amount: int = 1
@export_range(0.0, 60.0, 0.1, "or_greater") var duration_seconds: float = 0.0
