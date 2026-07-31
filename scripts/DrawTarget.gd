extends Node2D

var stage: int = -1

func _ready() -> void:
	GameState.stage_changed.connect(_on_stage_changed)
	stage = GameState.stage
	queue_redraw()

func _on_stage_changed(s: int) -> void:
	stage = s
	queue_redraw()

func _draw() -> void:
	match stage:
		0: _draw_air()
		1: _draw_hay()
		2: _draw_tree()
		3: _draw_stone()
		4: _draw_waterfall()
		5: _draw_sensei()

# ── Stage 0 — Air ─────────────────────────────────────────────────────────────
func _draw_air() -> void:
	# Swirling ki particles
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in 12:
		var angle := rng.randf_range(0, TAU)
		var dist  := rng.randf_range(20, 65)
		var pos   := Vector2(cos(angle) * dist, sin(angle) * dist - 40)
		var r     := rng.randf_range(3, 9)
		var a     := rng.randf_range(0.15, 0.45)
		draw_circle(pos, r, Color(0.7, 0.8, 1.0, a))
	# Center glow
	draw_circle(Vector2(0, -40), 22, Color(0.6, 0.75, 1.0, 0.12))
	draw_circle(Vector2(0, -40), 12, Color(0.7, 0.85, 1.0, 0.18))
	# Label-like "???" marker
	for i in 3:
		draw_circle(Vector2(-12 + i * 12, -72), 4, Color(0.7, 0.8, 1.0, 0.5))

# ── Stage 1 — Hay Roll ────────────────────────────────────────────────────────
func _draw_hay() -> void:
	var col_main := Color(0.88, 0.74, 0.18)
	var col_dark := Color(0.62, 0.52, 0.1)
	var col_rope := Color(0.45, 0.3, 0.1)

	# Shadow
	_ellipse(Vector2(0, 6), 38, 9, Color(0, 0, 0, 0.3))

	# Main cylinder body
	draw_rect(Rect2(-34, -96, 68, 100), col_main)

	# Top ellipse (cylinder cap)
	_ellipse(Vector2(0, -96), 34, 12, col_main.lightened(0.1))
	# Bottom ellipse
	_ellipse(Vector2(0, 4), 34, 12, col_dark)

	# Straw texture lines
	for i in 10:
		var y := -92.0 + i * 9.5
		draw_line(Vector2(-34, y), Vector2(34, y), col_dark, 1.5)

	# Straw end details on face
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 7:
		var sx := -28.0 + i * 9.0
		draw_line(Vector2(sx, -96), Vector2(sx + rng.randf_range(-3, 3), -104), col_dark, 1)

	# Rope bands
	for ry in [-75.0, -40.0, -10.0]:
		draw_rect(Rect2(-36, ry, 72, 7), col_rope)
		_ellipse(Vector2(0, ry + 3), 36, 7, col_rope)

	# Rope knot on right side
	draw_circle(Vector2(36, -40), 6, col_rope.darkened(0.2))

# ── Stage 2 — Tree ────────────────────────────────────────────────────────────
func _draw_tree() -> void:
	_ellipse(Vector2(0, 6), 30, 8, Color(0, 0, 0, 0.3))

	# Roots
	for i in 4:
		var angle := (-0.4 + i * 0.28) * PI
		var ep    := Vector2(cos(angle) * 32, sin(angle) * 12 + 4)
		draw_line(Vector2(0, 4), ep, Color(0.28, 0.17, 0.06), 4, true)

	# Trunk
	draw_polygon(
		PackedVector2Array([
			Vector2(-14, -112), Vector2(14, -112),
			Vector2(18, 4),     Vector2(-18, 4),
		]),
		PackedColorArray([Color(0.36, 0.22, 0.08)])
	)
	# Bark detail lines
	for i in 5:
		var by := -100.0 + i * 22.0
		draw_line(Vector2(-14, by), Vector2(-8, by + 10), Color(0.25, 0.15, 0.05), 1.5)
		draw_line(Vector2(5,  by), Vector2(12, by + 8),  Color(0.25, 0.15, 0.05), 1.5)

	# Canopy layers (bottom to top, each smaller and lighter)
	var layers := [
		[Vector2(0, -120), 52.0, 38.0, Color(0.07, 0.4,  0.1)],
		[Vector2(0, -152), 42.0, 30.0, Color(0.09, 0.48, 0.12)],
		[Vector2(0, -182), 32.0, 24.0, Color(0.11, 0.54, 0.15)],
		[Vector2(0, -208), 22.0, 18.0, Color(0.13, 0.58, 0.18)],
	]
	for l in layers:
		var center: Vector2 = l[0]
		var rx: float       = l[1]
		var ry: float       = l[2]
		var col: Color      = l[3]
		_ellipse(center, rx, ry, col)
		# Light highlight on top
		_ellipse(center + Vector2(0, -ry * 0.3), rx * 0.5, ry * 0.3, col.lightened(0.15))

