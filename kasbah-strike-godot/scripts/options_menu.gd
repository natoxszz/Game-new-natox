class_name OptionsMenu extends PanelContainer
## Menu Options : onglets Jeu / Souris-Clavier / Viseur / Video / Qualite / Audio / HUD.
signal closed

var _snap: Dictionary
var _snap_keys: Dictionary
var _holder: VBoxContainer
var _tabs: TabContainer
var _wait := ""
var _key_btns := {}

func _ready() -> void:
    custom_minimum_size = Vector2(840, 560)
    _snap = Settings.v.duplicate(true)
    _snap_keys = Settings.keys.duplicate()
    _holder = VBoxContainer.new()
    add_child(_holder)
    _build(0)

func _build(sel: int) -> void:
    for c in _holder.get_children():
        c.queue_free()
    _key_btns.clear()
    _tabs = TabContainer.new()
    _tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _holder.add_child(_tabs)
    _tab_game(); _tab_input(); _tab_cross(); _tab_video(); _tab_quality(); _tab_audio(); _tab_hud()
    var bar := HBoxContainer.new()
    bar.alignment = BoxContainer.ALIGNMENT_END
    bar.add_theme_constant_override("separation", 12)
    _holder.add_child(bar)
    _btn(bar, "Par défaut", func():
        Settings.reset_values(true)
        _build(_tabs.current_tab))
    _btn(bar, "Annuler", func():
        Settings.v = _snap.duplicate(true)
        Settings.keys = _snap_keys.duplicate()
        Settings.apply_keys(); Settings.apply_display(); Settings.apply_audio(); Settings.apply_quality()
        Settings.changed.emit()
        closed.emit())
    _btn(bar, "Enregistrer", func():
        Settings.save()
        closed.emit())
    _tabs.current_tab = sel

