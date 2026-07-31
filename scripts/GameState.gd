extends Node

enum Stage {
	AIR = 0, HAY = 1, TREE = 2, STONE = 3,
	WATERFALL = 4, VOLCANO = 5, MOUNTAIN = 6, TYPHOON = 7,
	SENSEI = 8, SPIRIT_WOLF = 9, DRAGON = 10,
	AMATERASU = 11, SUSANOO = 12, IZANAGI_IZANAMI = 13
}

const STAGE_NAMES = [
	"el Aire", "el Rollo de Paja", "el Árbol", "la Piedra",
	"la Cascada", "el Volcán", "la Montaña", "el Tifón",
	"el Sensei", "el Lobo Espíritu", "el Dragón Ancestral",
	"Amaterasu", "Susanoo", "Izanagi e Izanami"
]
const STAGE_HP = [
	INF,     100.0,    500.0,    3000.0,
	INF,     INF,      INF,      INF,
	80000.0, 150000.0, 600000.0,
	2000000.0, 8000000.0, 30000000.0
]
const STAGE_BONUS = [
	0,      60,     250,     1000,
	0,      3000,   10000,   0,
	20000,  80000,  300000,
	1000000, 5000000, 20000000
]

const AIR_PUNCHES_TO_ADVANCE      = 25
const WATERFALL_PUNCHES_TO_ADVANCE = 300
const VOLCANO_PUNCHES_TO_ADVANCE   = 400
const MOUNTAIN_PUNCHES_TO_ADVANCE  = 500
const TYPHOON_PUNCHES_TO_ADVANCE   = 600

var stage: int = Stage.AIR
var target_hp: float = INF
var target_max_hp: float = INF

var air_punches: int       = 0
var waterfall_punches: int = 0
var volcano_punches: int   = 0
var mountain_punches: int  = 0
var typhoon_punches: int   = 0
var game_complete: bool    = false

var strength_level: int  = 0
var speed_level: int     = 0
var technique_level: int = 0

var strength: float  = 1.0
var speed: float     = 1.0
var technique: float = 0.05

var skill_tree_unlocked: bool = false
var elemental_level: int = 0
var ki_level: int        = 0

var gold: int = 0

# Elements: [water, fire, earth, wind]
var elements: Array[bool] = [false, false, false, false]

signal stage_changed(s: int)
signal gold_changed(g: int)
signal stats_changed()
signal skill_tree_unlocked_signal()
signal element_gained(index: int)

func _ready() -> void:
	_apply_stage(Stage.AIR)
	_apply_debug_cli_args()

# Debug-only startup overrides, e.g. `godot . -- --gold=500 --stage=2 --skill_tree`
func _apply_debug_cli_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.trim_prefix("--").split("=", true, 1)
		var key := parts[0]
		var value := parts[1] if parts.size() > 1 else ""
		match key:
			"gold":
				gold = value.to_int()
				gold_changed.emit(gold)
			"stage":
				_apply_stage(clampi(value.to_int(), Stage.AIR, Stage.SENSEI))
			"skill_tree":
				skill_tree_unlocked = true
				skill_tree_unlocked_signal.emit()
				stats_changed.emit()

func effective_speed() -> float:
	return speed + (0.5 if elements[3] else 0.0)

func effective_technique() -> float:
	return minf(technique + (0.15 if elements[0] else 0.0), 0.95)

func _apply_stage(s: int) -> void:
	stage = s
	target_max_hp = STAGE_HP[s]
	target_hp = target_max_hp
	stage_changed.emit(s)

