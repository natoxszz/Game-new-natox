class_name Dust2Map extends Node3D
## Version jouable simplifiée de Dust II, construite avec géométrie et collisions Godot.
const W := 100.0
var t_spawns: Array[Vector3] = []
var ct_spawns: Array[Vector3] = []
var wall_rects: Array[Rect2] = []

func build() -> void:
	_floor()
	# Bordures et bâtiments des sites A/B, voies Long, Mid, Short et tunnels.
	_wall(Vector3(0, 3, -48), Vector3(100, 6, 2))
	_wall(Vector3(0, 3, 48), Vector3(100, 6, 2))
	_wall(Vector3(-48, 3, 0), Vector3(2, 6, 100))
	_wall(Vector3(48, 3, 0), Vector3(2, 6, 100))
	# Mid et portes Mid
	_wall(Vector3(-17, 3, -23), Vector3(2, 6, 28))
	_wall(Vector3(17, 3, -23), Vector3(2, 6, 28))
	_wall(Vector3(-17, 3, 5), Vector3(2, 6, 18))
	_wall(Vector3(17, 3, 5), Vector3(2, 6, 18))
	_wall(Vector3(0, 3, -10), Vector3(25, 6, 2))
	# Site A / Long A / Short
	_wall(Vector3(27, 3, -28), Vector3(2, 6, 24))
	_wall(Vector3(36, 3, -16), Vector3(20, 6, 2))
	_wall(Vector3(29, 3, -5), Vector3(2, 6, 22))
	_wall(Vector3(38, 3, 5), Vector3(20, 6, 2))
	_wall(Vector3(43, 3, -1), Vector3(2, 6, 10))
	# Site B / tunnels
	_wall(Vector3(-28, 3, 28), Vector3(2, 6, 24))
	_wall(Vector3(-38, 3, 16), Vector3(20, 6, 2))
	_wall(Vector3(-18, 3, 20), Vector3(2, 6, 18))
	_wall(Vector3(-34, 3, 6), Vector3(26, 6, 2))
	_wall(Vector3(-8, 3, 30), Vector3(18, 6, 2))
	_wall(Vector3(-2, 3, 39), Vector3(2, 6, 18))
	# Caisses et couvertures
	_crate(Vector3(33, 1, -28), Vector3(5, 2, 5))
	_crate(Vector3(39, 1, -31), Vector3(4, 2, 4))
	_crate(Vector3(29, 1, -10), Vector3(3, 2, 3))
	_crate(Vector3(-36, 1, 28), Vector3(5, 2, 5))
	_crate(Vector3(-24, 1, 31), Vector3(4, 2, 4))
	_crate(Vector3(-9, 1, 0), Vector3(3, 2, 3))
	_crate(Vector3(8, 1, -1), Vector3(3, 2, 3))
	for x in [-6.0, -3.0, 3.0, 6.0]:
		t_spawns.append(Vector3(x, 0.2, 40.0))
	for x in [-6.0, -2.0, 2.0, 6.0]:
		ct_spawns.append(Vector3(x, 0.2, -38.0))

func _floor() -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(W, 1, W)
	cs.shape = shape
	body.add_child(cs)
	body.position.y = -0.5
	add_child(body)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(W, W)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8e8879")
	mat.roughness = 1.0
	mesh.material_override = mat
	add_child(mesh)

func _wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c8b99a") if int(pos.x + pos.z) % 2 == 0 else Color("b7a583")
	mat.roughness = 0.95
	mesh.material_override = mat
	body.add_child(mesh)
	body.position = pos
	add_child(body)
	wall_rects.append(Rect2(pos.x - size.x / 2, pos.z - size.z / 2, size.x, size.z))

func _crate(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("76502e")
	mat.roughness = 0.9
	mesh.material_override = mat
	body.add_child(mesh)
	body.position = pos
	add_child(body)
