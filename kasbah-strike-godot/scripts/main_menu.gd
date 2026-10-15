extends Control
## Menu principal : solo, heberger, rejoindre, amis, options, quitter.
var pages := {}
var status: Label
var _joining := false

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var bg := ColorRect.new()
    bg.color = Color(0.15, 0.12, 0.09)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var band := ColorRect.new()
    band.color = Color(0.80, 0.68, 0.45, 0.12)
    band.set_anchors_preset(Control.PRESET_FULL_RECT)
    band.anchor_top = 0.62
    add_child(band)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    center.add_child(box)
    var title := Label.new()
    title.text = "KASBAH STRIKE"
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color(0.93, 0.78, 0.45))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    var sub := Label.new()
    sub.text = "FPS tactique multijoueur entre amis"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(sub)
    var holder := Control.new()
    holder.custom_minimum_size = Vector2(760, 440)
    box.add_child(holder)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(status)
    _home(holder)
    _join_page(holder)
    var fm := FriendsMenu.new()
    fm.join_requested.connect(_join)
    _page(holder, "friends", fm)
    var om := OptionsMenu.new()
    om.closed.connect(func(): _show("home"))
    _page(holder, "options", om)
    _show("home")
    Net.connected_sig.connect(func():
        if _joining:
            get_tree().change_scene_to_file("res://scenes/lobby.tscn"))
    Net.connection_failed_sig.connect(func():
        _joining = false
        status.text = "Connexion impossible (code incorrect, hôte injoignable ou port fermé).")

func _page(holder: Control, key: String, node: Control) -> void:
    var c := CenterContainer.new()
    c.set_anchors_preset(Control.PRESET_FULL_RECT)
    c.add_child(node)
    holder.add_child(c)
    pages[key] = c

func _btn(parent: Node, text: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(340, 46)
    b.pressed.connect(cb)
    parent.add_child(b)

func _home(holder: Control) -> void:
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 10)
    var le := LineEdit.new()
    le.placeholder_text = "Ton pseudo"
    le.text = str(Settings.v.nickname)
    le.max_length = 16
    le.text_changed.connect(func(t: String): Settings.set_val("nickname", t))
    le.text_submitted.connect(func(_t): Settings.save())
    vb.add_child(le)
    _btn(vb, "S'entraîner en solo", func():
        Settings.save(); Net.solo()
        get_tree().change_scene_to_file("res://scenes/game.tscn"))
    _btn(vb, "Héberger une partie", func():
        Settings.save()
        var e := Net.host(int(Settings.v.port))
        if e == OK:
            get_tree().change_scene_to_file("res://scenes/lobby.tscn")
        else:
            status.text = "Impossible d'héberger (port déjà utilisé ?). Erreur %d" % e)
    _btn(vb, "Rejoindre une partie", func(): _show("join"))
    _btn(vb, "Amis", func(): _show("friends"))
    _btn(vb, "Options", func(): _show("options"))
    _btn(vb, "Quitter", func(): get_tree().quit())
    _page(holder, "home", vb)

func _join_page(holder: Control) -> void:
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 10)
    var l := Label.new()
    l.text = "Code de salon (ou adresse IP:port) donné par ton ami"
    vb.add_child(l)
    var le := LineEdit.new()
    le.placeholder_text = "K7P2X-93KQ4"
    le.custom_minimum_size.x = 340
    vb.add_child(le)
    _btn(vb, "Rejoindre", func(): _join(le.text))
    _btn(vb, "Retour", func(): _show("home"))
    _page(holder, "join", vb)

func _join(code: String) -> void:
    Settings.save()
    var e := Net.join(code)
    if e == OK:
        _joining = true
        status.text = "Connexion en cours..."
    else:
        status.text = "Code invalide."

func _show(k: String) -> void:
    for p in pages:
        pages[p].visible = p == k
    status.text = ""
