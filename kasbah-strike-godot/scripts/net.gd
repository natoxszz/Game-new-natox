extends Node
## Reseau : heberger / rejoindre (ENet), UPnP, code de salon, liste des joueurs.
signal players_changed
signal connected_sig
signal connection_failed_sig
signal disconnected_sig

const ALPHA := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var players: Dictionary = {}   # id -> {"name": String}
var room_code := ""
var local_code := ""
var upnp_state := "..."
var is_solo := false
var _thread: Thread

func _ready() -> void:
    multiplayer.peer_disconnected.connect(_on_peer_left)
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(func(): connection_failed_sig.emit())
    multiplayer.server_disconnected.connect(_on_server_gone)

func solo() -> void:
    leave()
    is_solo = true
    players = {1: {"name": Settings.v.nickname}}

func host(port: int) -> Error:
    leave()
    var p := ENetMultiplayerPeer.new()
    var e := p.create_server(port, 7)
    if e != OK:
        return e
    multiplayer.multiplayer_peer = p
    players = {1: {"name": Settings.v.nickname}}
    room_code = ""
    upnp_state = "recherche..."
    var lip := _local_ip()
    local_code = encode(lip, port) if lip != "" else ""
    var http := HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, _c, _h, body: PackedByteArray):
        var ip := body.get_string_from_utf8().strip_edges()
        if ip.count(".") == 3:
            room_code = encode(ip, port)
        players_changed.emit()
        http.queue_free())
    http.request("https://api.ipify.org")
    _thread = Thread.new()
    _thread.start(_upnp.bind(port))
    players_changed.emit()
    return OK

func _upnp(port: int) -> void:
    var u := UPNP.new()
    if u.discover() == UPNP.UPNP_RESULT_SUCCESS and u.get_gateway() != null and u.get_gateway().is_valid_gateway():
        u.add_port_mapping(port, port, "KasbahStrike", "UDP")
        upnp_state = "OK (port ouvert)"
    else:
        upnp_state = "non disponible (voir README : VPN type ZeroTier)"

func join(text: String) -> Error:
    var t := text.strip_edges()
    var ip := ""
    var port := int(Settings.v.port)
    if ":" in t:
        var parts := t.split(":")
        ip = parts[0]
        port = int(parts[1])
    elif "." in t:
        ip = t
    else:
        var d := decode(t)
        if d.is_empty():
            return ERR_INVALID_PARAMETER
        ip = d.ip
        port = d.port
    leave()
    var p := ENetMultiplayerPeer.new()
    var e := p.create_client(ip, port)
    if e != OK:
        return e
    multiplayer.multiplayer_peer = p
    return OK

func leave() -> void:
    if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    players.clear()
    room_code = ""
    is_solo = false

func _local_ip() -> String:
    for a in IP.get_local_addresses():
        if a.count(".") == 3 and (a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172.")):
            return a
    return ""

func encode(ip: String, port: int) -> String:
    var p := ip.split(".")
    if p.size() != 4:
        return ""
    var n: int = (int(p[0]) << 40) | (int(p[1]) << 32) | (int(p[2]) << 24) | (int(p[3]) << 16) | port
    var s := ""
    for i in 10:
        s = ALPHA[n & 31] + s
        n >>= 5
    return s.substr(0, 5) + "-" + s.substr(5)

func decode(code: String) -> Dictionary:
    var c := code.replace("-", "").strip_edges().to_upper()
    if c.length() != 10:
        return {}
    var n := 0
    for ch in c:
        var i := ALPHA.find(ch)
        if i < 0:
            return {}
        n = (n << 5) | i
    return {"ip": "%d.%d.%d.%d" % [(n >> 40) & 255, (n >> 32) & 255, (n >> 24) & 255, (n >> 16) & 255], "port": n & 65535}

func _on_connected() -> void:
    register.rpc_id(1, Settings.v.nickname)
    connected_sig.emit()

func _on_peer_left(id: int) -> void:
    if multiplayer.is_server():
        players.erase(id)
        sync_players.rpc(players)

func _on_server_gone() -> void:
    leave()
    disconnected_sig.emit()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

@rpc("any_peer", "reliable")
func register(pname: String) -> void:
    if not multiplayer.is_server():
        return
    players[multiplayer.get_remote_sender_id()] = {"name": pname}
    sync_players.rpc(players)

@rpc("authority", "call_local", "reliable")
func sync_players(d: Dictionary) -> void:
    players = d
    players_changed.emit()

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
    get_tree().change_scene_to_file("res://scenes/game.tscn")
