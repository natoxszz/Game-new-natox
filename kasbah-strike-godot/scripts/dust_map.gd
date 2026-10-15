class_name DustMap extends Node3D
## Map "Kasbah" : plan inspire des trois voies (Long A / Mid / Tunnels B) d'une map desertique classique.
## Grille 40x40, cases de 3 m. Tout est genere par le code (textures comprises).
const N := 40
const CS := 3.0

var grid: Array = []
var wall_rects: Array = []   # Rect2 en coordonnees monde (x, z) pour le radar
var t_spawns: Array = []
var ct_spawns: Array = []
var _wall_mats: Array = []
var _crate_m: StandardMaterial3D
var _plat_m: StandardMaterial3D
var _cap_m: StandardMaterial3D
var _ground_m: StandardMaterial3D
var _asph_tex: ImageTexture

func cell(c: int, r: int) -> Vector3:
	return Vector3(-60.0 + (c + 0.5) * CS, 0.0, -60.0 + (r + 0.5) * CS)

func build() -> void:
	_make_grid()
	_make_materials()
	_floor()
	_walls()
	_props()
	for c in [14, 16, 19, 21, 27]:
		t_spawns.append(cell(c, 37) + Vector3(0, 0.2, 0))
	for c in [15, 17, 19, 21]:
		ct_spawns.append(cell(c, 7) + Vector3(0, 0.2, 0))

func _carve(a: int, b: int, r: int, q: int, ch := ".") -> void:
	for y in range(r, q + 1):
		for x in range(a, b + 1):
			grid[y][x] = ch

func _make_grid() -> void:
	for r in N:
		var row := []
		row.resize(N)
		row.fill("#")
		grid.append(row)
	for a in [[3,9,2,11],[10,11,6,7],[11,19,5,8],[14,23,5,13],[24,27,4,15],[27,33,2,9],[33,36,7,10],[33,37,10,28],[16,20,14,22],[15,23,22,27],[3,11,12,15],[7,8,16,16],[3,11,17,20],[12,16,16,18],[3,5,21,23],[3,11,24,36],[11,14,34,36],[13,31,35,38],[17,25,28,34],[30,37,29,34]]:
		_carve(a[0], a[1], a[2], a[3])
	_carve(16, 16, 14, 14, "#"); _carve(20, 20, 14, 14, "#")
	_carve(21, 23, 29, 31, "#"); _carve(6, 8, 29, 31, "#")
	_carve(31, 33, 2, 4, "p"); _carve(3, 6, 6, 8, "p")
	for p in [[29,5],[30,7],[28,8],[31,8],[5,4],[6,4],[5,5],[8,8],[9,13],[18,21],[17,24],[21,25],[34,18],[35,18],[34,19],[35,19],[18,36],[24,37],[6,27],[9,32],[5,34],[31,31],[33,33],[17,5],[20,10]]:
		grid[p[1]][p[0]] = "c"
	for p in [[26,6],[8,5],[13,7],[19,30],[4,10]]:
		grid[p[1]][p[0]] = "k"
	for p in [[9,3],[36,25],[35,26],[10,35],[22,36],[28,36],[4,19],[14,17],[34,12]]:
		grid[p[1]][p[0]] = "b"

# ---------- textures procedurales ----------
func _noise(w: int, h: int, base: Color, amt: float) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var n := (randf() - 0.5) * amt
			img.set_pixel(x, y, Color(base.r + n, base.g + n, base.b + n))
	return img

func _tint(img: Image, y0: int, col: Color, k: float) -> void:
	for y in range(y0, img.get_height()):
		for x in img.get_width():
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, k))

func _blot(img: Image, n: int, col: Color, a: float, y0: int, y1: int) -> void:
	for i in n:
		var cx := randi_range(0, img.get_width() - 1)
		var cy := randi_range(y0, y1)
		var r := randi_range(8, 28)
		for y in range(maxi(cy - r, 0), mini(cy + r, img.get_height())):
			for x in range(maxi(cx - r, 0), mini(cx + r, img.get_width())):
				var d := Vector2(x - cx, y - cy).length() / r
				if d < 1.0:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, a * (1.0 - d)))

