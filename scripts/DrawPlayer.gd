extends Node2D

# 0 = idle, 1 = full punch — tweened by punch_anim()
var punch_extend: float = 0.0:
	set(v):
		punch_extend = v
		queue_redraw()

func punch_anim() -> void:
	var tw := create_tween()
	tw.tween_property(self, "punch_extend", 1.0, 0.07)
	tw.tween_property(self, "punch_extend", 0.0, 0.13)

func _draw() -> void:
	var skin  := Color(0.94, 0.80, 0.64)
	var gi    := Color(0.94, 0.94, 0.98)
	var gi_s  := Color(0.78, 0.78, 0.82)   # shadow side of gi
	var belt  := Color(0.04, 0.04, 0.06)
	var pants := Color(0.78, 0.78, 0.84)
	var hair  := Color(0.1, 0.07, 0.03)
	var shoe  := Color(0.1, 0.08, 0.06)

	# Ground shadow
	_ellipse(Vector2(0, 6), 34, 7, Color(0, 0, 0, 0.28))

	# ── Legs ───────────────────────────────────────────────────────────────────
	# Left leg (slightly back — stance)
	draw_polygon(_trapezoid(Vector2(-10, -20), 8, 6, 30), PackedColorArray([pants]))
	draw_rect(Rect2(-12, 7, 14, 9), shoe)  # left shoe

	# Right leg (front)
	draw_polygon(_trapezoid(Vector2(6, -20), 8, 6, 30), PackedColorArray([pants]))
	draw_rect(Rect2(4, 7, 14, 9), shoe)   # right shoe

	# ── Body (gi torso) ────────────────────────────────────────────────────────
	draw_polygon(
		PackedVector2Array([
			Vector2(-16, -62), Vector2(16, -62),
			Vector2(12, -18),  Vector2(-12, -18),
		]),
		PackedColorArray([gi])
	)
	# Shadow side (right)
	draw_polygon(
		PackedVector2Array([
			Vector2(0, -62), Vector2(16, -62),
			Vector2(12, -18), Vector2(0, -18),
		]),
		PackedColorArray([gi_s])
	)
	# Gi collar V
	draw_line(Vector2(0, -62), Vector2(-7, -40), Color(0.6, 0.6, 0.65), 2.5, true)
	draw_line(Vector2(0, -62), Vector2(7, -40),  Color(0.6, 0.6, 0.65), 2.5, true)

	# Belt
	draw_rect(Rect2(-15, -30, 30, 8), belt)
	# Belt knot (small square in center)
	draw_rect(Rect2(-4, -31, 8, 10), Color(0.08, 0.08, 0.1))

	# ── Left arm (guard — bent upward) ─────────────────────────────────────────
	draw_line(Vector2(-14, -54), Vector2(-26, -46), skin, 9, true)
	draw_line(Vector2(-26, -46), Vector2(-22, -32), skin, 8, true)
	draw_circle(Vector2(-22, -32), 7, skin)  # fist guard

	# ── Right arm (punch!) ─────────────────────────────────────────────────────
	var ext := 20.0 + punch_extend * 34.0
	draw_line(Vector2(14, -54), Vector2(14 + ext, -52), skin, 9, true)
	# Fist
	draw_rect(Rect2(14 + ext - 2, -57, 12, 10), skin)
	draw_rect(Rect2(14 + ext,     -59, 10,  4), skin)   # knuckle top
	# Energy effect when punching
	if punch_extend > 0.5:
		var alpha := (punch_extend - 0.5) * 2.0
		draw_circle(Vector2(14 + ext + 8, -52), 14 * alpha, Color(1, 0.85, 0.3, 0.35 * alpha))
		draw_circle(Vector2(14 + ext + 8, -52), 8  * alpha, Color(1, 0.95, 0.6, 0.5  * alpha))

	# ── Head ───────────────────────────────────────────────────────────────────
	draw_circle(Vector2(0, -76), 19, skin)

	# Hair back
	draw_arc(Vector2(0, -76), 19, PI * 0.85, PI * 2.15, 24, hair, 7, true)
	# Top knot
	draw_circle(Vector2(2, -92), 7, hair)
	draw_line(Vector2(2, -86), Vector2(2, -92), hair, 5, true)

	# Face details
	# Eyes (determined look)
	draw_line(Vector2(-9, -77), Vector2(-4, -78), Color(0.1, 0.08, 0.05), 3, true)
	draw_line(Vector2(4, -78),  Vector2(9, -77),  Color(0.1, 0.08, 0.05), 3, true)
	draw_circle(Vector2(-6, -76), 2, Color(0.1, 0.08, 0.05))
	draw_circle(Vector2(6,  -76), 2, Color(0.1, 0.08, 0.05))

	# Mouth (closed, focused)
	draw_line(Vector2(-5, -67), Vector2(5, -67), Color(0.7, 0.45, 0.38), 1.5, true)

	# Headband
	draw_rect(Rect2(-20, -82, 40, 6), Color(0.85, 0.1, 0.1, 0.9))

# ── Helpers ────────────────────────────────────────────────────────────────────

func _trapezoid(center: Vector2, top_w: float, bot_w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-top_w, 0),
		center + Vector2(top_w,  0),
		center + Vector2(bot_w,  h),
		center + Vector2(-bot_w, h),
	])

func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polygon(pts, PackedColorArray([col]))
