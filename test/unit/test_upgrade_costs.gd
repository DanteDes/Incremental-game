extends GutTest

var GameStateScript = load("res://scripts/GameState.gd")
var state

func before_each():
	state = GameStateScript.new()
	add_child_autofree(state)

func test_strength_cost_at_level_zero():
	assert_eq(state.strength_cost(), 10)

func test_strength_cost_scales_with_level():
	state.strength_level = 1
	assert_eq(state.strength_cost(), 16)
	state.strength_level = 2
	assert_eq(state.strength_cost(), 25)

func test_speed_cost_scales_with_level():
	assert_eq(state.speed_cost(), 15)
	state.speed_level = 1
	assert_eq(state.speed_cost(), 25)
	state.speed_level = 2
	assert_eq(state.speed_cost(), 43)

func test_technique_cost_scales_with_level():
	assert_eq(state.technique_cost(), 25)
	state.technique_level = 1
	assert_eq(state.technique_cost(), 45)
	state.technique_level = 2
	assert_eq(state.technique_cost(), 81)

func test_elemental_cost_scales_with_level():
	assert_eq(state.elemental_cost(), 100)
	state.elemental_level = 1
	assert_eq(state.elemental_cost(), 200)
	state.elemental_level = 2
	assert_eq(state.elemental_cost(), 400)

func test_ki_cost_scales_with_level():
	assert_eq(state.ki_cost(), 150)
	state.ki_level = 1
	assert_eq(state.ki_cost(), 330)
	state.ki_level = 2
	assert_eq(state.ki_cost(), 726)

func test_can_upgrade_strength_false_when_gold_insufficient():
	state.gold = 9
	assert_false(state.can_upgrade_strength())

func test_can_upgrade_strength_true_when_gold_sufficient():
	state.gold = 10
	assert_true(state.can_upgrade_strength())

func test_can_upgrade_elemental_false_without_skill_tree_even_with_gold():
	state.gold = 1000
	state.skill_tree_unlocked = false
	assert_false(state.can_upgrade_elemental())

func test_can_upgrade_elemental_true_with_skill_tree_and_gold():
	state.gold = 100
	state.skill_tree_unlocked = true
	assert_true(state.can_upgrade_elemental())

func test_can_upgrade_ki_false_without_skill_tree_even_with_gold():
	state.gold = 1000
	state.skill_tree_unlocked = false
	assert_false(state.can_upgrade_ki())

func test_can_upgrade_ki_true_with_skill_tree_and_gold():
	state.gold = 150
	state.skill_tree_unlocked = true
	assert_true(state.can_upgrade_ki())

func test_upgrade_strength_noop_when_unaffordable():
	state.gold = 5
	state.upgrade_strength()
	assert_eq(state.gold, 5)
	assert_eq(state.strength_level, 0)
	assert_eq(state.strength, 1.0)

func test_upgrade_strength_deducts_gold_and_updates_stat():
	state.gold = 10
	state.upgrade_strength()
	assert_eq(state.gold, 0)
	assert_eq(state.strength_level, 1)
	assert_eq(state.strength, 2.5)

func test_upgrade_speed_deducts_gold_and_updates_stat():
	state.gold = 15
	state.upgrade_speed()
	assert_eq(state.gold, 0)
	assert_eq(state.speed_level, 1)
	assert_eq(state.speed, 1.5)

func test_upgrade_technique_deducts_gold_and_updates_stat():
	state.gold = 25
	state.upgrade_technique()
	assert_eq(state.gold, 0)
	assert_eq(state.technique_level, 1)
	assert_almost_eq(state.technique, 0.10, 0.0001)

func test_upgrade_technique_caps_at_ninety_percent():
	state.gold = 100000000
	for i in range(20):
		state.upgrade_technique()
	assert_almost_eq(state.technique, 0.90, 0.0001)

func test_upgrade_elemental_noop_when_skill_tree_locked():
	state.gold = 1000
	state.skill_tree_unlocked = false
	state.upgrade_elemental()
	assert_eq(state.gold, 1000)
	assert_eq(state.elemental_level, 0)

func test_upgrade_elemental_deducts_gold_and_increments_level_when_unlocked():
	state.gold = 100
	state.skill_tree_unlocked = true
	state.upgrade_elemental()
	assert_eq(state.gold, 0)
	assert_eq(state.elemental_level, 1)

func test_upgrade_ki_noop_when_skill_tree_locked():
	state.gold = 1000
	state.skill_tree_unlocked = false
	state.upgrade_ki()
	assert_eq(state.gold, 1000)
	assert_eq(state.ki_level, 0)

func test_upgrade_ki_deducts_gold_and_increments_level_when_unlocked():
	state.gold = 150
	state.skill_tree_unlocked = true
	state.upgrade_ki()
	assert_eq(state.gold, 0)
	assert_eq(state.ki_level, 1)