func _btn(parent: Node, text: String, cb: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(130, 36)
    b.pressed.connect(cb)
    parent.add_child(b)
    return b

func _page(title: String) -> VBoxContainer:
    var sc := ScrollContainer.new()
    sc.name = title
    _tabs.add_child(sc)
    var vb := VBoxContainer.new()
    vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vb.add_theme_constant_override("separation", 10)
    sc.add_child(vb)
    return vb

func _row(vb: Control, label: String, ctrl: Control) -> void:
    var h := HBoxContainer.new()
    var l := Label.new()
    l.text = label
    l.custom_minimum_size.x = 270
    h.add_child(l)
    ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    h.add_child(ctrl)
    vb.add_child(h)

func _slider(vb: Control, label: String, key: String, mn: float, mx: float, step: float) -> void:
    var h := HBoxContainer.new()
    var s := HSlider.new()
    s.min_value = mn; s.max_value = mx; s.step = step
    s.value = float(Settings.v[key])
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var val := Label.new()
    val.custom_minimum_size.x = 54
    val.text = "%.2f" % s.value
    s.value_changed.connect(func(x: float):
        Settings.set_val(key, x)
        val.text = "%.2f" % x)
    h.add_child(s)
    h.add_child(val)
    _row(vb, label, h)

func _check(vb: Control, label: String, key: String) -> void:
    var c := CheckBox.new()
    c.button_pressed = bool(Settings.v[key])
    c.toggled.connect(func(t: bool): Settings.set_val(key, t))
    _row(vb, label, c)

func _choice(vb: Control, label: String, key: String, items: Array, vals: Array = []) -> void:
    var o := OptionButton.new()
    for it in items:
        o.add_item(it)
    o.selected = vals.find(Settings.v[key]) if not vals.is_empty() else int(Settings.v[key])
    o.item_selected.connect(func(i: int): Settings.set_val(key, vals[i] if not vals.is_empty() else i))
    _row(vb, label, o)

func _color(vb: Control, label: String, key: String) -> void:
    var p := ColorPickerButton.new()
    p.color = Settings.v[key]
    p.custom_minimum_size = Vector2(120, 30)
    p.color_changed.connect(func(c: Color): Settings.set_val(key, c))
    _row(vb, label, p)

func _tab_game() -> void:
    var vb := _page("Jeu")
    var le := LineEdit.new()
    le.text = str(Settings.v.nickname)
    le.max_length = 16
    le.text_changed.connect(func(t: String): Settings.set_val("nickname", t))
    _row(vb, "Pseudo", le)
    _check(vb, "Afficher les FPS", "show_fps")
    var sp := SpinBox.new()
    sp.min_value = 1024; sp.max_value = 65535
    sp.value = float(Settings.v.port)
    sp.value_changed.connect(func(x: float): Settings.set_val("port", int(x)))
    _row(vb, "Port réseau (hébergement)", sp)

func _tab_input() -> void:
    var vb := _page("Souris / Clavier")
    _slider(vb, "Sensibilité (unités CS)", "sens", 0.1, 10.0, 0.05)
    _check(vb, "Inverser l'axe vertical", "invert_y")
    _slider(vb, "Champ de vision (FOV)", "fov", 70.0, 110.0, 1.0)
    var l := Label.new()
    l.text = "Touches (positions physiques : ZQSD sur AZERTY) - clique puis appuie sur une touche"
    vb.add_child(l)
    for a in Settings.KEY_NAMES:
        var b := Button.new()
        b.text = Settings.key_label(a)
        b.pressed.connect(func():
            _wait = a
            b.text = "Appuie sur une touche...")
        _key_btns[a] = b
        _row(vb, Settings.KEY_NAMES[a], b)

func _input(e: InputEvent) -> void:
    if _wait == "":
        return
    if e is InputEventKey and e.pressed:
        if e.physical_keycode != KEY_ESCAPE:
            Settings.keys[_wait] = e.physical_keycode
            Settings.apply_keys()
        _key_btns[_wait].text = Settings.key_label(_wait)
        _wait = ""
        get_viewport().set_input_as_handled()

func _tab_cross() -> void:
    var vb := _page("Viseur")
    var box := PanelContainer.new()
    box.custom_minimum_size = Vector2(0, 150)
    var cr := Crosshair.new()
    cr.preview = true
    cr.custom_minimum_size = Vector2(0, 150)
    box.add_child(cr)
    vb.add_child(box)
    _choice(vb, "Style", "ch_style", ["Croix", "Croix en T", "Cercle", "Point"])
    _color(vb, "Couleur", "ch_color")
    _slider(vb, "Taille", "ch_size", 1.0, 30.0, 0.5)
    _slider(vb, "Épaisseur", "ch_thick", 1.0, 8.0, 0.5)
    _slider(vb, "Écart central", "ch_gap", 0.0, 20.0, 0.5)
    _slider(vb, "Opacité", "ch_opacity", 0.1, 1.0, 0.05)
    _check(vb, "Contour noir", "ch_outline")
    _check(vb, "Point central", "ch_dot")
    _check(vb, "Dynamique (s'écarte en bougeant / tirant)", "ch_dyn")
    var code := LineEdit.new()
    code.text = Settings.crosshair_code()
    code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var h := HBoxContainer.new()
    h.add_child(code)
    _btn(h, "Copier", func():
        code.text = Settings.crosshair_code()
        DisplayServer.clipboard_set(code.text))
    _btn(h, "Importer", func():
        if Settings.import_crosshair(code.text):
            _build(2))
    _row(vb, "Code de partage", h)

func _tab_video() -> void:
    var vb := _page("Vidéo")
    _choice(vb, "Mode d'affichage", "mode", ["Fenêtré", "Plein écran", "Plein écran sans bordure"])
    _choice(vb, "Résolution (mode fenêtré)", "res", ["1280x720", "1600x900", "1920x1080", "2560x1440"])
    _check(vb, "Synchronisation verticale (VSync)", "vsync")
    _choice(vb, "Limite de FPS", "fps_max", ["Illimité", "60", "120", "144", "240"], [0, 60, 120, 144, 240])
    _slider(vb, "Luminosité", "brightness", 0.6, 1.6, 0.05)

func _tab_quality() -> void:
    var vb := _page("Qualité")
    var o := OptionButton.new()
    for it in ["Bas", "Moyen", "Élevé", "Ultra"]:
        o.add_item(it)
    o.selected = int(Settings.v.preset)
    o.item_selected.connect(func(i: int):
        Settings.apply_preset(i)
        _build(4))
    _row(vb, "Préréglage", o)
    _choice(vb, "Ombres", "shadows", ["Désactivées", "Basses", "Moyennes", "Hautes"])
    _choice(vb, "Anti-crénelage (MSAA)", "msaa", ["Désactivé", "2x", "4x", "8x"])
    _slider(vb, "Échelle de rendu 3D", "scale3d", 0.5, 1.0, 0.05)
    _check(vb, "Occlusion ambiante (SSAO)", "ssao")
    _check(vb, "Lueur (Glow)", "glow")
    _check(vb, "Brume de poussière", "fog")

func _tab_audio() -> void:
    var vb := _page("Audio")
    _slider(vb, "Volume général", "vol_master", 0.0, 1.0, 0.01)
    _slider(vb, "Effets (tirs)", "vol_fx", 0.0, 1.0, 0.01)
    _slider(vb, "Bruits de pas", "vol_steps", 0.0, 1.0, 0.01)
    _slider(vb, "Musique", "vol_music", 0.0, 1.0, 0.01)
    _slider(vb, "Ambiance", "vol_amb", 0.0, 1.0, 0.01)
    _check(vb, "Couper le son si la fenêtre est inactive", "mute_unfocus")

func _tab_hud() -> void:
    var vb := _page("HUD")
    _slider(vb, "Taille du HUD", "hud_scale", 0.7, 1.5, 0.05)
    _slider(vb, "Taille du radar", "radar_scale", 0.7, 1.5, 0.05)
