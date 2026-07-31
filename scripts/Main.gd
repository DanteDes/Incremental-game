extends Node2D

var _punch_timer: float = 0.0

# Visual nodes
var _player_node: Node2D   # DrawPlayer
var _target_node: Node2D   # DrawTarget
var _player_home: Vector2
var _target_home: Vector2
var _tween_player: Tween
var _tween_target: Tween

# Shader materials
var _mat_player: ShaderMaterial
var _mat_target: ShaderMaterial

# UI — authored in scenes/Main.tscn, fetched by unique name
@onready var _damage_container: Control = %DamageLayer
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_title_lbl: Label = %HPTitleLabel

@onready var _gold_lbl: Label = %GoldLabel
@onready var _target_name_lbl: Label = %TargetNameLabel
@onready var _target_hp_lbl: Label = %TargetHpLabel
@onready var _str_val_lbl: Label = %StrValLabel
@onready var _spd_val_lbl: Label = %SpdValLabel
@onready var _tec_val_lbl: Label = %TecValLabel

@onready var _str_row: VBoxContainer = %StrRow
@onready var _spd_row: VBoxContainer = %SpdRow
@onready var _tec_row: VBoxContainer = %TecRow
@onready var _ele_row: VBoxContainer = %EleRow
@onready var _ki_row: VBoxContainer = %KiRow
@onready var _skill_section: Control = %SkillSection

func _ready() -> void:
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
	_update_all()

# ── Scene Construction ─────────────────────────────────────────────────────────
# Background/player/target art and shaders are created at runtime here.
# The UI (upgrade panel, info panel, top bar, damage layer) is authored
# directly in scenes/Main.tscn instead — see the UILayer node.

func _build_scene() -> void:
	var vp := get_viewport_rect().size

	# Background (mountains, sky, dojo floor)
	var bg: Node2D = load("res://scripts/DrawBackground.gd").new()
	add_child(bg)

	# Player character + ki aura shader
	_player_node = load("res://scripts/DrawPlayer.gd").new()
	_player_home = Vector2(vp.x * 0.3, vp.y * 0.68)
	_player_node.position = _player_home
	_mat_player = ShaderMaterial.new()
	_mat_player.shader = load("res://shaders/ki_aura.gdshader")
	_player_node.material = _mat_player
	add_child(_player_node)

	# Target + hit flash shader
	_target_node = load("res://scripts/DrawTarget.gd").new()
	_target_home = Vector2(vp.x * 0.68, vp.y * 0.68)
	_target_node.position = _target_home
	_mat_target = ShaderMaterial.new()
	_mat_target.shader = load("res://shaders/hit_flash.gdshader")
	_target_node.material = _mat_target
	add_child(_target_node)

	# Vignette overlay (above game world, below UI)
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 1
	add_child(vignette_layer)
	var vignette_rect := ColorRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_mat := ShaderMaterial.new()
	vignette_mat.shader = load("res://shaders/vignette.gdshader")
	vignette_rect.material = vignette_mat
	vignette_layer.add_child(vignette_rect)

# ── Game Loop ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if GameState.sensei_defeated: return

	_punch_timer += delta
	if _punch_timer >= 1.0 / GameState.speed:
		_punch_timer -= 1.0 / GameState.speed
		_execute_punch()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var vp := get_viewport_rect().size
	if event.position.x > 265 and event.position.x < vp.x - 225:
		_execute_punch()

func _execute_punch() -> void:
	var result: Dictionary = GameState.punch()
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
	if _tween_player:
		_tween_player.kill()
	if _tween_target:
		_tween_target.kill()

	# Ki aura flash on player
	_mat_player.set_shader_parameter("aura", 1.0)
	var tw_aura := create_tween()
	tw_aura.tween_method(
		func(v: float): _mat_player.set_shader_parameter("aura", v),
		1.0, 0.0, 0.3
	)

	# Hit flash on target
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
	if GameState.sensei_defeated:
		_hp_title_lbl.text = "¡GANASTE! ¡Superaste al Sensei!"
		_hp_bar.visible = false
		_target_name_lbl.text = "El Sensei te honra."
		_target_hp_lbl.text = "Eres el maestro ahora."
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
		_:
			_hp_bar.visible = true
			_hp_bar.value = GameState.hp_ratio()
			_hp_title_lbl.text = "Rompiendo " + GameState.target_name()
			_target_hp_lbl.text = "HP: %s / %s" % [_fmt(GameState.target_hp), _fmt(GameState.target_max_hp)]

func _update_all() -> void:
	_str_val_lbl.text = "Fuerza:    %.1f dmg" % GameState.strength
	_spd_val_lbl.text = "Velocidad: %.2f /s"  % GameState.speed
	_tec_val_lbl.text = "Técnica:   %d%% crit" % int(GameState.technique * 100)
	_gold_lbl.text = "Oro: " + _fmt(GameState.gold)
	_skill_section.visible = GameState.skill_tree_unlocked
	_update_hp_display()
	_update_button_states()

func _update_button_states() -> void:
	_str_row.set_state(GameState.strength_level, GameState.strength_cost(), not GameState.can_upgrade_strength())
	_spd_row.set_state(GameState.speed_level, GameState.speed_cost(), not GameState.can_upgrade_speed())
	_tec_row.set_state(GameState.technique_level, GameState.technique_cost(), not GameState.can_upgrade_technique())
	_ele_row.set_state(GameState.elemental_level, GameState.elemental_cost(), not GameState.can_upgrade_elemental())
	_ki_row.set_state(GameState.ki_level, GameState.ki_cost(), not GameState.can_upgrade_ki())

# ── Signal Handlers ────────────────────────────────────────────────────────────

func _on_stage_changed(_s: int) -> void:
	_update_all()  # DrawTarget handles its own redraw via its own signal connection

func _on_gold_changed(_g: int) -> void:
	_gold_lbl.text = "Oro: " + _fmt(GameState.gold)
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
