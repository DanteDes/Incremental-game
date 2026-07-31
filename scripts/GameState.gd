extends Node

enum Stage { AIR = 0, HAY = 1, TREE = 2, STONE = 3, WATERFALL = 4, SENSEI = 5 }

const STAGE_NAMES = ["el Aire", "el Rollo de Paja", "el Árbol", "la Piedra", "la Cascada", "el Sensei"]
const STAGE_HP    = [INF,       100.0,               500.0,      3000.0,      INF,           20000.0]
const STAGE_BONUS = [0,         60,                  250,        1000,        0,             5000]

const AIR_PUNCHES_TO_ADVANCE       = 25
const WATERFALL_PUNCHES_TO_ADVANCE = 300

var stage: int = Stage.AIR
var target_hp: float = INF
var target_max_hp: float = INF

var air_punches: int = 0
var waterfall_punches: int = 0
var sensei_defeated: bool = false

var strength_level: int = 0
var speed_level: int    = 0
var technique_level: int = 0

var strength: float  = 1.0
var speed: float     = 1.0
var technique: float = 0.05

var skill_tree_unlocked: bool = false
var elemental_level: int = 0
var ki_level: int        = 0

var gold: int = 0

signal stage_changed(s: int)
signal gold_changed(g: int)
signal stats_changed()
signal skill_tree_unlocked_signal()

func _ready() -> void:
	_apply_stage(Stage.AIR)

func _apply_stage(s: int) -> void:
	stage = s
	target_max_hp = STAGE_HP[s]
	target_hp = target_max_hp
	emit_signal("stage_changed", s)

# Returns { damage: float, is_crit: bool }
func punch() -> Dictionary:
	var dmg = strength * (2.5 if randf() < technique else 1.0)

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
				_apply_stage(Stage.SENSEI)
		Stage.SENSEI:
			if not sensei_defeated:
				target_hp = maxf(0.0, target_hp - dmg)
				if target_hp == 0.0:
					sensei_defeated = true
					emit_signal("stage_changed", Stage.SENSEI)
		_:
			target_hp = maxf(0.0, target_hp - dmg)
			if target_hp == 0.0:
				_destroy_target()

	var earned = 1 if stage == Stage.AIR else maxi(1, int(dmg * 0.25))
	gold += earned
	emit_signal("gold_changed", gold)

	return {"damage": dmg, "is_crit": dmg > strength * 1.5}

func _destroy_target() -> void:
	gold += STAGE_BONUS[stage]
	emit_signal("gold_changed", gold)

	if stage == Stage.STONE and not skill_tree_unlocked:
		skill_tree_unlocked = true
		emit_signal("skill_tree_unlocked_signal")
		emit_signal("stats_changed")

	var next = mini(stage + 1, Stage.SENSEI)
	_apply_stage(next)

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
	emit_signal("stats_changed")
	emit_signal("gold_changed", gold)

func upgrade_speed() -> void:
	if not can_upgrade_speed(): return
	gold -= speed_cost()
	speed_level += 1
	speed = 1.0 + speed_level * 0.5
	emit_signal("stats_changed")
	emit_signal("gold_changed", gold)

func upgrade_technique() -> void:
	if not can_upgrade_technique(): return
	gold -= technique_cost()
	technique_level += 1
	technique = minf(0.05 + technique_level * 0.05, 0.90)
	emit_signal("stats_changed")
	emit_signal("gold_changed", gold)

func upgrade_elemental() -> void:
	if not can_upgrade_elemental(): return
	gold -= elemental_cost()
	elemental_level += 1
	emit_signal("stats_changed")
	emit_signal("gold_changed", gold)

func upgrade_ki() -> void:
	if not can_upgrade_ki(): return
	gold -= ki_cost()
	ki_level += 1
	emit_signal("stats_changed")
	emit_signal("gold_changed", gold)

func hp_ratio() -> float:
	if target_max_hp == INF: return 1.0
	return target_hp / target_max_hp

func target_name() -> String:
	return STAGE_NAMES[stage]
