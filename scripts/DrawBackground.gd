extends Node2D

var _time:  float = 0.0
var _stage: int   = 0

var _particles_embers:    GPUParticles2D
var _particles_rain:      GPUParticles2D
var _particles_fireflies: GPUParticles2D

func _ready() -> void:
	GameState.stage_changed.connect(_on_stage_changed)
	_stage = GameState.stage
	var vp := get_viewport_rect().size
	_particles_embers    = _make_embers(vp)
	_particles_rain      = _make_rain(vp)
	_particles_fireflies = _make_fireflies(vp)
	add_child(_particles_embers)
	add_child(_particles_rain)
	add_child(_particles_fireflies)
	_sync_particles()

func _on_stage_changed(s: int) -> void:
	_stage = s
	_sync_particles()

func _sync_particles() -> void:
	_particles_embers.emitting    = (_stage == 5)
	_particles_rain.emitting      = (_stage == 7)
	_particles_fireflies.emitting = (_stage != 5 and _stage != 7)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var vp = get_viewport_rect().size
	match _stage:
		5:  _draw_volcano_bg(vp)
		7:  _draw_storm_bg(vp)
		_:  _draw_night_dojo(vp)

# ── Night dojo (stages 0–4, 6, 8–13) ─────────────────────────────────────────

func _draw_night_dojo(vp: Vector2) -> void:
	_draw_sky(vp)
	_draw_stars(vp)
	_draw_moon(vp)
	_draw_clouds_night(vp)
	_draw_mountains(vp)
	_draw_mist(vp)
	_draw_ground(vp)
	_draw_dojo_floor(vp)