func _tex(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _mat(t: Texture2D, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _make_materials() -> void:
	# murs : tuile 4 m x 9 m (bande de base, fenetres a volets, porte en arc)
	var base := _noise(256, 512, Color("ebe3d0"), 0.09)
	_blot(base, 14, Color("a08250"), 0.25, 0, 511)
	_blot(base, 10, Color("fffffa"), 0.35, 0, 511)
	for v in 4:
		var img := base.duplicate() as Image
		_tint(img, 384, Color("5c9a89") if v == 1 else Color("d6b068"), 0.85)
		_blot(img, 12, Color("503c1e"), 0.3, 330, 511)
		if v < 2:
			for x in [50, 160]:
				img.fill_rect(Rect2i(x, 250, 44, 66), Color("2b2723"))
				img.fill_rect(Rect2i(x - 16, 250, 16, 66), Color("4c8b6b"))
				img.fill_rect(Rect2i(x + 44, 250, 16, 66), Color("4c8b6b"))
				img.fill_rect(Rect2i(x - 20, 316, 84, 7), Color("d9d2bd"))
		if v == 2:
			img.fill_rect(Rect2i(78, 400, 100, 112), Color("2a2522"))
			for y in range(350, 400):
				for x in range(78, 178):
					if Vector2(x - 128, y - 400).length() <= 50.0:
						img.set_pixel(x, y, Color("2a2522"))
		_wall_mats.append(_mat(_tex(img)))
	# caisses en bois
	var cr := _noise(256, 256, Color("8d6535"), 0.11)
	for x in range(0, 256, 32):
		cr.fill_rect(Rect2i(x, 0, 2, 256), Color("3a2410"))
	cr.fill_rect(Rect2i(0, 0, 256, 14), Color("3a2410")); cr.fill_rect(Rect2i(0, 242, 256, 14), Color("3a2410"))
	cr.fill_rect(Rect2i(0, 0, 14, 256), Color("3a2410")); cr.fill_rect(Rect2i(242, 0, 14, 256), Color("3a2410"))
	_crate_m = _mat(_tex(cr), 0.85)
	_plat_m = StandardMaterial3D.new(); _plat_m.albedo_color = Color("bdb6a5"); _plat_m.roughness = 0.95
	_cap_m = StandardMaterial3D.new(); _cap_m.albedo_color = Color("cfc8b6"); _cap_m.roughness = 1.0
	# sol pave
	var g := _noise(256, 256, Color("b9ab91"), 0.10)
	_blot(g, 22, Color("5a4b32"), 0.3, 0, 255)
	for r in 8:
		g.fill_rect(Rect2i(0, r * 32, 256, 2), Color("3c3223"))
		for x in range(((r % 2) * 16), 256, 32):
			g.fill_rect(Rect2i(x, r * 32, 2, 32), Color("3c3223"))
	_ground_m = _mat(_tex(g), 1.0)
	_ground_m.uv1_scale = Vector3(30, 30, 1)
	# asphalte
	var a := _noise(256, 256, Color("58595c"), 0.13)
	_blot(a, 16, Color("1e1e1e"), 0.3, 0, 255)
	a.fill_rect(Rect2i(8, 0, 6, 256), Color("e7e5de"))
	_asph_tex = _tex(a)

# ---------- geometrie ----------
func _box_mesh(size: Vector3, tu: float, tv: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size / 2.0
	var faces := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP], [Vector3.LEFT, Vector3.BACK, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP]]
	for f in faces:
		var n: Vector3 = f[0]
		var ua: Vector3 = f[1]
		var va: Vector3 = f[2]
		var hu := (ua * h).length()
		var hv := (va * h).length()
		var pts := []
		var uvs := []
		for cc in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			pts.append(n * h + ua * hu * cc.x + va * hv * cc.y)
			uvs.append(Vector2((cc.x + 1.0) * 0.5 * 2.0 * hu / tu, 1.0 - (cc.y + 1.0) * 0.5 * 2.0 * hv / tv))
		var cr: Vector3 = (pts[1] - pts[0]).cross(pts[2] - pts[0])
		var order := [0, 1, 2, 0, 2, 3]
		if cr.dot(n) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i in order:
			st.set_normal(n)
			st.set_uv(uvs[i])
			st.add_vertex(pts[i])
	return st.commit()

func _static_box(center: Vector3, size: Vector3, mesh: Mesh, mat: Material) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = center
	add_child(b)
	return b

func _floor() -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(120, 1, 120)
	cs.shape = sh
	b.add_child(cs)
	b.position.y = -0.5
	add_child(b)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	mi.mesh = pm
	mi.material_override = _ground_m
	add_child(mi)
	_asphalt(33, 37, 10, 28)
	_asphalt(30, 37, 29, 34)

func _asphalt(c1: int, c2: int, r1: int, r2: int) -> void:
	var w := (c2 - c1 + 1) * CS
	var l := (r2 - r1 + 1) * CS
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, l)
	mi.mesh = pm
	var m := _mat(_asph_tex, 0.9)
	m.uv1_scale = Vector3(1, l / 4.0, 1)
	mi.material_override = m
	mi.position = Vector3(-60.0 + (c1 + c2 + 1) * CS / 2.0, 0.02, -60.0 + (r1 + r2 + 1) * CS / 2.0)
	add_child(mi)

