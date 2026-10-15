extends Node3D
## Partie : construit la map, l'environnement, fait apparaitre les joueurs, gere kills et pause.
signal kill_announced(text: String)

var map: DustMap
var players: Node3D
var env: Environment
var sun: DirectionalLight3D
var stats := {}           # id -> {name, team, k, d}
var team_kills := [0, 0]
var elapsed := 0.0
var ready_peers: Array = []
var decals: Array = []
var _decal_mat: StandardMaterial3D
var _pause: CanvasLayer
var _pause_box: VBoxContainer
var _paused := false

func _ready() -> void:
    map = DustMap.new()
    add_child(map)
    map.build()
    _make_env()
    players = Node3D.new()
    players.name = "Players"
    add_child(players)
    _build_pause()
    var g := Gradient.new()
    g.set_color(0, Color(0.05, 0.04, 0.03, 0.9))
    g.set_color(1, Color(0, 0, 0, 0))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill = GradientTexture2D.FILL_RADIAL
    gt.fill_from = Vector2(0.5, 0.5)
    gt.fill_to = Vector2(1.0, 0.5)
    _decal_mat = StandardMaterial3D.new()
    _decal_mat.albedo_texture = gt
    _decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _decal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    Settings.changed.connect(func(): Settings.apply_env(env, sun))
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if multiplayer.is_server():
        multiplayer.peer_disconnected.connect(_on_left)
        _peer_ready(1)
    else:
        _request_spawn()

func _request_spawn() -> void:
    while not stats.has(multiplayer.get_unique_id()) and is_inside_tree():
        client_ready.rpc_id(1)
        await get_tree().create_timer(1.0).timeout

func _process(delta: float) -> void:
    elapsed += delta

func _make_env() -> void:
    var we := WorldEnvironment.new()
    env = Environment.new()
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.36, 0.56, 0.82)
    sm.sky_horizon_color = Color(0.86, 0.84, 0.76)
    sm.ground_horizon_color = Color(0.86, 0.83, 0.73)
    sm.ground_bottom_color = Color(0.7, 0.65, 0.55)
    sky.sky_material = sm
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.fog_light_color = Color(0.87, 0.89, 0.88)
    env.fog_density = 0.004
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -35, 0)
    sun.light_color = Color(1.0, 0.93, 0.78)
    sun.light_energy = 1.3
    sun.directional_shadow_max_distance = 140.0
    add_child(sun)
    Settings.apply_env(env, sun)

func spawn_point(team: int) -> Vector3:
    var arr: Array = map.t_spawns if team == 0 else map.ct_spawns
    return arr[randi() % arr.size()]

@rpc("any_peer", "reliable")
func client_ready() -> void:
    if multiplayer.is_server():
        _peer_ready(multiplayer.get_remote_sender_id())

func _peer_ready(id: int) -> void:
    if stats.has(id):
        return
    var team := stats.size() % 2
    var pname: String = Net.players.get(id, {}).get("name", "Joueur")
    ready_peers.append(id)
    for pid in stats.keys():
        spawn_player.rpc_id(id, pid, stats[pid].name, stats[pid].team, spawn_point(stats[pid].team))
    for rp in ready_peers:
        spawn_player.rpc_id(rp, id, pname, team, spawn_point(team))

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int, pname: String, team: int, pos: Vector3) -> void:
    if players.has_node(str(id)):
        return
    stats[id] = {"name": pname, "team": team, "k": 0, "d": 0}
    var p := Player.new()
    p.name = str(id)
    p.pname = pname
    p.team = team
    p.game = self
    p.position = pos
    players.add_child(p)

@rpc("authority", "call_local", "reliable")
func remove_player(id: int) -> void:
    stats.erase(id)
    if players.has_node(str(id)):
        players.get_node(str(id)).queue_free()

func _on_left(id: int) -> void:
    ready_peers.erase(id)
    for rp in ready_peers:
        remove_player.rpc_id(rp, id)

@rpc("any_peer", "call_local", "reliable")
func announce_kill(killer: int, victim: int) -> void:
    if stats.has(victim):
        stats[victim].d += 1
    if stats.has(killer) and killer != victim:
        stats[killer].k += 1
        team_kills[stats[killer].team] += 1
    var kn: String = stats.get(killer, {}).get("name", "?")
    var vn: String = stats.get(victim, {}).get("name", "?")
    kill_announced.emit("%s  »  %s" % [kn, vn])

@rpc("any_peer", "call_local", "unreliable")
func fx_hit(pos: Vector3, normal: Vector3) -> void:
    var d := MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(0.22, 0.22)
    d.mesh = q
    d.material_override = _decal_mat
    add_child(d)
    var up := Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT
    d.look_at_from_position(pos + normal * 0.01, pos - normal, up)
    decals.append(d)
    if decals.size() > 60:
        decals.pop_front().queue_free()

# ---------- menu pause ----------
func _build_pause() -> void:
    _pause = CanvasLayer.new()
    _pause.layer = 20
    _pause.visible = false
    add_child(_pause)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.55)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _pause.add_child(dim)
    var c := CenterContainer.new()
    c.set_anchors_preset(Control.PRESET_FULL_RECT)
    _pause.add_child(c)
    _pause_box = VBoxContainer.new()
    _pause_box.add_theme_constant_override("separation", 10)
    c.add_child(_pause_box)
    _pause_btn("Reprendre", _toggle_pause)
    _pause_btn("Options", _open_options.bind(c))
    _pause_btn("Quitter vers le menu", _quit_to_menu)

func _pause_btn(text: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(320, 44)
    b.pressed.connect(cb)
    _pause_box.add_child(b)

func _quit_to_menu() -> void:
    Net.leave()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _open_options(holder: Control) -> void:
    _pause_box.visible = false
    var om := OptionsMenu.new()
    om.closed.connect(func():
        om.queue_free()
        _pause_box.visible = true)
    holder.add_child(om)

func _toggle_pause() -> void:
    _paused = not _paused
    _pause.visible = _paused
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
    if e.is_action_pressed("ui_cancel"):
        _toggle_pause()
