extends Node2D

var _punch_timer: float = 0.0

# Visual nodes
var _player_node: Node2D   # DrawPlayer
var _target_node: Node2D   # DrawTarget
var _damage_container: Control
var _hp_bar: ProgressBar
var _hp_title_lbl: Label

# Info panel
var _gold_lbl: Label
var _target_name_lbl: Label
var _target_hp_lbl: Label
var _str_val_lbl: Label
var _spd_val_lbl: Label
var _tec_val_lbl: Label

# Upgrade buttons
var _btn_str: Button
var _btn_spd: Button
var _btn_tec: Button
var _btn_ele: Button
var _btn_ki: Button
var _skill_section: Control

func _ready() -> void:
	_build_scene()
	var gs = get_node("/root/GameState")
	gs.stage_changed.connect(_on_stage_changed)
	gs.gold_changed.connect(_on_gold_changed)
	gs.stats_changed.connect(_on_stats_changed)
	gs.skill_tree_unlocked_signal.connect(_on_skill_tree_unlocked)
	_update_all()

# ── Scene Construction ─────────────────────────────────────────────────────────

func _build_scene() -> void:
	var vp := get_viewport_rect().size

	# Background (mountains, sky, dojo floor)
	var bg: Node2D = load("res://scripts/DrawBackground.gd").new()
	add_child(bg)

	# Player character
	_player_node = load("res://scripts/DrawPlayer.gd").new()
	_player_node.position = Vector2(vp.x * 0.3, vp.y * 0.68)
	add_child(_player_node)

	# Target (self-manages redraws via GameState signal)
	_target_node = load("res://scripts/DrawTarget.gd").new()
	_target_node.position = Vector2(vp.x * 0.68, vp.y * 0.68)
	add_child(_target_node)

	# UI layer
	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)

	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)

	_build_upgrade_panel(ui_root, vp)
	_build_info_panel(ui_root, vp)
	_build_top_bar(ui_root, vp)

	_damage_container = Control.new()
	_damage_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_damage_container)

func _build_upgrade_panel(parent: Control, vp: Vector2) -> void:
	var panel := Panel.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(260, vp.y)
	parent.add_child(panel)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   12)
	mc.add_theme_constant_override("margin_right",  12)
	mc.add_theme_constant_override("margin_top",    14)
	mc.add_theme_constant_override("margin_bottom", 10)
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	mc.add_child(vbox)

	var title := Label.new()
	title.text = "MEJORAS"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_btn_str = _upgrade_row(vbox, "FUERZA",    "Aumenta el daño por golpe")
	_btn_str.pressed.connect(func(): get_node("/root/GameState").upgrade_strength())

	_btn_spd = _upgrade_row(vbox, "VELOCIDAD", "Golpes automáticos por segundo")
	_btn_spd.pressed.connect(func(): get_node("/root/GameState").upgrade_speed())

	_btn_tec = _upgrade_row(vbox, "TÉCNICA",   "Probabilidad de golpe crítico (x2.5)")
	_btn_tec.pressed.connect(func(): get_node("/root/GameState").upgrade_technique())

	vbox.add_child(HSeparator.new())

	_skill_section = VBoxContainer.new()
	_skill_section.visible = false
	_skill_section.add_theme_constant_override("separation", 5)
	vbox.add_child(_skill_section)

	var sk_lbl := Label.new()
	sk_lbl.text = "SKILL TREE"
	sk_lbl.add_theme_font_size_override("font_size", 16)
	sk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sk_lbl.modulate = Color(1.0, 0.82, 0.2)
	_skill_section.add_child(sk_lbl)

	var sk_hint := Label.new()
	sk_hint.text = "Desbloqueado al romper la Piedra"
	sk_hint.add_theme_font_size_override("font_size", 9)
	sk_hint.modulate = Color(0.7, 0.65, 0.5)
	sk_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_section.add_child(sk_hint)

	_btn_ele = _upgrade_row(_skill_section, "ELEMENTAL", "Añade daño elemental fijo")
	_btn_ele.pressed.connect(func(): get_node("/root/GameState").upgrade_elemental())

	_btn_ki = _upgrade_row(_skill_section, "KI", "Multiplica todo el daño")
	_btn_ki.pressed.connect(func(): get_node("/root/GameState").upgrade_ki())

