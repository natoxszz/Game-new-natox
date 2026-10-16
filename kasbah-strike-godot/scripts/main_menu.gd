extends Control
## Menu principal de Kasbah Strike. Le réseau existant reste inchangé.


var pages: Dictionary = {}
var status: Label
var _joining := false
var pending_mode := ""

const BG_DARK := Color(0.025, 0.032, 0.041, 0.94)
const PANEL := Color(0.055, 0.067, 0.078, 0.94)
const ACCENT := Color(0.88, 0.19, 0.10)
const TEXT_MAIN := Color(0.92, 0.91, 0.86)
const TEXT_MUTED := Color(0.67, 0.70, 0.71)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_backdrop()
	_build_interface()
	_build_pages()
	_show("home")

	Net.connected_sig.connect(func():
		if _joining:
			get_tree().change_scene_to_file("res://scenes/lobby.tscn"))
	Net.connection_failed_sig.connect(func():
		_joining = false
		status.text = "Connexion impossible. Vérifie le code, l'hôte et le port.")

func _build_backdrop() -> void:
	# Fond 2D fiable pour le menu : illustration désertique intégrée au projet.
	var background := TextureRect.new()
	background.name = "DesertBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://menu_background.svg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "AtmosphereOverlay"
	shade.color = Color(0.015, 0.022, 0.03, 0.18)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _build_interface() -> void:
	var sidebar := ColorRect.new()
	sidebar.name = "Sidebar"
	sidebar.color = BG_DARK
	sidebar.anchor_left = 0.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_right = 0.285
	sidebar.anchor_bottom = 1.0
	sidebar.offset_right = 1.0
	sidebar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sidebar)

	var accent_line := ColorRect.new()
	accent_line.color = ACCENT
	accent_line.anchor_left = 0.285
	accent_line.anchor_right = 0.285
	accent_line.anchor_bottom = 1.0
	accent_line.offset_left = -2.0
	accent_line.offset_right = 2.0
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent_line)

	var brand := VBoxContainer.new()
	brand.position = Vector2(34, 30)
	brand.size = Vector2(300, 112)
	brand.add_theme_constant_override("separation", 0)
	add_child(brand)

	var eyebrow := _label("K S  /  TACTICAL FPS", 13, ACCENT)
	brand.add_child(eyebrow)
	var title := _label("KASBAH", 39, TEXT_MAIN)
	title.add_theme_font_size_override("font_size", 39)
	brand.add_child(title)
	var title2 := _label("STRIKE", 39, TEXT_MAIN)
	title2.add_theme_font_size_override("font_size", 39)
	brand.add_child(title2)
	var edition := _label("OPÉRATIONS DANS LE DÉSERT", 10, TEXT_MUTED)
	brand.add_child(edition)

	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.13)
	divider.position = Vector2(34, 157)
	divider.size = Vector2(292, 1)
	add_child(divider)

	var nav := VBoxContainer.new()
	nav.name = "Navigation"
	nav.position = Vector2(25, 182)
	nav.size = Vector2(310, 340)
	nav.add_theme_constant_override("separation", 7)
	add_child(nav)

	_nav_button(nav, "01   JOUER", func(): _show("home"), true)
	_nav_button(nav, "02   AMIS", func(): _show("friends"))
	_nav_button(nav, "03   JOUER EN SOLO", func():
		pending_mode = "solo"
		_show("maps"))
	_nav_button(nav, "04   HÉBERGER UNE PARTIE", func():
		pending_mode = "host"
		_show("maps"))
	_nav_button(nav, "05   REJOINDRE UNE PARTIE", func(): _show("join"))
	_nav_button(nav, "06   OPTIONS", func(): _show("options"))

	var quit_button := _nav_button(nav, "07   QUITTER", func(): get_tree().quit())
	quit_button.modulate = Color(0.88, 0.66, 0.63)

	var profile_label := _label("IDENTITÉ OPÉRATEUR", 11, TEXT_MUTED)
	profile_label.position = Vector2(34, 555)
	profile_label.size = Vector2(290, 22)
	add_child(profile_label)

	var nickname := LineEdit.new()
	nickname.name = "Nickname"
	nickname.position = Vector2(30, 582)
	nickname.size = Vector2(294, 38)
	nickname.placeholder_text = "Ton pseudo"
	nickname.text = str(Settings.v.nickname)
	nickname.max_length = 16
	_style_input(nickname)
	nickname.text_changed.connect(func(value: String): Settings.set_val("nickname", value))
	nickname.text_submitted.connect(func(_value: String): Settings.save())
	add_child(nickname)

	var footer := _label("KASBAH STRIKE   /   BUILD 0.1", 10, TEXT_MUTED)
	footer.position = Vector2(34, 674)
	footer.size = Vector2(300, 20)
	add_child(footer)

	status = _label("", 13, Color(1.0, 0.72, 0.45))
	status.anchor_left = 0.31
	status.anchor_right = 0.97
	status.anchor_top = 0.91
	status.anchor_bottom = 0.98
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)

func _start_solo() -> void:
	pending_mode = "solo"
	_show("maps")