# ── Stage 3 — Stone ───────────────────────────────────────────────────────────
func _draw_stone() -> void:
	_ellipse(Vector2(0, 6), 50, 10, Color(0, 0, 0, 0.35))

	# Boulder body (irregular polygon)
	var body := PackedVector2Array([
		Vector2(-44, 0),
		Vector2(-50, -28),
		Vector2(-36, -62),
		Vector2(-16, -88),
		Vector2(10,  -96),
		Vector2(36,  -80),
		Vector2(48,  -50),
		Vector2(44,  -18),
		Vector2(28,   4),
		Vector2(-10,  6),
	])
	draw_polygon(body, PackedColorArray([Color(0.44, 0.43, 0.48)]))

	# Top highlight
	var highlight := PackedVector2Array([
		Vector2(-20, -60),
		Vector2(-10, -90),
		Vector2(10,  -96),
		Vector2(24,  -80),
		Vector2(14,  -58),
		Vector2(-8,  -52),
	])
	draw_polygon(highlight, PackedColorArray([Color(0.56, 0.55, 0.6)]))

	# Cracks
	draw_line(Vector2(-5,  -90), Vector2(-18, -50), Color(0.22, 0.22, 0.26), 2.5, true)
	draw_line(Vector2(-18, -50), Vector2(-8,  -22), Color(0.22, 0.22, 0.26), 2,   true)
	draw_line(Vector2(12,  -70), Vector2(22,  -38), Color(0.22, 0.22, 0.26), 2,   true)
	draw_line(Vector2(-18, -50), Vector2(5,   -44), Color(0.22, 0.22, 0.26), 1.5, true)

	# Moss patches
	draw_circle(Vector2(-30, -20), 8, Color(0.18, 0.38, 0.14, 0.7))
	draw_circle(Vector2(20, -12),  6, Color(0.15, 0.35, 0.12, 0.7))

# ── Stage 4 — Waterfall ───────────────────────────────────────────────────────
func _draw_waterfall() -> void:
	# Cliff / rock top
	var cliff := PackedVector2Array([
		Vector2(-58, -162),
		Vector2(-70, -145),
		Vector2(-66, -128),
		Vector2(66,  -128),
		Vector2(70,  -145),
		Vector2(58,  -162),
		Vector2(40,  -172),
		Vector2(-40, -172),
	])
	draw_polygon(cliff, PackedColorArray([Color(0.35, 0.32, 0.28)]))
	draw_polygon(cliff, PackedColorArray([Color(0.42, 0.38, 0.33)]))  # top lighter
	var cliff_top := PackedVector2Array([
		Vector2(-58, -162), Vector2(58, -162),
		Vector2(40,  -172), Vector2(-40, -172),
	])
	draw_polygon(cliff_top, PackedColorArray([Color(0.48, 0.44, 0.38)]))

	# Water streams
	var stream_cols := [
		Color(0.3,  0.6,  0.9,  0.9),
		Color(0.45, 0.72, 0.98, 0.85),
		Color(0.5,  0.78, 1.0,  0.8),
		Color(0.38, 0.65, 0.92, 0.88),
	]
	for i in 4:
		var sx := -38.0 + i * 26.0
		draw_rect(Rect2(sx, -128, 20, 140), stream_cols[i])
		# White highlight stripe
		draw_rect(Rect2(sx + 2, -128, 4, 140), Color(0.8, 0.9, 1.0, 0.5))

	# Pool / splash at bottom
	_ellipse(Vector2(0, 14), 60, 14, Color(0.3, 0.55, 0.85, 0.6))
	_ellipse(Vector2(0, 12), 48, 10, Color(0.55, 0.78, 1.0, 0.4))

	# Mist particles
	for i in 5:
		var mx := -40.0 + i * 20.0
		draw_circle(Vector2(mx, 5), 12, Color(0.8, 0.9, 1.0, 0.2))
	draw_circle(Vector2(0, 2), 30, Color(0.85, 0.93, 1.0, 0.15))

