extends Node2D

func _draw() -> void:
	var vp = get_viewport_rect().size
	_draw_sky(vp)
	_draw_stars(vp)
	_draw_moon(vp)
	_draw_mountains(vp)
	_draw_ground(vp)
	_draw_dojo_floor(vp)

func _draw_sky(vp: Vector2) -> void:
	var steps := 14
	var h := vp.y * 0.7 / steps
	for i in steps:
		var t := float(i) / steps
		var col := Color(0.03, 0.05, 0.16).lerp(Color(0.22, 0.36, 0.55), t)
		draw_rect(Rect2(0, i * h, vp.x, h + 1.0), col)
	# Horizon glow
	draw_rect(Rect2(0, vp.y * 0.6, vp.x, vp.y * 0.1), Color(0.42, 0.52, 0.65, 0.25))

func _draw_stars(vp: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 70:
		var x := rng.randf_range(5, vp.x - 5)
		var y := rng.randf_range(5, vp.y * 0.55)
		var r := rng.randf_range(0.7, 2.2)
		var a := rng.randf_range(0.35, 1.0)
		draw_circle(Vector2(x, y), r, Color(1, 1, 1, a))

func _draw_moon(vp: Vector2) -> void:
	var pos := Vector2(vp.x * 0.83, vp.y * 0.11)
	draw_circle(pos, 50, Color(0.9, 0.88, 0.65, 0.1))
	draw_circle(pos, 42, Color(0.92, 0.9, 0.7, 0.18))
	draw_circle(pos, 34, Color(0.96, 0.94, 0.8))
	# Craters
	draw_circle(pos + Vector2(-11, -9), 6.5, Color(0.88, 0.86, 0.7))
	draw_circle(pos + Vector2(9, 7),    4.5, Color(0.88, 0.86, 0.7))
	draw_circle(pos + Vector2(-4, 11),  3.5, Color(0.88, 0.86, 0.7))
	draw_circle(pos + Vector2(12, -12), 3.0, Color(0.88, 0.86, 0.7))

func _draw_mountains(vp: Vector2) -> void:
	# Far range — blue-grey
	var far := PackedVector2Array([
		Vector2(0, vp.y * 0.68),
		Vector2(0, vp.y * 0.5),
		Vector2(vp.x * 0.08, vp.y * 0.28),
		Vector2(vp.x * 0.18, vp.y * 0.43),
		Vector2(vp.x * 0.28, vp.y * 0.22),
		Vector2(vp.x * 0.38, vp.y * 0.38),
		Vector2(vp.x * 0.5,  vp.y * 0.17),
		Vector2(vp.x * 0.62, vp.y * 0.34),
		Vector2(vp.x * 0.73, vp.y * 0.2),
		Vector2(vp.x * 0.84, vp.y * 0.32),
		Vector2(vp.x,        vp.y * 0.42),
		Vector2(vp.x,        vp.y * 0.68),
	])
	draw_polygon(far, PackedColorArray([Color(0.17, 0.21, 0.34)]))

	# Snow caps
	var peaks := [
		[vp.x * 0.08, vp.y * 0.28,  vp.x * 0.04],
		[vp.x * 0.28, vp.y * 0.22,  vp.x * 0.05],
		[vp.x * 0.5,  vp.y * 0.17,  vp.x * 0.055],
		[vp.x * 0.73, vp.y * 0.2,   vp.x * 0.048],
	]
	for p in peaks:
		var pk := Vector2(p[0], p[1])
		var sz: float = p[2]
		draw_polygon(
			PackedVector2Array([pk, pk + Vector2(-sz, sz * 1.6), pk + Vector2(sz, sz * 1.6)]),
			PackedColorArray([Color(0.86, 0.89, 0.96, 0.85)])
		)

	# Near range — darker silhouette
	var near := PackedVector2Array([
		Vector2(0, vp.y * 0.68),
		Vector2(0, vp.y * 0.58),
		Vector2(vp.x * 0.12, vp.y * 0.42),
		Vector2(vp.x * 0.22, vp.y * 0.53),
		Vector2(vp.x * 0.35, vp.y * 0.37),
		Vector2(vp.x * 0.48, vp.y * 0.51),
		Vector2(vp.x * 0.6,  vp.y * 0.38),
		Vector2(vp.x * 0.74, vp.y * 0.54),
		Vector2(vp.x * 0.88, vp.y * 0.4),
		Vector2(vp.x,        vp.y * 0.53),
		Vector2(vp.x,        vp.y * 0.68),
	])
	draw_polygon(near, PackedColorArray([Color(0.09, 0.12, 0.19)]))

	# Pine tree silhouette row
	for i in 20:
		var tx := (float(i) / 19.0) * vp.x * 0.92 + vp.x * 0.04
		_draw_pine(tx, vp.y * 0.645, 0.55)

func _draw_pine(x: float, y: float, sc: float) -> void:
	var h := 30.0 * sc
	var w := 11.0 * sc
	draw_polygon(
		PackedVector2Array([Vector2(x, y - h), Vector2(x - w, y), Vector2(x + w, y)]),
		PackedColorArray([Color(0.05, 0.09, 0.14)])
	)

func _draw_ground(vp: Vector2) -> void:
	draw_rect(Rect2(0, vp.y * 0.68, vp.x, vp.y * 0.32), Color(0.14, 0.11, 0.07))
	draw_rect(Rect2(0, vp.y * 0.68, vp.x, 3), Color(0.07, 0.05, 0.03))

func _draw_dojo_floor(vp: Vector2) -> void:
	var fx := vp.x * 0.2
	var fw := vp.x * 0.6
	var fy := vp.y * 0.664
	var fh := vp.y * 0.042

	draw_rect(Rect2(fx, fy, fw, fh), Color(0.3, 0.21, 0.12))
	draw_rect(Rect2(fx, fy,          fw, 2.5), Color(0.45, 0.33, 0.2))
	draw_rect(Rect2(fx, fy + fh - 2, fw, 2),  Color(0.16, 0.11, 0.06))

	# Wood grain
	for i in 9:
		var lx := fx + i * (fw / 9.0)
		draw_line(Vector2(lx, fy), Vector2(lx, fy + fh), Color(0.2, 0.13, 0.07, 0.55), 1)

	# Subtle center line (fighting court mark)
	draw_line(
		Vector2(vp.x * 0.5, fy),
		Vector2(vp.x * 0.5, fy + fh),
		Color(0.38, 0.28, 0.15, 0.8), 2
	)
