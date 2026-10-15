class_name Player extends CharacterBody3D
## Joueur FPS. Le proprietaire (authority) le controle ; position/rotation sont repliquees aux autres.
const SPEED := 7.0
const WALK := 3.6
const JUMP := 9.0
const GRAV := 24.0

var pname := "Joueur"
var team := 0                # 0 = T, 1 = CT
var game: Node
var health := 100
var ammo := 30
var reserve := 90
var dead := false
var head: Node3D
var cam: Camera3D
var hud
var gun: Node3D
var flash: MeshInstance3D
var flash_light: OmniLight3D
var body_vis: Node3D
var col_shape: CollisionShape3D
var shot_player: AudioStreamPlayer3D
var step_player: AudioStreamPlayer3D
var pitch := 0.0
var cd := 0.0
var reload_t := 0.0
var kick := 0.0
var flash_t := 0.0
var step_d := 0.0
var respawn_t := 0.0
var last_pos := Vector3.ZERO

func _enter_tree() -> void:
    var id := str(name).to_int()
    set_multiplayer_authority(id)
    collision_layer = 2
    collision_mask = 1
    col_shape = CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.4
    cap.height = 1.8
    col_shape.shape = cap
    col_shape.position.y = 0.9
    add_child(col_shape)
    _build_visuals()
    head = Node3D.new()
    head.name = "Head"
    head.position.y = 1.6
    add_child(head)
    cam = Camera3D.new()
    cam.keep_aspect = Camera3D.KEEP_WIDTH
    cam.near = 0.05
    cam.far = 400.0
    head.add_child(cam)
    _build_gun()
    shot_player = AudioStreamPlayer3D.new()
    shot_player.stream = Sfx.noise(0.25, 1.0, 0.5, 2.5)
    shot_player.bus = "Effects"
    shot_player.unit_size = 25.0
    add_child(shot_player)
    step_player = AudioStreamPlayer3D.new()
    step_player.stream = Sfx.noise(0.08, 0.5, 0.15, 2.0)
    step_player.bus = "Steps"
    add_child(step_player)
    var cfg := SceneReplicationConfig.new()
    for p in [".:position", ".:rotation", "Head:rotation"]:
        var np := NodePath(p)
        cfg.add_property(np)
        cfg.property_set_replication_mode(np, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
    var sy := MultiplayerSynchronizer.new()
    sy.replication_config = cfg
    sy.set_multiplayer_authority(id)
    add_child(sy)
    if is_multiplayer_authority():
        cam.current = true
        body_vis.visible = false
        hud = Hud.new()
        hud.player = self
        hud.game = game
        add_child(hud)
    last_pos = position

func _build_visuals() -> void:
    body_vis = Node3D.new()
    add_child(body_vis)
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.85, 0.6, 0.25) if team == 0 else Color(0.25, 0.45, 0.9)
    var mi := MeshInstance3D.new()
    var cm := CapsuleMesh.new()
    cm.radius = 0.38
    cm.height = 1.5
    mi.mesh = cm
    mi.material_override = m
    mi.position.y = 0.75
    body_vis.add_child(mi)
    var hd := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.17
    sm.height = 0.34
    hd.mesh = sm
    var hm := StandardMaterial3D.new()
    hm.albedo_color = Color(0.9, 0.75, 0.6)
    hd.material_override = hm
    hd.position.y = 1.65
    body_vis.add_child(hd)
    var lb := Label3D.new()
    lb.text = pname
    lb.position.y = 2.15
    lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lb.pixel_size = 0.005
    lb.font_size = 48
    lb.outline_size = 12
    body_vis.add_child(lb)

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, metal := 0.0) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = 0.5
    bm.material = m
    mi.mesh = bm
    mi.position = pos
    parent.add_child(mi)
    return mi

func _build_gun() -> void:
    gun = Node3D.new()
    gun.position = Vector3(0.2, -0.2, -0.4)
    cam.add_child(gun)
    var dark := Color(0.12, 0.12, 0.14)
    var wood := Color(0.42, 0.27, 0.14)
    _box(gun, Vector3(0.07, 0.11, 0.5), Vector3.ZERO, dark, 0.8)
    _box(gun, Vector3(0.03, 0.03, 0.4), Vector3(0, 0.02, -0.43), Color(0.07, 0.07, 0.08), 0.9)
    _box(gun, Vector3(0.075, 0.075, 0.24), Vector3(0, -0.005, -0.24), wood)
    _box(gun, Vector3(0.06, 0.12, 0.24), Vector3(0, -0.02, 0.32), wood)
    var mag := _box(gun, Vector3(0.05, 0.19, 0.08), Vector3(0, -0.15, 0.04), Color(0.16, 0.16, 0.18), 0.7)
    mag.rotation.x = 0.3
    _box(gun, Vector3(0.02, 0.04, 0.02), Vector3(0, 0.075, -0.5), Color(0.05, 0.05, 0.05))
    flash = MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(0.28, 0.28)
    var fm := StandardMaterial3D.new()
    fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    fm.albedo_color = Color(1.0, 0.75, 0.35)
    fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    q.material = fm
    flash.mesh = q
    flash.position = Vector3(0, 0.02, -0.72)
    flash.visible = false
    gun.add_child(flash)
    flash_light = OmniLight3D.new()
    flash_light.light_color = Color(1.0, 0.65, 0.3)
    flash_light.omni_range = 9.0
    flash_light.visible = false
    flash_light.position = Vector3(0, 0.05, -0.8)
    gun.add_child(flash_light)