func _walls() -> void:
	var open := {}
	var rects := []
	for r in N:
		var nxt := {}
		var c := 0
		while c < N:
			if grid[r][c] != "#":
				c += 1
				continue
			var a := c
			while c < N and grid[r][c] == "#":
				c += 1
			var b := c - 1
			var k := "%d-%d" % [a, b]
			var o: Dictionary
			if open.has(k):
				o = open[k]
				o["r2"] = r
			else:
				o = {"a": a, "b": b, "r1": r, "r2": r}
				rects.append(o)
			nxt[k] = o
		open = nxt
	for o in rects:
		var border: bool = o.a == 0 or o.b == N - 1 or o.r1 == 0 or o.r2 == N - 1
		var h := 9.0 if border else (6.5 if (o.a + o.r1) % 2 == 0 else 8.0)
		var w: float = (o.b - o.a + 1) * CS
		var d: float = (o.r2 - o.r1 + 1) * CS
		var pos := Vector3(-60.0 + (o.a + o.b + 1) * CS / 2.0, h / 2.0, -60.0 + (o.r1 + o.r2 + 1) * CS / 2.0)
		var size := Vector3(w, h, d)
		_static_box(pos, size, _box_mesh(size, 4.0, 9.0), _wall_mats[(o.a * 5 + o.r1 * 11) % 4])
		var cap := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w + 0.3, 0.35, d + 0.3)
		cap.mesh = bm
		cap.material_override = _cap_m
		cap.position = Vector3(pos.x, h + 0.175, pos.z)
		add_child(cap)
		wall_rects.append(Rect2(pos.x - w / 2.0, pos.z - d / 2.0, w, d))

func _props() -> void:
	for r in N:
		for c in N:
			var ch: String = grid[r][c]
			var p := cell(c, r)
			if ch == "c" or ch == "k":
				var h := 3.0 if ch == "c" else 1.5
				var size := Vector3(CS, h, CS)
				_static_box(p + Vector3(0, h / 2.0, 0), size, _box_mesh(size, 3.0, 3.0), _crate_m)
			elif ch == "p":
				var size := Vector3(CS, 1.5, CS)
				_static_box(p + Vector3(0, 0.75, 0), size, _box_mesh(size, 3.0, 3.0), _plat_m)
			elif ch == "b":
				_barrel(p)
	_car(cell(36, 13), false)
	_car(cell(7, 14), true)
	for p in [[28, 3], [4, 3], [15, 6], [10, 26], [27, 37], [24, 12]]:
		_palm(cell(p[0], p[1]))