func _draw_clouds_night(vp: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 8:
		var base_x := rng.randf_range(0.0, 1.1)
		var cy     := rng.randf_range(0.07, 0.40) * vp.y
		var drift  := rng.randf_range(0.004, 0.011)
		var w      := rng.randf_range(120.0, 240.0)
		var h      := rng.randf_range(24.0, 52.0)
		var x      := fmod(base_x * vp.x + _time * drift * vp.x, vp.x * 1.3) - vp.x * 0.15

		# Each cloud is 7 overlapping ellipses — fluffy cumulus look
		var pr := RandomNumberGenerator.new()
		pr.seed = i * 37 + 11
		for j in 7:
			var ex := x  + pr.randf_range(-w * 0.44, w * 0.44)
			var ey := cy + pr.randf_range(-h * 0.28, h * 0.28)
			var ew := pr.randf_range(w * 0.22, w * 0.52)
			var eh := pr.randf_range(h * 0.32, h * 0.68)
			var ea := pr.randf_range(0.05, 0.13)
			_ellipse(Vector2(ex, ey), ew, eh, Color(0.70, 0.76, 0.90, ea))

func _draw_mist(vp: Vector2) -> void:
	# Gentle ground mist at the base of the mountains
	var mist_y := vp.y * 0.62
	var mist_a := 0.06 + 0.02 * sin(_time * 0.25)
	for i in 3:
		var t := float(i) / 3.0
		draw_rect(
			Rect2(0, mist_y + t * vp.y * 0.06, vp.x, vp.y * 0.025),
			Color(0.55, 0.65, 0.82, mist_a * (1.0 - t * 0.6))
		)

# ── Volcano (stage 5) ─────────────────────────────────────────────────────────

func _draw_volcano_bg(vp: Vector2) -> void:
	# Sky — dark red gradient with ash-grey top
	var steps := 18
	var h := vp.y * 0.7 / steps
	for i in steps:
		var t := float(i) / steps
		var col := Color(0.08, 0.04, 0.04).lerp(Color(0.38, 0.14, 0.03), t)
		draw_rect(Rect2(0, i * h, vp.x, h + 1.0), col)

	# Ash cloud layer in upper sky
	var rng := RandomNumberGenerator.new()
	rng.seed = 313
	for i in 6:
		var bx  := rng.randf_range(0.0, 1.0) * vp.x
		var by  := rng.randf_range(0.05, 0.35) * vp.y
		var bw  := rng.randf_range(180.0, 320.0)
		var bh  := rng.randf_range(30.0, 70.0)
		var spd := rng.randf_range(0.003, 0.008)
		var x   := fmod(bx + _time * spd * vp.x, vp.x * 1.2) - vp.x * 0.1
		_ellipse(Vector2(x, by), bw, bh, Color(0.22, 0.14, 0.10, 0.18))

	# Horizon ember glow — pulses
	var glow_a := 0.28 + 0.10 * sin(_time * 0.8)
	draw_rect(Rect2(0, vp.y * 0.52, vp.x, vp.y * 0.18), Color(1.0, 0.28, 0.0, glow_a))
	draw_rect(Rect2(0, vp.y * 0.63, vp.x, vp.y * 0.05), Color(1.0, 0.55, 0.0, glow_a * 0.7))

	# Distant volcano silhouettes — three layered peaks
	draw_polygon(PackedVector2Array([
		Vector2(vp.x * 0.05, vp.y * 0.68), Vector2(vp.x * 0.18, vp.y * 0.30),
		Vector2(vp.x * 0.31, vp.y * 0.68),
	]), PackedColorArray([Color(0.10, 0.05, 0.03)]))
	draw_polygon(PackedVector2Array([
		Vector2(vp.x * 0.28, vp.y * 0.68), Vector2(vp.x * 0.42, vp.y * 0.18),
		Vector2(vp.x * 0.56, vp.y * 0.68),
	]), PackedColorArray([Color(0.07, 0.03, 0.02)]))
	draw_polygon(PackedVector2Array([
		Vector2(vp.x * 0.62, vp.y * 0.68), Vector2(vp.x * 0.74, vp.y * 0.26),
		Vector2(vp.x * 0.86, vp.y * 0.68),
	]), PackedColorArray([Color(0.09, 0.04, 0.02)]))

	# Lava glow at craters — each flickers independently
	for ci in [[0.18, 0.30, 2.1], [0.42, 0.18, 4.3], [0.74, 0.26, 3.7]]:
		var flicker := 0.55 + 0.45 * sin(_time * ci[2])
		var cp := Vector2(vp.x * ci[0], vp.y * ci[1])
		draw_circle(cp, 22 + flicker * 8, Color(1.0, 0.45, 0.0, 0.20 * flicker))
		draw_circle(cp, 12,               Color(1.0, 0.68, 0.1, 0.48 * flicker))
		draw_circle(cp,  5,               Color(1.0, 0.90, 0.5, 0.70 * flicker))

	# Lava river on the middle volcano
	var lava_pulse := 0.5 + 0.5 * sin(_time * 1.2)
	draw_polygon(PackedVector2Array([
		Vector2(vp.x * 0.40, vp.y * 0.30), Vector2(vp.x * 0.44, vp.y * 0.30),
		Vector2(vp.x * 0.47, vp.y * 0.55), Vector2(vp.x * 0.37, vp.y * 0.55),
	]), PackedColorArray([Color(1.0, 0.40, 0.0, 0.45 + 0.15 * lava_pulse)]))

	_draw_ground_volcano(vp)
	_draw_dojo_floor(vp)

func _draw_ground_volcano(vp: Vector2) -> void:
	draw_rect(Rect2(0, vp.y * 0.68, vp.x, vp.y * 0.32), Color(0.12, 0.06, 0.04))
	# Lava cracks in the ground
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 8:
		var lx1 := rng.randf_range(0.05, 0.95) * vp.x
		var ly1 := rng.randf_range(0.70, 0.85) * vp.y
		var lx2 := lx1 + rng.randf_range(-60, 60)
		var ly2 := ly1 + rng.randf_range(10, 35)
		var glow := 0.4 + 0.3 * sin(_time * 1.5 + float(i))
		draw_line(Vector2(lx1, ly1), Vector2(lx2, ly2), Color(1.0, 0.45, 0.0, glow * 0.7), 2)
		draw_line(Vector2(lx1, ly1), Vector2(lx2, ly2), Color(1.0, 0.80, 0.2, glow * 0.4), 1)

# ── Typhoon storm (stage 7) ───────────────────────────────────────────────────

func _draw_storm_bg(vp: Vector2) -> void:
	# Dark churning sky — two-layer gradient
	var steps := 18
	var h := vp.y * 0.7 / steps
	for i in steps:
		var t := float(i) / steps
		var col := Color(0.03, 0.04, 0.09).lerp(Color(0.12, 0.16, 0.26), t)
		draw_rect(Rect2(0, i * h, vp.x, h + 1.0), col)

	# Storm clouds — dark swirling masses
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	for i in 9:
		var bx  := rng.randf_range(0.0, 1.1) * vp.x
		var by  := rng.randf_range(0.04, 0.48) * vp.y
		var bw  := rng.randf_range(160.0, 340.0)
		var bh  := rng.randf_range(35.0, 80.0)
		var spd := rng.randf_range(-0.010, -0.004)  # storm clouds move right-to-left
		var x   := fmod(bx + _time * spd * vp.x + vp.x * 1.2, vp.x * 1.3) - vp.x * 0.15
		var ca  := rng.randf_range(0.12, 0.28)
		_ellipse(Vector2(x, by), bw, bh, Color(0.07, 0.09, 0.16, ca))

	# Lightning flash — rare, very brief spike
	var flash := maxf(0.0, sin(_time * 0.7) * sin(_time * 3.1) * sin(_time * 7.3))
	if flash > 0.85:
		var fa := (flash - 0.85) * 5.0
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.75, 0.82, 1.0, fa))
		# Bright bolt
		var bolt_x := vp.x * 0.45
		draw_line(Vector2(bolt_x, 0), Vector2(bolt_x - 18, vp.y * 0.35),
				  Color(0.9, 0.95, 1.0, fa * 1.5), 3)
		draw_line(Vector2(bolt_x - 18, vp.y * 0.35), Vector2(bolt_x + 8, vp.y * 0.55),
				  Color(0.9, 0.95, 1.0, fa * 1.5), 2)

	# Dark mountain silhouettes
	draw_polygon(PackedVector2Array([
		Vector2(0, vp.y * 0.68),         Vector2(0, vp.y * 0.48),
		Vector2(vp.x * 0.22, vp.y * 0.26), Vector2(vp.x * 0.38, vp.y * 0.44),
		Vector2(vp.x * 0.55, vp.y * 0.20), Vector2(vp.x * 0.72, vp.y * 0.40),
		Vector2(vp.x * 0.88, vp.y * 0.24), Vector2(vp.x, vp.y * 0.42),
		Vector2(vp.x, vp.y * 0.68),
	]), PackedColorArray([Color(0.05, 0.06, 0.11)]))

	# Ground mist driven by storm wind
	for i in 4:
		var t  := float(i) / 4.0
		var mx := fmod(_time * (0.04 + t * 0.02) * vp.x, vp.x * 1.5) - vp.x * 0.25
		draw_rect(Rect2(mx, vp.y * 0.62 + t * 18, vp.x, 16.0),
				  Color(0.40, 0.50, 0.72, 0.10 - t * 0.02))

	_draw_ground(vp)
	_draw_dojo_floor(vp)