# ── Stage 5 — Sensei ──────────────────────────────────────────────────────────
func _draw_sensei() -> void:
	var skin  := Color(0.86, 0.72, 0.56)
	var gi    := Color(0.75, 0.12, 0.12)   # red gi
	var gi_s  := Color(0.55, 0.08, 0.08)
	var belt  := Color(0.04, 0.04, 0.05)   # black belt
	var pants := Color(0.12, 0.12, 0.16)
	var hair  := Color(0.88, 0.88, 0.9)    # white/grey hair (old master)
	var shoe  := Color(0.08, 0.06, 0.04)

	_ellipse(Vector2(0, 6), 34, 8, Color(0, 0, 0, 0.3))

	# Legs — wider fighting stance
	draw_polygon(_trapezoid(Vector2(-12, -22), 9, 7, 32), PackedColorArray([pants]))
	draw_rect(Rect2(-14, 7, 15, 9), shoe)
	draw_polygon(_trapezoid(Vector2(12, -22),  9, 7, 32), PackedColorArray([pants]))
	draw_rect(Rect2(6, 7, 15, 9), shoe)

	# Body — red gi
	draw_polygon(
		PackedVector2Array([
			Vector2(-18, -64), Vector2(18, -64),
			Vector2(14, -20),  Vector2(-14, -20),
		]),
		PackedColorArray([gi])
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(0, -64), Vector2(18, -64),
			Vector2(14, -20), Vector2(0, -20),
		]),
		PackedColorArray([gi_s])
	)
	# Gi collar
	draw_line(Vector2(0, -64), Vector2(-8, -40), Color(0.55, 0.08, 0.08), 2.5)
	draw_line(Vector2(0, -64), Vector2(8,  -40), Color(0.55, 0.08, 0.08), 2.5)

	# Belt
	draw_rect(Rect2(-16, -30, 32, 8), belt)
	draw_rect(Rect2(-5, -31, 10, 10), Color(0.06, 0.06, 0.08))

	# Left arm — raised block
	draw_line(Vector2(-16, -56), Vector2(-36, -44), skin, 9, true)
	draw_line(Vector2(-36, -44), Vector2(-30, -26), skin, 8, true)
	draw_circle(Vector2(-30, -26), 7, skin)

	# Right arm — counter-punch stance
	draw_line(Vector2(16, -56), Vector2(34, -48), skin, 9, true)
	draw_circle(Vector2(34, -48), 7, skin)

	# Head
	draw_circle(Vector2(0, -78), 20, skin)

	# White beard
	draw_polygon(
		PackedVector2Array([
			Vector2(-10, -64), Vector2(10, -64),
			Vector2(14,  -52), Vector2(0,  -48), Vector2(-14, -52),
		]),
		PackedColorArray([Color(0.92, 0.92, 0.94)])
	)

	# White hair / top knot
	draw_arc(Vector2(0, -78), 20, PI * 0.75, PI * 2.25, 24, hair, 6, true)
	draw_circle(Vector2(0, -96), 6, hair)
	draw_line(Vector2(0, -90), Vector2(0, -96), hair, 4, true)

	# Eyes — sharp, evaluating
	draw_line(Vector2(-9, -80), Vector2(-4, -80), Color(0.06, 0.05, 0.04), 3, true)
	draw_line(Vector2(4,  -80), Vector2(9,  -80), Color(0.06, 0.05, 0.04), 3, true)
	draw_circle(Vector2(-6, -79), 2, Color(0.06, 0.05, 0.04))
	draw_circle(Vector2(6,  -79), 2, Color(0.06, 0.05, 0.04))

	# Eyebrows — stern
	draw_line(Vector2(-10, -84), Vector2(-3, -82), Color(0.3, 0.28, 0.26), 2, true)
	draw_line(Vector2(3,   -82), Vector2(10, -84), Color(0.3, 0.28, 0.26), 2, true)

	# Mouth — serious
	draw_line(Vector2(-6, -69), Vector2(6, -69), Color(0.65, 0.45, 0.38), 1.5)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polygon(pts, PackedColorArray([col]))

func _trapezoid(center: Vector2, tw: float, bw: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-tw, 0), center + Vector2(tw, 0),
		center + Vector2(bw, h),  center + Vector2(-bw, h),
	])
