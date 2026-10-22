class_name Dust2RealMap extends Node3D
## Map "Dust2 (modèle)" : charge le vrai modèle .obj importé, ajoute les collisions
## et place les points d'apparition sur le sol par raycast.
signal spawns_ready

const MODEL_PATH := "res://assets/maps/de_dust2/de_dust2.obj"
## Les maps CS sont en "unités Hammer" (1 unité ≈ 1 pouce). 0.0254 = mètres Godot.
## Si la map paraît trop grande/petite, ajuste cette valeur.
const MAP_SCALE := 0.0254
## Positions XZ (en mètres, après mise à l'échelle) des spawns. Laisse vide pour un
## placement automatique aux deux extrémités de la map. Remplis-les après un test.
const T_SPAWN_XZ: Array[Vector2] = []
const CT_SPAWN_XZ: Array[Vector2] = []

var t_spawns: Array[Vector3] = []
var ct_spawns: Array[Vector3] = []
var wall_rects: Array[Rect2] = []   # utilisé par le radar ; vide pour ce modèle
var loaded := false
var _aabb := AABB()

func build() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		push_error("Modèle introuvable : %s (voir README)" % MODEL_PATH)
		_fallback()
		return
	var res = load(MODEL_PATH)
	var root := Node3D.new()
	root.scale = Vector3.ONE * MAP_SCALE
	add_child(root)
	var meshes: Array[MeshInstance3D] = []
	if res is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = res
		root.add_child(mi)
		meshes.append(mi)
	elif res is PackedScene:
		var inst: Node = res.instantiate()
		root.add_child(inst)
		_collect(inst, meshes)
	for mi in meshes:
		# Collision exacte sur la géométrie (sol, murs, escaliers, caisses).
		mi.create_trimesh_collision()
		var a: AABB = mi.global_transform * mi.get_aabb() if mi.is_inside_tree() else mi.get_aabb()
		a = AABB(a.position * MAP_SCALE, a.size * MAP_SCALE)
		_aabb = a if _aabb.size == Vector3.ZERO else _aabb.merge(a)
	loaded = true
	_provisional_spawns()
	_snap_spawns.call_deferred()

func _collect(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)

func _provisional_spawns() -> void:
	var top := _aabb.end.y + 2.0
	var tx: Array[Vector2] = T_SPAWN_XZ.duplicate()
	var cx: Array[Vector2] = CT_SPAWN_XZ.duplicate()
	if tx.is_empty() or cx.is_empty():
		# Placement auto : les deux bouts de l'axe le plus long de la map.
		var c := _aabb.get_center()
		var long_x := _aabb.size.x >= _aabb.size.z
		var half := (_aabb.size.x if long_x else _aabb.size.z) * 0.4
		for i in 4:
			var off := (i - 1.5) * 2.0
			var a := Vector2(c.x + (half if long_x else off), c.z + (off if long_x else half))
			var b := Vector2(c.x - (half if long_x else -off), c.z - (off if long_x else half))
			if tx.size() < 4: tx.append(a)
			if cx.size() < 4: cx.append(b)
	for p in tx: t_spawns.append(Vector3(p.x, top, p.y))
	for p in cx: ct_spawns.append(Vector3(p.x, top, p.y))

func _snap_spawns() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	for arr in [t_spawns, ct_spawns]:
		for i in arr.size():
			var from: Vector3 = arr[i]
			var q := PhysicsRayQueryParameters3D.create(from, Vector3(from.x, _aabb.position.y - 5.0, from.z))
			var hit := space.intersect_ray(q)
			if hit:
				arr[i] = hit.position + Vector3.UP * 0.2
	spawns_ready.emit()

func _fallback() -> void:
	# Si le modèle n'est pas encore dans le projet, on utilise la Dust2 faite par code.
	var d := Dust2Map.new()
	add_child(d)
	d.build()
	t_spawns = d.t_spawns
	ct_spawns = d.ct_spawns
	wall_rects = d.wall_rects
	_emit_later.call_deferred()

func _emit_later() -> void:
	spawns_ready.emit()
