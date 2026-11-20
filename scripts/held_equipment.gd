extends Node3D

var _shaft: MeshInstance3D = MeshInstance3D.new()
var _head: MeshInstance3D = MeshInstance3D.new()


func _ready() -> void:
	_shaft.name = "Shaft"
	_head.name = "Head"
	add_child(_shaft)
	add_child(_head)
	_shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Equipment.equipped_changed.connect(_show_item)
	_show_item(Equipment.get_equipped_item())


func _show_item(item: String) -> void:
	visible = not item.is_empty()
	if not visible:
		return
	_shaft.mesh = _cylinder(0.035, 0.035, 0.75)
	_shaft.material_override = _material(Color(0.4, 0.23, 0.1))
	_head.position = Vector3(0, 0.38, 0)
	match item:
		"wooden_spear":
			_shaft.mesh = _cylinder(0.03, 0.03, 1.5)
			_head.mesh = _cylinder(0.0, 0.075, 0.25)
			_head.position.y = 0.85
			_head.material_override = _material(Color(0.65, 0.68, 0.7))
		"stone_axe":
			_head.mesh = _box(Vector3(0.4, 0.23, 0.12))
			_head.position.x = 0.1
			_head.material_override = _material(Color(0.55, 0.6, 0.65))
		"torch":
			_head.mesh = _cylinder(0.07, 0.1, 0.25)
			_head.material_override = _material(Color(1.0, 0.55, 0.12))


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


func _box(size: Vector3) -> BoxMesh:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return mesh


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic_specular = 0.0
	return material