func _unhandled_input(e: InputEvent) -> void:
    if not is_multiplayer_authority() or dead:
        return
    if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var s := deg_to_rad(float(Settings.v.sens) * 0.022)
        rotate_y(-e.relative.x * s)
        var inv := -1.0 if Settings.v.invert_y else 1.0
        pitch = clampf(pitch - e.relative.y * s * inv, -1.5, 1.5)
        head.rotation.x = pitch

func _physics_process(delta: float) -> void:
    var moved := Vector2(position.x - last_pos.x, position.z - last_pos.z).length()
    last_pos = position
    if moved > 0.001 and (not is_multiplayer_authority() or is_on_floor()) and not dead:
        step_d += moved
        if step_d > 2.4:
            step_d = 0.0
            step_player.play()
    if not is_multiplayer_authority():
        return
    if dead:
        respawn_t -= delta
        if respawn_t <= 0.0:
            _respawn()
        return
    var active := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
    var dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if active else Vector2.ZERO
    var wish := (transform.basis * Vector3(dir.x, 0, dir.y)).normalized()
    var sp := WALK if Input.is_action_pressed("walk") else SPEED
    var k := minf(1.0, 14.0 * delta)
    velocity.x = lerpf(velocity.x, wish.x * sp, k)
    velocity.z = lerpf(velocity.z, wish.z * sp, k)
    if not is_on_floor():
        velocity.y -= GRAV * delta
    elif active and Input.is_action_just_pressed("jump"):
        velocity.y = JUMP
    move_and_slide()
    cd -= delta
    if reload_t > 0.0:
        reload_t -= delta
        if reload_t <= 0.0:
            var n := mini(30 - ammo, reserve)
            ammo += n
            reserve -= n
    elif active:
        if Input.is_action_just_pressed("reload") and ammo < 30 and reserve > 0:
            reload_t = 1.2
        elif Input.is_action_pressed("fire") and cd <= 0.0:
            if ammo > 0:
                _shoot()
            elif reserve > 0:
                reload_t = 1.2

func _process(delta: float) -> void:
    flash_t -= delta
    flash.visible = flash_t > 0.0
    flash_light.visible = flash_t > 0.0
    if not is_multiplayer_authority():
        return
    cam.fov = float(Settings.v.fov)
    kick = maxf(0.0, kick - delta * 9.0)
    var sway := sin(Time.get_ticks_msec() * 0.012) * 0.006 * minf(Vector2(velocity.x, velocity.z).length() / SPEED, 1.0)
    gun.position = Vector3(0.2 + sway, -0.2 - kick * 0.012 - (0.12 if reload_t > 0.0 else 0.0), -0.4 + kick * 0.05)
    gun.rotation.x = kick * 0.05 + (-0.5 if reload_t > 0.0 else 0.0)
    if hud:
        hud.crosshair.spread = 3.0 + Vector2(velocity.x, velocity.z).length() * 0.8 + kick * 10.0

func _shoot() -> void:
    ammo -= 1
    cd = 0.1
    kick = 1.0
    flash_t = 0.05
    shot_player.play()
    fx_shot.rpc()
    var sp := 0.004 + Vector2(velocity.x, velocity.z).length() * 0.0025 + (0.0 if is_on_floor() else 0.03)
    var bs := cam.global_transform.basis
    var dir := (-bs.z + bs.x * randf_range(-sp, sp) + bs.y * randf_range(-sp, sp)).normalized()
    var from := cam.global_position
    var q := PhysicsRayQueryParameters3D.create(from, from + dir * 250.0, 3, [get_rid()])
    pitch = minf(pitch + 0.012, 1.5)
    head.rotation.x = pitch
    rotate_y(randf_range(-0.003, 0.003))
    var hit := get_world_3d().direct_space_state.intersect_ray(q)
    if hit.is_empty():
        return
    var c = hit.collider
    if c is Player:
        if not c.dead and c.team != team:
            var hs: bool = hit.position.y - c.global_position.y > 1.45
            c.take_damage.rpc_id(c.get_multiplayer_authority(), 100 if hs else 27, multiplayer.get_unique_id())
            if hud:
                hud.hitmarker()
    else:
        game.fx_hit.rpc(hit.position, hit.normal)

@rpc("any_peer", "call_remote", "unreliable")
func fx_shot() -> void:
    shot_player.play()
    flash_t = 0.05

@rpc("any_peer", "call_local", "reliable")
func take_damage(dmg: int, shooter: int) -> void:
    if not is_multiplayer_authority() or dead:
        return
    health -= dmg
    if hud:
        hud.hurt()
    if health <= 0:
        health = 0
        respawn_t = 3.0
        set_dead.rpc(true)
        game.announce_kill.rpc(shooter, str(name).to_int())

@rpc("authority", "call_local", "reliable")
func set_dead(d: bool) -> void:
    dead = d
    col_shape.set_deferred("disabled", d)
    if not is_multiplayer_authority():
        body_vis.visible = not d
        gun.visible = not d

func _respawn() -> void:
    health = 100
    ammo = 30
    reserve = 90
    reload_t = 0.0
    velocity = Vector3.ZERO
    position = game.spawn_point(team)
    set_dead.rpc(false)
