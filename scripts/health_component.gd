class_name HealthComponent
extends Node

signal damaged(amount: int, source: Node3D)
signal died

@export_range(1, 1000, 1, "or_greater") var max_health: int = 100
var current_health: int = 0


func _ready() -> void:
	max_health = maxi(max_health, 1)
	current_health = max_health


# The owning body's take_damage method can forward to this component.
func take_damage(amount: int, source: Node3D) -> void:
	if amount <= 0 or current_health <= 0:
		return
	var applied_damage: int = mini(amount, current_health)
	current_health -= applied_damage
	var killed: bool = current_health == 0
	damaged.emit(applied_damage, source)
	if killed:
		died.emit()