func _barrel(p: Vector3) -> void:
	var b := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.48; cm.bottom_radius = 0.48; cm.height = 1.1
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("8a5030"); m.metallic = 0.6; m.roughness = 0.55
	mi.mesh = cm; mi.material_override = m
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.48; sh.height = 1.1
	cs.shape = sh
	b.add_child(cs)
	b.position = p + Vector3(0, 0.55, 0)
	add_child(b)

func _car(p: Vector3, along_x: bool) -> void:
	var b := StaticBody3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d8c9a0"); m.metallic = 0.3; m.roughness = 0.4
	var gl := StandardMaterial3D.new()
	gl.albedo_color = Color("2a3138"); gl.roughness = 0.1; gl.metallic = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(4.4, 0.8, 1.9)
	body.mesh = bm; body.material_override = m; body.position.y = 0.7
	b.add_child(body)
	var cab := MeshInstance3D.new()
	var cm := BoxMesh.new(); cm.size = Vector3(2.3, 0.7, 1.7)
	cab.mesh = cm; cab.material_override = gl; cab.position = Vector3(-0.2, 1.45, 0)
	b.add_child(cab)
	for w in [[1.4, 0.9], [1.4, -0.9], [-1.4, 0.9], [-1.4, -0.9]]:
		var wh := MeshInstance3D.new()
		var wm := CylinderMesh.new(); wm.top_radius = 0.35; wm.bottom_radius = 0.35; wm.height = 0.25
		wh.mesh = wm; wh.rotation.x = PI / 2.0; wh.position = Vector3(w[0], 0.35, w[1])
		b.add_child(wh)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new(); sh.size = Vector3(4.4, 1.8, 1.9)
	cs.shape = sh; cs.position.y = 0.9
	b.add_child(cs)
	b.position = p
	b.rotation.y = 0.0 if along_x else PI / 2.0
	add_child(b)

func _palm(p: Vector3) -> void:
	var g := Node3D.new()
	g.position = p
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.18; cm.bottom_radius = 0.3; cm.height = 6.0
	var tm := StandardMaterial3D.new(); tm.albedo_color = Color("6e5a3d")
	trunk.mesh = cm; trunk.material_override = tm; trunk.position.y = 3.0
	g.add_child(trunk)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("4f7a35"); lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 9:
		var piv := Node3D.new()
		piv.position.y = 6.0
		piv.rotation.y = i / 9.0 * TAU
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new(); qm.size = Vector2(0.9, 3.4)
		q.mesh = qm; q.material_override = lm
		q.position.z = -1.6
		q.rotation.x = -PI / 2.0 + 0.5
		piv.add_child(q)
		g.add_child(piv)
	add_child(g)

func zone_at(pos: Vector3) -> String:
	var c := floori((pos.x + 60.0) / CS)
	var r := floori((pos.z + 60.0) / CS)
	if c <= 11 and r <= 11: return "Site B"
	if c <= 11 and r <= 15: return "B Car"
	if r <= 8 and c <= 19: return "Fenêtre B"
	if c <= 11 and r <= 23: return "Upper Tunnels"
	if c >= 27 and c <= 33 and r <= 9: return "Site A"
	if c >= 33 and r <= 10: return "Rampe A"
	if c >= 24 and c <= 27 and r <= 15: return "Short"
	if r <= 13 and c <= 23: return "Spawn CT"
	if c >= 33 and r <= 21: return "Long A"
	if c >= 33 and r <= 28: return "Pit"
	if c >= 29 and r >= 29 and r <= 34: return "Rampe T"
	if c <= 11 and r >= 24: return "Outside Tunnels"
	if r >= 35: return "Spawn T"
	if r >= 28: return "Cour"
	if r >= 22: return "Top Mid"
	if c >= 12 and c <= 16 and r >= 16 and r <= 18: return "Lower Tunnels"
	if r <= 15: return "Mid Doors"
	return "Mid"