# ── Shared draw helpers ────────────────────────────────────────────────────────

func _draw_sky(vp: Vector2) -> void:
	var steps := 18
	var h := vp.y * 0.7 / steps
	for i in steps:
		var t   := float(i) / steps
		var col := Color(0.02, 0.04, 0.14).lerp(Color(0.20, 0.34, 0.52), t)
		draw_rect(Rect2(0, i * h, vp.x, h + 1.0), col)
	var glow_a := 0.18 + 0.06 * sin(_time * 0.4)
	draw_rect(Rect2(0, vp.y * 0.60, vp.x, vp.y * 0.10), Color(0.42, 0.52, 0.65, glow_a))

func _draw_stars(vp: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 80:
		var x      := rng.randf_range(5, vp.x - 5)
		var y      := rng.randf_range(5, vp.y * 0.52)
		var r      := rng.randf_range(0.6, 2.4)
		var base_a := rng.randf_range(0.30, 1.0)
		var phase  := rng.randf_range(0.0, TAU)
		var speed  := rng.randf_range(0.4, 2.0)
		var a      := base_a * (0.55 + 0.45 * sin(_time * speed + phase))
		draw_circle(Vector2(x, y), r, Color(1.0, 1.0, 1.0, a))
		# Occasional bright star gets a tiny cross sparkle
		if base_a > 0.85:
			draw_line(Vector2(x - r * 2.5, y), Vector2(x + r * 2.5, y),
					  Color(1.0, 1.0, 1.0, a * 0.4), 0.5)
			draw_line(Vector2(x, y - r * 2.5), Vector2(x, y + r * 2.5),
					  Color(1.0, 1.0, 1.0, a * 0.4), 0.5)

func _draw_moon(vp: Vector2) -> void:
	var pos := Vector2(vp.x * 0.83, vp.y * 0.11)
	var halo_r := 50.0 + 2.5 * sin(_time * 0.6)
	var halo_a := 0.07 + 0.04 * sin(_time * 0.6)
	# Three halo rings
	draw_circle(pos, halo_r + 22, Color(0.88, 0.86, 0.62, halo_a * 0.30))
	draw_circle(pos, halo_r + 8,  Color(0.90, 0.88, 0.65, halo_a * 0.55))
	draw_circle(pos, halo_r,      Color(0.90, 0.88, 0.65, halo_a))
	draw_circle(pos, 42, Color(0.92, 0.90, 0.70, 0.18))
	draw_circle(pos, 34, Color(0.96, 0.94, 0.80))
	# Craters
	draw_circle(pos + Vector2(-11, -9),  6.5, Color(0.88, 0.86, 0.70))
	draw_circle(pos + Vector2(  9,  7),  4.5, Color(0.88, 0.86, 0.70))
	draw_circle(pos + Vector2( -4, 11),  3.5, Color(0.88, 0.86, 0.70))
	draw_circle(pos + Vector2( 12,-12),  3.0, Color(0.88, 0.86, 0.70))
	# Moon rim light
	draw_arc(pos, 34, -PI * 0.6, PI * 0.1, 20, Color(1.0, 0.98, 0.88, 0.55), 2.0)

func _draw_mountains(vp: Vector2) -> void:
	var mouse   := get_viewport().get_mouse_position()
	var mx      := (mouse.x / vp.x - 0.5) * 2.0
	var off_far  := mx * 8.0
	var off_near := mx * 18.0
	var off_pine := mx * 28.0

	# Far range
	var far := PackedVector2Array([
		Vector2(0            + off_far, vp.y * 0.68),
		Vector2(0            + off_far, vp.y * 0.50),
		Vector2(vp.x * 0.08 + off_far, vp.y * 0.28),
		Vector2(vp.x * 0.18 + off_far, vp.y * 0.43),
		Vector2(vp.x * 0.28 + off_far, vp.y * 0.22),
		Vector2(vp.x * 0.38 + off_far, vp.y * 0.38),
		Vector2(vp.x * 0.50 + off_far, vp.y * 0.17),
		Vector2(vp.x * 0.62 + off_far, vp.y * 0.34),
		Vector2(vp.x * 0.73 + off_far, vp.y * 0.20),
		Vector2(vp.x * 0.84 + off_far, vp.y * 0.32),
		Vector2(vp.x        + off_far, vp.y * 0.42),
		Vector2(vp.x        + off_far, vp.y * 0.68),
	])
	draw_polygon(far, PackedColorArray([Color(0.16, 0.20, 0.33)]))

	# Snow caps
	var peaks := [
		[vp.x * 0.08, vp.y * 0.28,  vp.x * 0.040],
		[vp.x * 0.28, vp.y * 0.22,  vp.x * 0.050],
		[vp.x * 0.50, vp.y * 0.17,  vp.x * 0.055],
		[vp.x * 0.73, vp.y * 0.20,  vp.x * 0.048],
	]
	for p in peaks:
		var pk := Vector2(p[0] + off_far, p[1])
		var sz: float = p[2]
		draw_polygon(
			PackedVector2Array([pk, pk + Vector2(-sz, sz * 1.6), pk + Vector2(sz, sz * 1.6)]),
			PackedColorArray([Color(0.86, 0.89, 0.96, 0.85)])
		)

	# Near range
	var near := PackedVector2Array([
		Vector2(0            + off_near, vp.y * 0.68),
		Vector2(0            + off_near, vp.y * 0.58),
		Vector2(vp.x * 0.12 + off_near, vp.y * 0.42),
		Vector2(vp.x * 0.22 + off_near, vp.y * 0.53),
		Vector2(vp.x * 0.35 + off_near, vp.y * 0.37),
		Vector2(vp.x * 0.48 + off_near, vp.y * 0.51),
		Vector2(vp.x * 0.60 + off_near, vp.y * 0.38),
		Vector2(vp.x * 0.74 + off_near, vp.y * 0.54),
		Vector2(vp.x * 0.88 + off_near, vp.y * 0.40),
		Vector2(vp.x        + off_near, vp.y * 0.53),
		Vector2(vp.x        + off_near, vp.y * 0.68),
	])
	draw_polygon(near, PackedColorArray([Color(0.08, 0.11, 0.18)]))

	# Rock texture — erosion lines on near range
	var drng := RandomNumberGenerator.new()
	drng.seed = 321
	for i in 18:
		var dx  := drng.randf_range(0.04, 0.96) * vp.x + off_near
		var dy  := drng.randf_range(0.40, 0.63) * vp.y
		var dlen := drng.randf_range(8.0, 28.0)
		var da  := drng.randf_range(0.12, 0.30)
		draw_line(Vector2(dx, dy), Vector2(dx - dlen * 0.35, dy + dlen),
				  Color(0.05, 0.06, 0.10, da), 1.2)

	# Pine tree silhouette row
	for i in 22:
		var tx := (float(i) / 21.0) * vp.x * 0.94 + vp.x * 0.03 + off_pine
		_draw_pine(tx, vp.y * 0.645, 0.55 + 0.12 * sin(float(i) * 0.7))

func _draw_pine(x: float, y: float, sc: float) -> void:
	var h := 30.0 * sc
	var w := 11.0 * sc
	# Main triangle
	draw_polygon(
		PackedVector2Array([Vector2(x, y - h), Vector2(x - w, y), Vector2(x + w, y)]),
		PackedColorArray([Color(0.05, 0.08, 0.13)])
	)
	# Lower skirt for a layered pine look
	draw_polygon(
		PackedVector2Array([
			Vector2(x, y - h * 0.55),
			Vector2(x - w * 1.2, y + h * 0.08),
			Vector2(x + w * 1.2, y + h * 0.08),
		]),
		PackedColorArray([Color(0.04, 0.07, 0.11)])
	)

func _draw_ground(vp: Vector2) -> void:
	draw_rect(Rect2(0, vp.y * 0.68, vp.x, vp.y * 0.32), Color(0.13, 0.10, 0.07))
	draw_rect(Rect2(0, vp.y * 0.68, vp.x, 3),            Color(0.06, 0.04, 0.02))

func _draw_dojo_floor(vp: Vector2) -> void:
	var fx := vp.x * 0.2
	var fw := vp.x * 0.6
	var fy := vp.y * 0.664
	var fh := vp.y * 0.042

	draw_rect(Rect2(fx, fy, fw, fh), Color(0.30, 0.21, 0.12))
	draw_rect(Rect2(fx, fy,          fw, 2.5), Color(0.46, 0.33, 0.20))
	draw_rect(Rect2(fx, fy + fh - 2, fw, 2),  Color(0.15, 0.10, 0.05))

	# Wood grain
	for i in 11:
		var lx := fx + i * (fw / 11.0)
		draw_line(Vector2(lx, fy), Vector2(lx, fy + fh), Color(0.20, 0.13, 0.07, 0.50), 1)
	# Center court mark
	draw_line(Vector2(vp.x * 0.5, fy), Vector2(vp.x * 0.5, fy + fh),
			  Color(0.38, 0.28, 0.15, 0.80), 2)
	# Side accent lines
	draw_line(Vector2(fx, fy + 3), Vector2(fx + fw, fy + 3),
			  Color(0.42, 0.30, 0.16, 0.35), 1)

# ── Ellipse helper ─────────────────────────────────────────────────────────────

func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) * TAU / 24.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polygon(pts, PackedColorArray([col]))

