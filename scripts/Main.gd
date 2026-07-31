extends Node2D

const COMBO_WINDOW: float = 1.2

const ELEM_DATA := [
	["~ Agua",    Color(0.30, 0.65, 1.0), "+15% crit"],
	["~ Fuego",   Color(1.00, 0.42, 0.1), "+30% daño"],
	["~ Tierra",  Color(0.45, 0.78, 0.2), "+25% oro"],
	["~ Huracan", Color(0.72, 0.90, 1.0), "+0.5 vel"],
]

var _punch_timer: float  = 0.0
var _combo: int          = 0
var _combo_decay: float  = 0.0

# Visual nodes
var _player_node: Node2D
var _target_node: Node2D
var _player_home: Vector2
var _target_home: Vector2
var _tween_player: Tween
var _tween_target: Tween

# Shader materials
var _mat_player: ShaderMaterial
var _mat_target: ShaderMaterial
var _mat_vignette: ShaderMaterial
var _tint_current: Color = Color(0.03, 0.05, 0.12)

const STAGE_TINTS: Array[Color] = [
	Color(0.03, 0.05, 0.12),  # 0  Air        — night blue (default)
	Color(0.07, 0.05, 0.02),  # 1  Hay         — warm straw
	Color(0.02, 0.06, 0.02),  # 2  Tree        — forest dark
	Color(0.05, 0.05, 0.07),  # 3  Stone       — cold grey
	Color(0.01, 0.04, 0.10),  # 4  Waterfall   — deep teal
	Color(0.12, 0.03, 0.01),  # 5  Volcano     — ember red
	Color(0.04, 0.04, 0.08),  # 6  Mountain    — slate purple
	Color(0.02, 0.03, 0.10),  # 7  Typhoon     — storm blue
	Color(0.07, 0.04, 0.01),  # 8  Sensei      — amber lamp
	Color(0.01, 0.07, 0.03),  # 9  Spirit Wolf — spectral green
	Color(0.10, 0.02, 0.01),  # 10 Dragon      — deep scarlet
	Color(0.09, 0.07, 0.01),  # 11 Amaterasu   — solar gold
	Color(0.02, 0.03, 0.10),  # 12 Susanoo     — storm navy
	Color(0.06, 0.02, 0.08),  # 13 Izanagi/Izanami — void purple
]

# UI — authored in scenes/Main.tscn, fetched by unique name
@onready var _damage_container: Control = %DamageLayer
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_title_lbl: Label = %HPTitleLabel
@onready var _combo_lbl: Label = %ComboLabel

@onready var _gold_lbl: Label = %GoldLabel
@onready var _target_name_lbl: Label = %TargetNameLabel
@onready var _target_hp_lbl: Label = %TargetHpLabel
@onready var _str_val_lbl: Label = %StrValLabel
@onready var _spd_val_lbl: Label = %SpdValLabel
@onready var _tec_val_lbl: Label = %TecValLabel

@onready var _str_row: UpgradeRow = %StrRow
@onready var _spd_row: UpgradeRow = %SpdRow
@onready var _tec_row: UpgradeRow = %TecRow
@onready var _ele_row: UpgradeRow = %EleRow
@onready var _ki_row: UpgradeRow = %KiRow
@onready var _skill_section: Control = %SkillSection

var _element_lbls: Array[Label]

