class_name Crosshair extends Control
## Viseur personnalisable (style, couleur, taille, ecart, contour...).
var spread := 0.0
var preview := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    Settings.changed.connect(queue_redraw)

func _process(_d: float) -> void:
    if preview or Settings.v.ch_dyn:
        queue_redraw()

func _bar(r: Rect2, c: Color, o: Color) -> void:
    if Settings.v.ch_outline:
        draw_rect(r.grow(1.0), o)
    draw_rect(r, c)

func _draw() -> void:
    var s := Settings.v
    var c: Color = s.ch_color
    c.a = float(s.ch_opacity)
    var o := Color(0, 0, 0, float(s.ch_opacity))
    var ctr := size / 2.0
    var gap := float(s.ch_gap) + (spread if s.ch_dyn else 0.0)
    var ln := float(s.ch_size)
    var th := float(s.ch_thick)
    var st := int(s.ch_style)
    if st == 0 or st == 1:
        _bar(Rect2(ctr.x - gap - ln, ctr.y - th / 2.0, ln, th), c, o)
        _bar(Rect2(ctr.x + gap, ctr.y - th / 2.0, ln, th), c, o)
        _bar(Rect2(ctr.x - th / 2.0, ctr.y + gap, th, ln), c, o)
        if st == 0:
            _bar(Rect2(ctr.x - th / 2.0, ctr.y - gap - ln, th, ln), c, o)
    elif st == 2:
        if s.ch_outline:
            draw_arc(ctr, gap + ln * 0.5, 0.0, TAU, 48, o, th + 2.0)
        draw_arc(ctr, gap + ln * 0.5, 0.0, TAU, 48, c, th)
    if st == 3 or s.ch_dot:
        _bar(Rect2(ctr.x - th / 2.0 - 0.5, ctr.y - th / 2.0 - 0.5, th + 1.0, th + 1.0), c, o)
