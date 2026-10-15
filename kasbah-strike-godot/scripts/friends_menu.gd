class_name FriendsMenu extends VBoxContainer
## Amis (sans serveur) : liste locale pseudo + dernier code de salon.
signal join_requested(code: String)
const PATH := "user://friends.json"
var friends: Array = []
var _list: VBoxContainer

func _ready() -> void:
    custom_minimum_size = Vector2(700, 0)
    add_theme_constant_override("separation", 10)
    if FileAccess.file_exists(PATH):
        var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
        if d is Array:
            friends = d
    var me := Label.new()
    me.text = "Ton identifiant : %s#%s" % [Settings.v.nickname, Settings.v.friend_id]
    add_child(me)
    var info := Label.new()
    info.text = "Pas de serveur central : colle ici le code de salon que ton ami te donne\n(il s'affiche dans le salon quand il héberge)."
    add_child(info)
    var h := HBoxContainer.new()
    var n := LineEdit.new(); n.placeholder_text = "Pseudo"; n.custom_minimum_size.x = 150
    var c := LineEdit.new(); c.placeholder_text = "Code de salon (ex. K7P2X-93KQ4)"; c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var b := Button.new(); b.text = "Ajouter"
    b.pressed.connect(func():
        if n.text.strip_edges() == "":
            return
        friends.append({"name": n.text.strip_edges(), "code": c.text.strip_edges()})
        n.text = ""; c.text = ""
        _save(); _refresh())
    h.add_child(n); h.add_child(c); h.add_child(b)
    add_child(h)
    _list = VBoxContainer.new()
    add_child(_list)
    _refresh()

func _save() -> void:
    var f := FileAccess.open(PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify(friends))

func _refresh() -> void:
    for ch in _list.get_children():
        ch.queue_free()
    for i in friends.size():
        var fr: Dictionary = friends[i]
        var h := HBoxContainer.new()
        var l := Label.new(); l.text = str(fr.name); l.custom_minimum_size.x = 150
        var e := LineEdit.new(); e.text = str(fr.code); e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        e.text_changed.connect(func(t: String):
            friends[i].code = t
            _save())
        var j := Button.new(); j.text = "Rejoindre"
        j.pressed.connect(func(): join_requested.emit(e.text))
        var r := Button.new(); r.text = "Retirer"
        r.pressed.connect(func():
            friends.remove_at(i)
            _save(); _refresh())
        h.add_child(l); h.add_child(e); h.add_child(j); h.add_child(r)
        _list.add_child(h)
