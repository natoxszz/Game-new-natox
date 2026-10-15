extends Node3D
## Décor 3D procédural du menu : désert, kasbah et combattants provisoires.
## Les modèles définitifs et animations pourront remplacer les silhouettes plus tard.

var _camera: Camera3D
var _time := 0.0
var _soldiers: Array[Node3D] = []

func _ready() -> void:
	_build_environment()
	_build_landscape()
	_build_kasbah()
	_build_soldiers()
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 5.2, 16.5)
	_camera.fov = 54.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 2.2, 0.0), Vector3.UP)
	_camera.current = true

func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(_camera):
		_camera.position.x = sin(_time * 0.12) * 0.42
		_camera.position.y = 5.2 + sin(_time * 0.18) * 0.12
		_camera.look_at(Vector3(0.0, 2.2, 0.0), Vector3.UP)
	for i in _soldiers.size():
		var soldier := _soldiers[i]
		if is_instance_valid(soldier):
			soldier.rotation.y = soldier.get_meta("base_yaw", 0.0) + sin(_time * 0.45 + float(i)) * 0.025

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.19, 0.29, 0.42)
	sky_mat.sky_horizon_color = Color(0.94, 0.57, 0.30)
	sky_mat.ground_horizon_color = Color(0.75, 0.49, 0.30)
	sky_mat.ground_bottom_color = Color(0.22, 0.16, 0.12)
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.83, 0.54, 0.35)
	env.fog_density = 0.006
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.73, 0.49)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _build_landscape() -> void:
	_box("Sable", Vector3(90.0, 0.5, 70.0), Vector3(0.0, -0.45, 0.0), Color(0.48, 0.30, 0.16))
	for i in 12:
		var x := float(i % 6) * 9.0 - 23.0
		var z := -float(i / 6) * 11.0 - 9.0
		var dune := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		dune.mesh = mesh
		dune.scale = Vector3(5.8, 1.0 + float(i % 3) * 0.25, 3.0)
		dune.position = Vector3(x, -0.1, z)
		dune.material_override = _mat(Color(0.61, 0.39, 0.22))
		add_child(dune)
	for i in 15:
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.55 + float(i % 3) * 0.22
		rock.mesh = rock_mesh
		rock.scale = Vector3(1.4, 0.65, 0.9)
		rock.position = Vector3(float((i * 7) % 31) - 15.0, -0.05, float((i * 11) % 25) - 12.0)
		rock.material_override = _mat(Color(0.35, 0.25, 0.19))
		add_child(rock)

func _build_kasbah() -> void:
	var sand := Color(0.67, 0.43, 0.27)
	var shade := Color(0.43, 0.27, 0.19)
	_box("Mur gauche", Vector3(7.0, 5.0, 2.0), Vector3(-11.0, 2.05, -5.0), sand)
	_box("Tour gauche", Vector3(3.0, 7.2, 3.0), Vector3(-14.5, 3.15, -7.0), shade)
	_box("Tour droite", Vector3(3.2, 6.0, 3.0), Vector3(12.5, 2.55, -8.0), sand)
	_box("Mur droit", Vector3(8.0, 4.4, 2.0), Vector3(10.0, 1.75, -5.5), shade)
	_box("Bâtiment fond", Vector3(8.0, 8.0, 4.0), Vector3(0.0, 3.45, -12.0), sand)
	_box("Toit fond", Vector3(8.8, 0.65, 4.5), Vector3(0.0, 7.7, -12.0), shade)
	_box("Entrée sombre", Vector3(2.1, 3.0, 0.18), Vector3(0.0, 1.15, -9.88), Color(0.15, 0.11, 0.09))
	_box("Balcon", Vector3(5.0, 0.35, 1.0), Vector3(0.0, 4.2, -9.5), Color(0.33, 0.22, 0.16))
	for x in [-4.5, 4.5]:
		_box("Colonne", Vector3(0.65, 3.4, 0.65), Vector3(x, 1.25, -8.7), Color(0.76, 0.54, 0.35))
		_box("Chapiteau", Vector3(1.0, 0.35, 1.0), Vector3(x, 3.0, -8.7), shade)

func _build_soldiers() -> void:
	# Deux silhouettes de chaque camp, provisoires et remplaçables par les modèles Mixamo.
	_make_soldier(Vector3(-5.3, 0.0, 3.0), Color(0.30, 0.36, 0.25), Color(0.18, 0.22, 0.17), -0.12)
	_make_soldier(Vector3(-7.4, 0.0, 1.0), Color(0.36, 0.39, 0.30), Color(0.20, 0.24, 0.19), 0.08)
	_make_soldier(Vector3(5.2, 0.0, 2.5), Color(0.25, 0.34, 0.42), Color(0.16, 0.21, 0.27), 0.12)
	_make_soldier(Vector3(7.2, 0.0, 0.7), Color(0.31, 0.37, 0.43), Color(0.17, 0.22, 0.28), -0.08)

func _make_soldier(pos: Vector3, uniform: Color, gear: Color, yaw: float) -> void:
	var soldier := Node3D.new()
	soldier.position = pos
	soldier.rotation.y = yaw
	soldier.set_meta("base_yaw", yaw)
	add_child(soldier)
	_soldiers.append(soldier)
	_box("Bottes", Vector3(0.28, 0.22, 0.42), Vector3(-0.18, 0.12, 0.0), gear, soldier)
	_box("Bottes", Vector3(0.28, 0.22, 0.42), Vector3(0.18, 0.12, 0.0), gear, soldier)
	_box("Jambes", Vector3(0.58, 0.75, 0.42), Vector3(0.0, 0.58, 0.0), uniform, soldier)
	_box("Gilet", Vector3(0.78, 0.82, 0.42), Vector3(0.0, 1.45, 0.0), gear, soldier)
	_box("Bras", Vector3(0.22, 0.72, 0.25), Vector3(-0.48, 1.48, -0.02), uniform, soldier)
	_box("Bras", Vector3(0.22, 0.72, 0.25), Vector3(0.48, 1.48, -0.02), uniform, soldier)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.08, 0.0)
	head.material_override = _mat(Color(0.63, 0.45, 0.33))
	soldier.add_child(head)
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.27
	helmet_mesh.height = 0.3
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0.0, 2.28, 0.0)
	helmet.material_override = _mat(gear)
	soldier.add_child(helmet)
	_box("Fusil", Vector3(0.12, 0.12, 1.05), Vector3(0.35, 1.48, -0.52), Color(0.09, 0.10, 0.10), soldier)

func _box(label: String, dimensions: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	if parent == null:
		add_child(item)
	else:
		parent.add_child(item)
	return item

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
