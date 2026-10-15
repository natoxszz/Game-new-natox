extends Node
## Parametres du jeu (sauvegardes dans user://settings.cfg) + touches.
signal changed

const PATH := "user://settings.cfg"
const DEFAULTS := {
    "nickname": "Joueur", "friend_id": "",
    "sens": 1.5, "invert_y": false, "fov": 90.0,
    "ch_style": 0, "ch_size": 8.0, "ch_thick": 2.0, "ch_gap": 4.0, "ch_outline": true,
    "ch_opacity": 1.0, "ch_color": Color(0.2, 1.0, 0.5), "ch_dyn": true, "ch_dot": false,
    "mode": 0, "res": 0, "vsync": true, "fps_max": 0, "brightness": 1.0,
    "preset": 2, "shadows": 2, "msaa": 1, "ssao": true, "glow": true, "scale3d": 1.0, "fog": true,
    "vol_master": 1.0, "vol_fx": 1.0, "vol_music": 0.6, "vol_amb": 0.8, "vol_steps": 1.0, "mute_unfocus": true,
    "hud_scale": 1.0, "radar_scale": 1.0, "show_fps": false,
    "port": 7777,
}
const DEFAULT_KEYS := {
    "move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
    "jump": KEY_SPACE, "walk": KEY_SHIFT, "reload": KEY_R, "scoreboard": KEY_TAB,
}
const KEY_NAMES := {
    "move_forward": "Avancer", "move_back": "Reculer", "move_left": "Gauche", "move_right": "Droite",
    "jump": "Sauter", "walk": "Marcher", "reload": "Recharger", "scoreboard": "Tableau des scores",
}
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const PRESETS := [
    {"shadows": 0, "msaa": 0, "ssao": false, "glow": false, "scale3d": 0.7, "fog": false},
    {"shadows": 1, "msaa": 0, "ssao": false, "glow": false, "scale3d": 0.85, "fog": true},
    {"shadows": 2, "msaa": 1, "ssao": true, "glow": true, "scale3d": 1.0, "fog": true},
    {"shadows": 3, "msaa": 2, "ssao": true, "glow": true, "scale3d": 1.0, "fog": true},
]

var v: Dictionary = {}
var keys: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for b in ["Effects", "Music", "Ambient", "Steps"]:
        if AudioServer.get_bus_index(b) == -1:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
    reset_values()
    var c := ConfigFile.new()
    if c.load(PATH) == OK:
        for k in DEFAULTS:
            v[k] = c.get_value("s", k, DEFAULTS[k])
        for a in DEFAULT_KEYS:
            keys[a] = c.get_value("keys", a, DEFAULT_KEYS[a])
    if str(v.friend_id) == "":
        v.friend_id = "%04d" % randi_range(0, 9999)
        save()
    apply_keys()
    apply_display()
    apply_audio()
    apply_quality()

func reset_values(keep_identity := false) -> void:
    var nick = v.get("nickname", "Joueur")
    var fid = v.get("friend_id", "")
    v = DEFAULTS.duplicate(true)
    keys = DEFAULT_KEYS.duplicate()
    if keep_identity:
        v.nickname = nick
        v.friend_id = fid
    apply_keys(); apply_display(); apply_audio(); apply_quality()
    changed.emit()

func save() -> void:
    var c := ConfigFile.new()
    for k in v:
        c.set_value("s", k, v[k])
    for a in keys:
        c.set_value("keys", a, keys[a])
    c.save(PATH)

func set_val(k: String, val) -> void:
    v[k] = val
    if k in ["mode", "res", "vsync", "fps_max"]:
        apply_display()
    elif k.begins_with("vol_"):
        apply_audio()
    elif k in ["msaa", "scale3d"]:
        apply_quality()
    changed.emit()

func apply_preset(i: int) -> void:
    v.preset = i
    for k in PRESETS[i]:
        v[k] = PRESETS[i][k]
    apply_quality()
    changed.emit()

func apply_keys() -> void:
    for a in keys:
        if not InputMap.has_action(a):
            InputMap.add_action(a)
        InputMap.action_erase_events(a)
        var e := InputEventKey.new()
        e.physical_keycode = int(keys[a]) as Key
        InputMap.action_add_event(a, e)
    if not InputMap.has_action("fire"):
        InputMap.add_action("fire")
        var m := InputEventMouseButton.new()
        m.button_index = MOUSE_BUTTON_LEFT
        InputMap.action_add_event("fire", m)

func key_label(a: String) -> String:
    var k: int = int(keys.get(a, 0))
    return OS.get_keycode_string(DisplayServer.keyboard_get_label_from_physical(k as Key))

func apply_display() -> void:
    var w := get_window()
    match int(v.mode):
        0:
            w.mode = Window.MODE_WINDOWED
            w.borderless = false
            w.size = RESOLUTIONS[clampi(int(v.res), 0, RESOLUTIONS.size() - 1)]
        1:
            w.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
        2:
            w.mode = Window.MODE_FULLSCREEN
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v.vsync else DisplayServer.VSYNC_DISABLED)
    Engine.max_fps = int(v.fps_max)

func _db(x) -> float:
    return linear_to_db(maxf(float(x), 0.0001))

func apply_audio() -> void:
    AudioServer.set_bus_volume_db(0, _db(v.vol_master))
    for p in [["Effects", "vol_fx"], ["Music", "vol_music"], ["Ambient", "vol_amb"], ["Steps", "vol_steps"]]:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index(p[0]), _db(v[p[1]]))

func apply_quality() -> void:
    var vp := get_viewport()
    vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][clampi(int(v.msaa), 0, 3)]
    vp.scaling_3d_scale = clampf(float(v.scale3d), 0.5, 1.0)

func apply_env(env: Environment, sun: DirectionalLight3D) -> void:
    env.ssao_enabled = bool(v.ssao)
    env.glow_enabled = bool(v.glow)
    env.fog_enabled = bool(v.fog)
    env.adjustment_enabled = true
    env.adjustment_brightness = float(v.brightness)
    var sh := clampi(int(v.shadows), 0, 3)
    sun.shadow_enabled = sh > 0
    if sh > 0:
        RenderingServer.directional_shadow_atlas_set_size([2048, 2048, 4096, 4096][sh], true)
        RenderingServer.directional_soft_shadow_filter_set_quality([RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][sh])

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and v.get("mute_unfocus", false):
        AudioServer.set_bus_mute(0, true)
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        AudioServer.set_bus_mute(0, false)

func crosshair_code() -> String:
    var c: Color = v.ch_color
    return "KS1;%d;%.1f;%.1f;%.1f;%d;%.2f;%s;%d;%d" % [int(v.ch_style), float(v.ch_size), float(v.ch_thick), float(v.ch_gap), int(v.ch_outline), float(v.ch_opacity), c.to_html(false), int(v.ch_dyn), int(v.ch_dot)]

func import_crosshair(code: String) -> bool:
    var p := code.strip_edges().split(";")
    if p.size() != 10 or p[0] != "KS1":
        return false
    v.ch_style = int(p[1]); v.ch_size = float(p[2]); v.ch_thick = float(p[3]); v.ch_gap = float(p[4])
    v.ch_outline = p[5] == "1"; v.ch_opacity = float(p[6]); v.ch_color = Color.html(p[7])
    v.ch_dyn = p[8] == "1"; v.ch_dot = p[9] == "1"
    changed.emit()
    return true