func _select_map(map_id: String) -> void:
	Settings.set_val("selected_map", map_id)
	Settings.save()
	if pending_mode == "solo":
		Net.solo()
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	elif pending_mode == "host":
		var err := Net.host(int(Settings.v.port))
		if err == OK:
			get_tree().change_scene_to_file("res://scenes/lobby.tscn")
		else:
			status.text = "Hébergement impossible. Erreur %d" % err
			_show("maps")

func _build_pages() -> void:
	var holder := Control.new()
	holder.name = "PageArea"
	holder.anchor_left = 0.30
	holder.anchor_top = 0.10
	holder.anchor_right = 0.98
	holder.anchor_bottom = 0.89
	add_child(holder)

	_home(holder)
	_map_page(holder)
	_join_page(holder)

	var friends := FriendsMenu.new()
	friends.join_requested.connect(_join)
	friends.closed.connect(func(): _show("home"))
	_page(holder, "friends", friends)

	var options := OptionsMenu.new()
	options.closed.connect(func(): _show("home"))
	_page(holder, "options", options)

func _home(holder: Control) -> void:
	# Page d'accueil volontairement dégagée : l'illustration reste visible.
	var page := Control.new()
	var hint := _label("SÉLECTIONNE UNE OPÉRATION", 13, TEXT_MAIN)
	hint.anchor_left = 0.54
	hint.anchor_top = 0.83
	hint.anchor_right = 0.96
	hint.anchor_bottom = 0.91
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page.add_child(hint)
	_page(holder, "home", page)

func _map_page(holder: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 340)
	_style_panel(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(_label("CONFIGURATION DE L’OPÉRATION", 12, ACCENT))
	vb.add_child(_label("CHOISIR UNE MAP", 28, TEXT_MAIN))
	var help := _label("Sélectionne le terrain avant de lancer la partie.", 14, TEXT_MUTED)
	vb.add_child(help)
	_action_button(vb, "KASBAH  /  MAP ORIGINALE", func(): _select_map("kasbah"), true)
	_action_button(vb, "DUST II  /  STYLE COUNTER-STRIKE", func(): _select_map("dust2"), false)
	_action_button(vb, "RETOUR AU MENU", func(): _show("home"), false)
	_page(holder, "maps", panel)

func _join_page(holder: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 240)
	_style_panel(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	vb.add_child(_label("ACCÈS OPÉRATION", 12, ACCENT))
	vb.add_child(_label("REJOINDRE UNE PARTIE", 25, TEXT_MAIN))
	var help := _label("Entre le code du salon ou une adresse IP:port.", 14, TEXT_MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(help)

	var code := LineEdit.new()
	code.placeholder_text = "Code du salon ou IP:port"
	_style_input(code)
	vb.add_child(code)
	_action_button(vb, "REJOINDRE", func(): _join(code.text), true)
	_action_button(vb, "RETOUR", func(): _show("home"), false)
	_page(holder, "join", panel)

func _page(holder: Control, key: String, node: Control) -> void:
	var center := CenterContainer.new()
	center.name = key.capitalize() + "Page"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(node)
	holder.add_child(center)
	pages[key] = center

func _nav_button(parent: Control, text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _stylebox(Color(0.08, 0.09, 0.10, 0.60), Color(1, 1, 1, 0.06)))
	button.add_theme_stylebox_override("hover", _stylebox(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.88), ACCENT))
	button.add_theme_stylebox_override("pressed", _stylebox(Color(0.55, 0.10, 0.07, 0.95), ACCENT))
	button.add_theme_stylebox_override("focus", _stylebox(Color(0.08, 0.09, 0.10, 0.75), ACCENT))
	if primary:
		button.add_theme_stylebox_override("normal", _stylebox(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.90), ACCENT))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _action_button(parent: Control, text: String, callback: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_stylebox_override("normal", _stylebox(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.90) if primary else Color(0.10, 0.12, 0.13, 0.92), ACCENT if primary else Color(1, 1, 1, 0.12)))
	button.add_theme_stylebox_override("hover", _stylebox(Color(0.96, 0.26, 0.14, 0.98), ACCENT))
	button.pressed.connect(callback)
	parent.add_child(button)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, Color(1, 1, 1, 0.16), 16))
	panel.add_theme_constant_override("margin_left", 26)
	panel.add_theme_constant_override("margin_right", 26)
	panel.add_theme_constant_override("margin_top", 24)
	panel.add_theme_constant_override("margin_bottom", 24)

func _style_input(input: LineEdit) -> void:
	input.add_theme_color_override("font_color", TEXT_MAIN)
	input.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	input.add_theme_stylebox_override("normal", _stylebox(Color(0.025, 0.035, 0.04, 0.95), Color(1, 1, 1, 0.16)))
	input.add_theme_stylebox_override("focus", _stylebox(Color(0.025, 0.035, 0.04, 0.98), ACCENT))

func _stylebox(fill: Color, border: Color, radius := 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _join(code: String) -> void:
	Settings.save()
	var err := Net.join(code)
	if err == OK:
		_joining = true
		status.text = "Connexion en cours..."
	else:
		status.text = "Code ou adresse invalide."

func _show(key: String) -> void:
	for page_key in pages:
		pages[page_key].visible = page_key == key
	status.text = ""
