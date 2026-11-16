extends Area3D


func interact(_player: Node3D) -> void:
	Inventory.add_item("dirty_water", 1)


func get_interaction_prompt() -> String:
	return "[E] Collect Dirty Water"
