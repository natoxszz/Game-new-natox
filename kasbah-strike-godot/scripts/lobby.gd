extends Control
## Salon d'attente : liste des joueurs, code de salon, lancement par l'hote.
var list: VBoxContainer
var code_l: Label
var upnp_l: Label
var start_b: Button

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var bg := ColorRect.new()
    bg.color = Color(0.15, 0.12, 0.09)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var vb := VBoxContainer.new()
    vb.custom_minimum_size = Vector2(640, 0)
    vb.add_theme_constant_override("separation", 12)
    center.add_child(vb)
    var t := Label.new()
    t.text = "Salon"
    t.add_theme_font_size_override("font_size", 40)
    vb.add_child(t)
    code_l = Label.new()
    vb.add_child(code_l)
    upnp_l = Label.new()
    vb.add_child(upnp_l)
    var cp := Button.new()
    cp.text = "Copier le code d'invitation"
    cp.visible = multiplayer.is_server()
    cp.pressed.connect(func(): DisplayServer.clipboard_set(Net.room_code if Net.room_code != "" else Net.local_code))
    vb.add_child(cp)
    list = VBoxContainer.new()
    vb.add_child(list)
    start_b = Button.new()
    start_b.text = "Lancer la partie"
    start_b.custom_minimum_size.y = 44
    start_b.visible = multiplayer.is_server()
    start_b.pressed.connect(func(): Net.start_game.rpc())
    vb.add_child(start_b)
    var q := Button.new()
    q.text = "Quitter le salon"
    q.pressed.connect(func():
        Net.leave()
        get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    vb.add_child(q)
    Net.players_changed.connect(_refresh)
    var tm := Timer.new()
    tm.wait_time = 1.0
    tm.autostart = true
    tm.timeout.connect(_refresh)
    add_child(tm)
    _refresh()

func _refresh() -> void:
    if multiplayer.is_server():
        code_l.text = "Code (Internet) : %s     Code (réseau local) : %s" % [Net.room_code if Net.room_code != "" else "...", Net.local_code]
        upnp_l.text = "Ouverture automatique du port (UPnP) : " + Net.upnp_state
    else:
        code_l.text = "Connecté. En attente du lancement par l'hôte..."
        upnp_l.text = ""
    for c in list.get_children():
        c.queue_free()
    for id in Net.players:
        var l := Label.new()
        l.text = "- %s%s" % [Net.players[id].name, "  (hôte)" if id == 1 else ""]
        list.add_child(l)