# ── Particle factories ─────────────────────────────────────────────────────────

func _make_embers(vp: Vector2) -> GPUParticles2D:
	var p   := GPUParticles2D.new()
	p.amount  = 70
	p.lifetime = 4.0
	p.position = Vector2(vp.x * 0.5, vp.y * 0.65)

	var mat := ParticleProcessMaterial.new()
	mat.direction            = Vector3(0.0, -1.0, 0.0)
	mat.spread               = 50.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 90.0
	mat.gravity              = Vector3(6.0, 30.0, 0.0)
	mat.scale_min            = 2.0
	mat.scale_max            = 5.0
	mat.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp.x * 0.22, 6.0, 0.0)

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.40, 1.0])
	grad.colors  = PackedColorArray([
		Color(1.0, 0.88, 0.28, 1.0),
		Color(1.0, 0.38, 0.05, 0.75),
		Color(0.38, 0.04, 0.0,  0.0),
	])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	mat.color_ramp = gt

	p.process_material = mat
	return p

func _make_rain(vp: Vector2) -> GPUParticles2D:
	var p    := GPUParticles2D.new()
	p.amount   = 220
	p.lifetime  = 1.1
	p.position  = Vector2(vp.x * 0.5, -10.0)

	var mat := ParticleProcessMaterial.new()
	mat.direction            = Vector3(0.15, 1.0, 0.0)
	mat.spread               = 4.0
	mat.initial_velocity_min = 450.0
	mat.initial_velocity_max = 650.0
	mat.gravity              = Vector3(0.0, 0.0, 0.0)
	mat.scale_min            = 1.0
	mat.scale_max            = 2.5
	mat.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp.x * 0.65, 0.0, 0.0)

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.70, 1.0])
	grad.colors  = PackedColorArray([
		Color(0.65, 0.78, 1.0, 0.0),
		Color(0.70, 0.82, 1.0, 0.55),
		Color(0.70, 0.82, 1.0, 0.50),
		Color(0.65, 0.78, 1.0, 0.0),
	])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	mat.color_ramp = gt

	p.process_material = mat
	return p

func _make_fireflies(vp: Vector2) -> GPUParticles2D:
	var p    := GPUParticles2D.new()
	p.amount   = 22
	p.lifetime  = 5.5
	p.position  = Vector2(vp.x * 0.5, vp.y * 0.60)

	var mat := ParticleProcessMaterial.new()
	mat.direction            = Vector3(0.0, -1.0, 0.0)
	mat.spread               = 130.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 14.0
	mat.gravity              = Vector3(0.0, 3.0, 0.0)
	mat.scale_min            = 3.5
	mat.scale_max            = 6.5
	mat.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp.x * 0.32, vp.y * 0.08, 0.0)

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 1.0])
	grad.colors  = PackedColorArray([
		Color(0.72, 1.0, 0.52, 0.0),
		Color(0.82, 1.0, 0.62, 0.80),
		Color(0.86, 1.0, 0.65, 0.80),
		Color(0.72, 1.0, 0.52, 0.0),
	])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	mat.color_ramp = gt

	p.process_material = mat
	return p
