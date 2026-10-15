class_name Hud extends CanvasLayer
## HUD : vie, munitions, viseur, radar, chrono/score, killfeed, zone, tableau des scores, degats.
var player
var game
var crosshair: Crosshair
var root: Control
var hp_l: Label
var ammo_l: Label
var timer_l: Label
var zone_l: Label
var dead_l: Label
var hit_l: Label
var fps_l: Label
var feed: VBoxContainer
var dmg: ColorRect
var board: PanelContainer
var board_box: VBoxContainer
var radar: RadarView
var _hit_t := 0.0
var _board_t := 0.0

class RadarView extends Control:
	var hud
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		if hud == null or hud.player == null or hud.game == null:
			return
		var p = hud.player
		var k := size.x / 90.0
		var pp := Vector2(p.global_position.x, p.global_position.z)
		draw_set_transform(size / 2.0, p.rotation.y, Vector2.ONE)
		for r in hud.game.map.wall_rects:
			draw_rect(Rect2((r.position - pp) * k, r.size * k), Color(0.55, 0.47, 0.28, 0.9))
		for o in hud.game.players.get_children():
			if o != p and o.team == p.team and not o.dead:
				draw_circle((Vector2(o.global_position.x, o.global_position.z) - pp) * k, 4.0, Color(0.3, 0.7, 1.0))
		draw_set_transform(size / 2.0, 0.0, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(5, 5), Vector2(-5, 5)]), Color(0.3, 1.0, 0.5))

func _label(sz: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", int(sz * float(Settings.v.hud_scale)))
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	dmg = ColorRect.new()
	dmg.color = Color(0.8, 0, 0, 0)
	dmg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dmg)
	crosshair = Crosshair.new()
	root.add_child(crosshair)
	radar = RadarView.new()
	radar.hud = self
	radar.clip_contents = true
	radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(radar)
	hp_l = _label(44, Color(0.5, 1, 0.55))
	ammo_l = _label(44, Color(1, 0.9, 0.5))
	timer_l = _label(26)
	zone_l = _label(20, Color(1, 0.8, 0.45))
	dead_l = _label(30, Color(1, 0.4, 0.4))
	dead_l.visible = false
	hit_l = _label(30, Color(1, 0.3, 0.3))
	hit_l.text = "X"
	hit_l.visible = false
	fps_l = _label(16)
	feed = VBoxContainer.new()
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(feed)
	board = PanelContainer.new()
	board.visible = false
	board_box = VBoxContainer.new()
	board.add_child(board_box)
	root.add_child(board)
	game.kill_announced.connect(_add_feed)

func hurt() -> void:
	dmg.color.a = 0.45

func hitmarker() -> void:
	_hit_t = 0.15

func _add_feed(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	feed.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var vs := root.get_viewport_rect().size
	dmg.size = vs
	dmg.color.a = maxf(0.0, dmg.color.a - delta * 1.2)
	crosshair.size = vs
	crosshair.position = Vector2.ZERO
	hp_l.text = "+ %d" % player.health
	hp_l.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if player.health < 30 else Color(0.5, 1, 0.55))
	ammo_l.text = "%d / %d" % [player.ammo, player.reserve] + ("  (recharge)" if player.reload_t > 0.0 else "")
	hp_l.position = Vector2(30, vs.y - hp_l.size.y - 22)
	ammo_l.position = Vector2(vs.x - ammo_l.size.x - 30, vs.y - ammo_l.size.y - 22)
	var rs := 170.0 * float(Settings.v.radar_scale)
	radar.size = Vector2(rs, rs)
	radar.position = Vector2(20, 20)
	radar.queue_redraw()
	zone_l.text = game.map.zone_at(player.global_position)
	zone_l.position = Vector2(20, 20 + rs + 6)
	var t := int(game.elapsed)
	timer_l.text = "T %d    %02d:%02d    CT %d" % [game.team_kills[0], floori(t / 60.0), t % 60, game.team_kills[1]]
	timer_l.position = Vector2(vs.x / 2.0 - timer_l.size.x / 2.0, 14)
	feed.position = Vector2(vs.x - feed.size.x - 20, 20)
	dead_l.visible = player.dead
	dead_l.text = "Éliminé - réapparition dans %d s" % ceili(player.respawn_t)
	dead_l.position = Vector2(vs.x / 2.0 - dead_l.size.x / 2.0, vs.y * 0.62)
	_hit_t -= delta
	hit_l.visible = _hit_t > 0.0
	hit_l.position = vs / 2.0 + Vector2(14, 6)
	fps_l.visible = bool(Settings.v.show_fps)
	fps_l.text = "%d FPS" % Engine.get_frames_per_second()
	fps_l.position = Vector2(vs.x - 90, vs.y - 30 - ammo_l.size.y)
	var show_bar := Input.is_action_pressed("scoreboard")
	board.visible = show_bar
	if show:
		_board_t -= delta
		if _board_t <= 0.0:
			_board_t = 0.3
			_refresh_board()
		board.position = vs / 2.0 - board.size / 2.0

func _row(cells: Array, col: Color) -> void:
	var h := HBoxContainer.new()
	var w := [220, 80, 60, 60]
	for i in cells.size():
		var l := Label.new()
		l.text = str(cells[i])
		l.custom_minimum_size.x = w[i]
		l.add_theme_color_override("font_color", col)
		h.add_child(l)
	board_box.add_child(h)

func _refresh_board() -> void:
	for c in board_box.get_children():
		c.queue_free()
	var rows := []
	for id in game.stats:
		rows.append(game.stats[id])
	rows.sort_custom(func(a, b): return a.k > b.k)
	_row(["Joueur", "Équipe", "K", "D"], Color(1, 0.85, 0.4))
	for r in rows:
		_row([r.name, "T" if r.team == 0 else "CT", r.k, r.d], Color.WHITE)