func _upgrade_row(parent: Control, stat: String, desc: String) -> Button:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 1)
	parent.add_child(container)

	var name_lbl := Label.new()
	name_lbl.text = stat
	name_lbl.add_theme_font_size_override("font_size", 13)
	container.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.modulate = Color(0.72, 0.72, 0.72)
	container.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "Mejorar"
	container.add_child(btn)
	return btn

func _build_info_panel(parent: Control, vp: Vector2) -> void:
	var panel := Panel.new()
	panel.position = Vector2(vp.x - 225, 0)
	panel.size = Vector2(225, vp.y)
	parent.add_child(panel)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   12)
	mc.add_theme_constant_override("margin_right",  12)
	mc.add_theme_constant_override("margin_top",    14)
	mc.add_theme_constant_override("margin_bottom", 10)
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	mc.add_child(vbox)

	var title := Label.new()
	title.text = "ESTADO"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_gold_lbl = Label.new()
	_gold_lbl.text = "Oro: 0"
	_gold_lbl.add_theme_font_size_override("font_size", 16)
	_gold_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(_gold_lbl)

	vbox.add_child(HSeparator.new())

	_target_name_lbl = Label.new()
	_target_name_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_target_name_lbl)

	_target_hp_lbl = Label.new()
	_target_hp_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_target_hp_lbl)

	vbox.add_child(HSeparator.new())

	var stats_title := Label.new()
	stats_title.text = "ESTADÍSTICAS"
	stats_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stats_title)

	_str_val_lbl = Label.new()
	_str_val_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_str_val_lbl)

	_spd_val_lbl = Label.new()
	_spd_val_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_spd_val_lbl)

	_tec_val_lbl = Label.new()
	_tec_val_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_tec_val_lbl)

func _build_top_bar(parent: Control, vp: Vector2) -> void:
	var bar_w := vp.x - 490.0
	var container := Control.new()
	container.position = Vector2(265, 10)
	container.size = Vector2(bar_w, 58)
	parent.add_child(container)

	_hp_title_lbl = Label.new()
	_hp_title_lbl.size = Vector2(bar_w, 26)
	_hp_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_title_lbl.add_theme_font_size_override("font_size", 15)
	container.add_child(_hp_title_lbl)

	_hp_bar = ProgressBar.new()
	_hp_bar.position = Vector2(0, 28)
	_hp_bar.size = Vector2(bar_w, 24)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 1.0
	_hp_bar.value = 1.0
	_hp_bar.show_percentage = false
	container.add_child(_hp_bar)

# ── Game Loop ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	var gs = get_node("/root/GameState")
	if gs.sensei_defeated: return

	_punch_timer += delta
	if _punch_timer >= 1.0 / gs.speed:
		_punch_timer -= 1.0 / gs.speed
		_execute_punch()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var vp := get_viewport_rect().size
	if event.position.x > 265 and event.position.x < vp.x - 225:
		_execute_punch()

func _execute_punch() -> void:
	var gs = get_node("/root/GameState")
	var result: Dictionary = gs.punch()
	_spawn_damage(result.damage, result.is_crit)
	_animate_punch()
	_update_hp_display()
	_update_button_states()

func _spawn_damage(dmg: float, is_crit: bool) -> void:
	var vp := get_viewport_rect().size
	var lbl := Label.new()
	lbl.text = ("¡CRÍTICO! +" if is_crit else "+") + _fmt(dmg)
	lbl.add_theme_font_size_override("font_size", 22 if is_crit else 14)
	lbl.modulate = Color(1.0, 0.22, 0.08) if is_crit else Color(1.0, 1.0, 0.4)
	lbl.position = Vector2(
		vp.x * 0.58 + randf_range(-55, 55),
		vp.y * 0.44 + randf_range(-30, 30)
	)
	_damage_container.add_child(lbl)

	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(randf_range(-15, 15), -75), 0.85)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85)
	tw.tween_callback(lbl.queue_free)