func _ready() -> void:
	_element_lbls = [%AguaLabel, %FuegoLabel, %TierraLabel, %HuracanLabel]

	_build_scene()

	_str_row.configure("FUERZA", "Aumenta el daño por golpe")
	_str_row.pressed.connect(GameState.upgrade_strength)
	_spd_row.configure("VELOCIDAD", "Golpes automáticos por segundo")
	_spd_row.pressed.connect(GameState.upgrade_speed)
	_tec_row.configure("TÉCNICA", "Probabilidad de golpe crítico (x2.5)")
	_tec_row.pressed.connect(GameState.upgrade_technique)
	_ele_row.configure("ELEMENTAL", "Añade daño elemental fijo")
	_ele_row.pressed.connect(GameState.upgrade_elemental)
	_ki_row.configure("KI", "Multiplica todo el daño")
	_ki_row.pressed.connect(GameState.upgrade_ki)

	GameState.stage_changed.connect(_on_stage_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.skill_tree_unlocked_signal.connect(_on_skill_tree_unlocked)
	GameState.element_gained.connect(_on_element_gained)
	_update_all()

# ── Scene Construction ─────────────────────────────────────────────────────────
# Background/player/target art and shaders are created at runtime here.
# The UI (upgrade panel, info panel, top bar, damage layer) is authored
# directly in scenes/Main.tscn instead — see the UILayer node.

func _build_scene() -> void:
	var vp := get_viewport_rect().size

	var bg: Node2D = load("res://scripts/DrawBackground.gd").new()
	add_child(bg)

	_player_node = load("res://scripts/DrawPlayer.gd").new()
	_player_home = Vector2(vp.x * 0.3, vp.y * 0.68)
	_player_node.position = _player_home
	_mat_player = ShaderMaterial.new()
	_mat_player.shader = load("res://shaders/ki_aura.gdshader")
	_player_node.material = _mat_player
	add_child(_player_node)

	_target_node = load("res://scripts/DrawTarget.gd").new()
	_target_home = Vector2(vp.x * 0.68, vp.y * 0.68)
	_target_node.position = _target_home
	_mat_target = ShaderMaterial.new()
	_mat_target.shader = load("res://shaders/hit_flash.gdshader")
	_target_node.material = _mat_target
	add_child(_target_node)

	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 1
	add_child(vignette_layer)
	var vignette_rect := ColorRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat_vignette = ShaderMaterial.new()
	_mat_vignette.shader = load("res://shaders/vignette.gdshader")
	vignette_rect.material = _mat_vignette
	vignette_layer.add_child(vignette_rect)

# ── Game Loop ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if GameState.game_complete: return

	if _combo > 0:
		_combo_decay -= delta
		if _combo_decay <= 0.0:
			_combo = 0
			_update_combo_display()

	_punch_timer += delta
	if _punch_timer >= 1.0 / GameState.effective_speed():
		_punch_timer -= 1.0 / GameState.effective_speed()
		_execute_punch(false)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var vp := get_viewport_rect().size
	if event.position.x > 265 and event.position.x < vp.x - 225:
		_execute_punch(true)

func _execute_punch(is_manual: bool) -> void:
	if is_manual:
		_combo += 1
		_combo_decay = COMBO_WINDOW
		_update_combo_display()
	var result: Dictionary = GameState.punch(_combo_multiplier())
	_spawn_damage(result.damage, result.is_crit)
	_animate_punch()
	_update_hp_display()
	_update_button_states()

func _combo_multiplier() -> float:
	if _combo <= 1: return 1.0
	return 1.0 + minf(float(_combo - 1), 20.0) * 0.1

func _update_combo_display() -> void:
	if _combo <= 1:
		_combo_lbl.visible = false
		return
	_combo_lbl.visible = true
	var mult := _combo_multiplier()
	_combo_lbl.text = "COMBO  x%.1f" % mult
	var t := minf(float(_combo - 1) / 19.0, 1.0)
	_combo_lbl.modulate = Color(1.0, 1.0 - t * 0.6, 0.2)

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
	if _tween_player: _tween_player.kill()
	if _tween_target: _tween_target.kill()

	_mat_player.set_shader_parameter("aura", 1.0)
	var tw_aura := create_tween()
	tw_aura.tween_method(
		func(v: float): _mat_player.set_shader_parameter("aura", v),
		1.0, 0.0, 0.3
	)

	_mat_target.set_shader_parameter("flash", 1.0)
	var tw_flash := create_tween()
	tw_flash.tween_method(
		func(v: float): _mat_target.set_shader_parameter("flash", v),
		1.0, 0.0, 0.18
	)

	_player_node.punch_anim()
	_tween_player = create_tween()
	_tween_player.tween_property(_player_node, "position", _player_home + Vector2(22, -4), 0.06)
	_tween_player.tween_property(_player_node, "position", _player_home, 0.12)

	_tween_target = create_tween()
	_tween_target.tween_property(_target_node, "position", _target_home + Vector2(10, 0),  0.04)
	_tween_target.tween_property(_target_node, "position", _target_home + Vector2(-6, 0),  0.04)
	_tween_target.tween_property(_target_node, "position", _target_home,                   0.04)

# ── UI Updates ─────────────────────────────────────────────────────────────────

func _update_hp_display() -> void:
	if GameState.game_complete:
		_hp_title_lbl.text = "¡LEYENDA! Venciste a Izanagi e Izanami"
		_hp_bar.visible = false
		_target_name_lbl.text = "El cosmos te reconoce."
		_target_hp_lbl.text = "No hay más adversarios."
		return

	_target_name_lbl.text = "Objetivo: " + GameState.target_name()

	match GameState.stage:
		GameState.Stage.AIR:
			_hp_bar.visible = false
			_hp_title_lbl.text = "Calentando motores..."
			_target_hp_lbl.text = "%d / %d golpes al aire" % [GameState.air_punches, GameState.AIR_PUNCHES_TO_ADVANCE]
		GameState.Stage.WATERFALL:
			_hp_bar.visible = false
			_hp_title_lbl.text = "Entrenando en la Cascada"
			_target_hp_lbl.text = "%d / %d golpes" % [GameState.waterfall_punches, GameState.WATERFALL_PUNCHES_TO_ADVANCE]
		GameState.Stage.VOLCANO:
			_hp_bar.visible = false
			_hp_title_lbl.text = "Canalizando el Volcan"
			_target_hp_lbl.text = "%d / %d golpes" % [GameState.volcano_punches, GameState.VOLCANO_PUNCHES_TO_ADVANCE]
		GameState.Stage.MOUNTAIN:
			_hp_bar.visible = false
			_hp_title_lbl.text = "Escalando la Montana"
			_target_hp_lbl.text = "%d / %d golpes" % [GameState.mountain_punches, GameState.MOUNTAIN_PUNCHES_TO_ADVANCE]
		GameState.Stage.TYPHOON:
			_hp_bar.visible = false
			_hp_title_lbl.text = "Resistiendo el Tifon"
			_target_hp_lbl.text = "%d / %d golpes" % [GameState.typhoon_punches, GameState.TYPHOON_PUNCHES_TO_ADVANCE]
		_:
			_hp_bar.visible = true
			_hp_bar.value = GameState.hp_ratio()
			_hp_title_lbl.text = "Enfrentando " + GameState.target_name()
			_target_hp_lbl.text = "HP: %s / %s" % [_fmt(GameState.target_hp), _fmt(GameState.target_max_hp)]

func _update_all() -> void:
	_str_val_lbl.text = "Fuerza:    %.1f dmg" % GameState.strength
	_spd_val_lbl.text = "Velocidad: %.2f /s"  % GameState.effective_speed()
	_tec_val_lbl.text = "Tecnica:   %d%% crit" % int(GameState.effective_technique() * 100)
	_gold_lbl.text = "Oro: " + _fmt(GameState.gold)
	_skill_section.visible = GameState.skill_tree_unlocked
	for i in 4:
		if GameState.elements[i]:
			_element_lbls[i].modulate = ELEM_DATA[i][1]
	_update_hp_display()
	_update_button_states()

func _update_button_states() -> void:
	_str_row.set_state(GameState.strength_level, GameState.strength_cost(), not GameState.can_upgrade_strength())
	_spd_row.set_state(GameState.speed_level, GameState.speed_cost(), not GameState.can_upgrade_speed())
	_tec_row.set_state(GameState.technique_level, GameState.technique_cost(), not GameState.can_upgrade_technique())
	_ele_row.set_state(GameState.elemental_level, GameState.elemental_cost(), not GameState.can_upgrade_elemental())
	_ki_row.set_state(GameState.ki_level, GameState.ki_cost(), not GameState.can_upgrade_ki())

# ── Signal Handlers ────────────────────────────────────────────────────────────

func _on_stage_changed(s: int) -> void:
	_update_all()
	_transition_stage_tint(s)

func _transition_stage_tint(s: int) -> void:
	if s < 0 or s >= STAGE_TINTS.size(): return
	var target := STAGE_TINTS[s]
	var from := _tint_current
	var tw := create_tween()
	tw.tween_method(
		func(c: Color):
			_tint_current = c
			_mat_vignette.set_shader_parameter("tint_color", Vector3(c.r, c.g, c.b)),
		from, target, 1.5
	)

func _on_gold_changed(_g: int) -> void:
	_gold_lbl.text = "Oro: " + _fmt(GameState.gold)
	_update_button_states()

func _on_stats_changed() -> void:
	_update_all()

func _on_skill_tree_unlocked() -> void:
	_skill_section.visible = true

func _on_element_gained(index: int) -> void:
	var tw := create_tween()
	tw.tween_property(_element_lbls[index], "modulate", ELEM_DATA[index][1], 0.6)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _fmt(n: float) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:     return "%.1fK" % (n / 1_000.0)
	return str(int(n))