func punch(combo_mult: float = 1.0) -> Dictionary:
	var is_crit := randf() < effective_technique()
	var dmg: float = strength * (2.5 if is_crit else 1.0) * combo_mult

	if elements[1]:
		dmg += strength * 0.3

	if elemental_level > 0:
		dmg += elemental_level * strength * 0.35
	if ki_level > 0:
		dmg *= 1.0 + ki_level * 0.3

	match stage:
		Stage.AIR:
			air_punches += 1
			if air_punches >= AIR_PUNCHES_TO_ADVANCE:
				_apply_stage(Stage.HAY)
		Stage.WATERFALL:
			waterfall_punches += 1
			if waterfall_punches >= WATERFALL_PUNCHES_TO_ADVANCE:
				_unlock_element(0)
				_apply_stage(Stage.VOLCANO)
		Stage.VOLCANO:
			volcano_punches += 1
			if volcano_punches >= VOLCANO_PUNCHES_TO_ADVANCE:
				_unlock_element(1)
				gold += STAGE_BONUS[Stage.VOLCANO]
				gold_changed.emit(gold)
				_apply_stage(Stage.MOUNTAIN)
		Stage.MOUNTAIN:
			mountain_punches += 1
			if mountain_punches >= MOUNTAIN_PUNCHES_TO_ADVANCE:
				_unlock_element(2)
				gold += STAGE_BONUS[Stage.MOUNTAIN]
				gold_changed.emit(gold)
				_apply_stage(Stage.TYPHOON)
		Stage.TYPHOON:
			typhoon_punches += 1
			if typhoon_punches >= TYPHOON_PUNCHES_TO_ADVANCE:
				_unlock_element(3)
				_apply_stage(Stage.SENSEI)
		Stage.IZANAGI_IZANAMI:
			if not game_complete:
				target_hp = maxf(0.0, target_hp - dmg)
				if target_hp == 0.0:
					game_complete = true
					gold += STAGE_BONUS[Stage.IZANAGI_IZANAMI]
					gold_changed.emit(gold)
					stage_changed.emit(Stage.IZANAGI_IZANAMI)
		_:
			target_hp = maxf(0.0, target_hp - dmg)
			if target_hp == 0.0:
				_destroy_target()

	var gold_mult: float = 1.25 if elements[2] else 1.0
	var earned: int = 1 if stage == Stage.AIR else maxi(1, int(dmg * 0.25 * gold_mult))
	gold += earned
	gold_changed.emit(gold)

	return {"damage": dmg, "is_crit": is_crit}

func _unlock_element(index: int) -> void:
	if elements[index]: return
	elements[index] = true
	element_gained.emit(index)
	stats_changed.emit()

func _destroy_target() -> void:
	gold += STAGE_BONUS[stage]
	gold_changed.emit(gold)

	if stage == Stage.STONE and not skill_tree_unlocked:
		skill_tree_unlocked = true
		skill_tree_unlocked_signal.emit()
		stats_changed.emit()

	_apply_stage(stage + 1)

# ── Costs ─────────────────────────────────────────────────────────────────────
func strength_cost() -> int:  return int(10  * pow(1.6, strength_level))
func speed_cost() -> int:     return int(15  * pow(1.7, speed_level))
func technique_cost() -> int: return int(25  * pow(1.8, technique_level))
func elemental_cost() -> int: return int(100 * pow(2.0, elemental_level))
func ki_cost() -> int:        return int(150 * pow(2.2, ki_level))

func can_upgrade_strength() -> bool:  return gold >= strength_cost()
func can_upgrade_speed() -> bool:     return gold >= speed_cost()
func can_upgrade_technique() -> bool: return gold >= technique_cost()
func can_upgrade_elemental() -> bool: return skill_tree_unlocked and gold >= elemental_cost()
func can_upgrade_ki() -> bool:        return skill_tree_unlocked and gold >= ki_cost()

func upgrade_strength() -> void:
	if not can_upgrade_strength(): return
	gold -= strength_cost()
	strength_level += 1
	strength = 1.0 + strength_level * 1.5
	stats_changed.emit()
	gold_changed.emit(gold)

func upgrade_speed() -> void:
	if not can_upgrade_speed(): return
	gold -= speed_cost()
	speed_level += 1
	speed = 1.0 + speed_level * 0.5
	stats_changed.emit()
	gold_changed.emit(gold)

func upgrade_technique() -> void:
	if not can_upgrade_technique(): return
	gold -= technique_cost()
	technique_level += 1
	technique = minf(0.05 + technique_level * 0.05, 0.90)
	stats_changed.emit()
	gold_changed.emit(gold)

func upgrade_elemental() -> void:
	if not can_upgrade_elemental(): return
	gold -= elemental_cost()
	elemental_level += 1
	stats_changed.emit()
	gold_changed.emit(gold)

func upgrade_ki() -> void:
	if not can_upgrade_ki(): return
	gold -= ki_cost()
	ki_level += 1
	stats_changed.emit()
	gold_changed.emit(gold)

func hp_ratio() -> float:
	if target_max_hp == INF: return 1.0
	return target_hp / target_max_hp

func target_name() -> String:
	return STAGE_NAMES[stage]