func _animate_punch() -> void:
	# Player moves forward + arm extends
	var orig_p := _player_node.position
	_player_node.punch_anim()
	var tw_p := create_tween()
	tw_p.tween_property(_player_node, "position", orig_p + Vector2(22, -4), 0.06)
	tw_p.tween_property(_player_node, "position", orig_p, 0.12)

	# Target shakes
	var orig_t := _target_node.position
	var tw_t := create_tween()
	tw_t.tween_property(_target_node, "position", orig_t + Vector2(10, 0),  0.04)
	tw_t.tween_property(_target_node, "position", orig_t + Vector2(-6, 0),  0.04)
	tw_t.tween_property(_target_node, "position", orig_t,                   0.04)

# ── UI Updates ─────────────────────────────────────────────────────────────────

func _update_hp_display() -> void:
	var gs = get_node("/root/GameState")

	if gs.sensei_defeated:
		_hp_title_lbl.text = "¡GANASTE! ¡Superaste al Sensei!"
		_hp_bar.visible = false
		_target_name_lbl.text = "El Sensei te honra."
		_target_hp_lbl.text = "Eres el maestro ahora."
		return

	_target_name_lbl.text = "Objetivo: " + gs.target_name()

	match gs.stage:
		0:  # AIR
			_hp_bar.visible = false
			_hp_title_lbl.text = "Calentando motores..."
			_target_hp_lbl.text = "%d / %d golpes al aire" % [gs.air_punches, gs.AIR_PUNCHES_TO_ADVANCE]
		4:  # WATERFALL
			_hp_bar.visible = false
			_hp_title_lbl.text = "Entrenando en la Cascada"
			_target_hp_lbl.text = "%d / %d golpes" % [gs.waterfall_punches, gs.WATERFALL_PUNCHES_TO_ADVANCE]
		_:
			_hp_bar.visible = true
			_hp_bar.value = gs.hp_ratio()
			_hp_title_lbl.text = "Rompiendo " + gs.target_name()
			_target_hp_lbl.text = "HP: %s / %s" % [_fmt(gs.target_hp), _fmt(gs.target_max_hp)]

func _update_all() -> void:
	var gs = get_node("/root/GameState")
	_str_val_lbl.text = "Fuerza:    %.1f dmg" % gs.strength
	_spd_val_lbl.text = "Velocidad: %.2f /s"  % gs.speed
	_tec_val_lbl.text = "Técnica:   %d%% crit" % int(gs.technique * 100)
	_gold_lbl.text = "Oro: " + _fmt(gs.gold)
	_skill_section.visible = gs.skill_tree_unlocked
	_update_hp_display()
	_update_button_states()

func _update_button_states() -> void:
	var gs = get_node("/root/GameState")
	_btn_str.text     = "Nv.%d — $%s" % [gs.strength_level + 1, _fmt(gs.strength_cost())]
	_btn_str.disabled = not gs.can_upgrade_strength()

	_btn_spd.text     = "Nv.%d — $%s" % [gs.speed_level + 1, _fmt(gs.speed_cost())]
	_btn_spd.disabled = not gs.can_upgrade_speed()

	_btn_tec.text     = "Nv.%d — $%s" % [gs.technique_level + 1, _fmt(gs.technique_cost())]
	_btn_tec.disabled = not gs.can_upgrade_technique()

	_btn_ele.text     = "Nv.%d — $%s" % [gs.elemental_level + 1, _fmt(gs.elemental_cost())]
	_btn_ele.disabled = not gs.can_upgrade_elemental()

	_btn_ki.text      = "Nv.%d — $%s" % [gs.ki_level + 1, _fmt(gs.ki_cost())]
	_btn_ki.disabled  = not gs.can_upgrade_ki()

# ── Signal Handlers ────────────────────────────────────────────────────────────

func _on_stage_changed(_s: int) -> void:
	_update_all()  # DrawTarget handles its own redraw via its own signal connection

func _on_gold_changed(_g: int) -> void:
	var gs = get_node("/root/GameState")
	_gold_lbl.text = "Oro: " + _fmt(gs.gold)
	_update_button_states()

func _on_stats_changed() -> void:
	_update_all()

func _on_skill_tree_unlocked() -> void:
	_skill_section.visible = true

# ── Helpers ────────────────────────────────────────────────────────────────────

func _fmt(n: float) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:     return "%.1fK" % (n / 1_000.0)
	return str(int(n))
