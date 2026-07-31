extends GutTest

var GameStateScript = load("res://scripts/GameState.gd")
var state

func before_each():
	state = GameStateScript.new()
	add_child_autofree(state)

func test_air_stage_stays_air_below_threshold():
	for i in range(24):
		state.punch()
	assert_eq(state.stage, GameStateScript.Stage.AIR)
	assert_eq(state.air_punches, 24)

func test_air_stage_advances_to_hay_at_threshold():
	for i in range(25):
		state.punch()
	assert_eq(state.stage, GameStateScript.Stage.HAY)

func test_hay_destruction_advances_to_tree():
	state._apply_stage(GameStateScript.Stage.HAY)
	state.strength = 999999.0
	state.punch()
	assert_eq(state.stage, GameStateScript.Stage.TREE)
	assert_eq(state.target_hp, state.STAGE_HP[GameStateScript.Stage.TREE])

func test_tree_destruction_advances_to_stone_without_unlocking_skill_tree():
	state._apply_stage(GameStateScript.Stage.TREE)
	state.strength = 999999.0
	state.punch()
	assert_eq(state.stage, GameStateScript.Stage.STONE)
	assert_false(state.skill_tree_unlocked)

func test_stone_destruction_unlocks_skill_tree_and_advances_to_waterfall():
	state._apply_stage(GameStateScript.Stage.STONE)
	state.strength = 999999.0
	assert_false(state.skill_tree_unlocked)
	state.punch()
	assert_true(state.skill_tree_unlocked)
	assert_eq(state.stage, GameStateScript.Stage.WATERFALL)

func test_skill_tree_unlock_signal_emitted_once_on_stone_destruction():
	state._apply_stage(GameStateScript.Stage.STONE)
	state.strength = 999999.0
	watch_signals(state)
	state.punch()
	assert_signal_emit_count(state, "skill_tree_unlocked_signal", 1)

func test_skill_tree_unlock_signal_not_re_emitted_if_already_unlocked():
	state.skill_tree_unlocked = true
	state._apply_stage(GameStateScript.Stage.STONE)
	state.strength = 999999.0
	watch_signals(state)
	state.punch()
	assert_signal_emit_count(state, "skill_tree_unlocked_signal", 0)

func test_waterfall_stays_waterfall_below_threshold():
	state._apply_stage(GameStateScript.Stage.WATERFALL)
	for i in range(299):
		state.punch()
	assert_eq(state.stage, GameStateScript.Stage.WATERFALL)
	assert_eq(state.waterfall_punches, 299)

func test_waterfall_advances_to_sensei_at_threshold():
	state._apply_stage(GameStateScript.Stage.WATERFALL)
	for i in range(300):
		state.punch()
	assert_eq(state.stage, GameStateScript.Stage.SENSEI)

func test_sensei_defeat_sets_flag_without_advancing_stage():
	state._apply_stage(GameStateScript.Stage.SENSEI)
	state.strength = 999999.0
	state.punch()
	assert_true(state.sensei_defeated)
	assert_eq(state.stage, GameStateScript.Stage.SENSEI)
	assert_eq(state.target_hp, 0.0)

func test_sensei_punches_after_defeat_stay_at_zero_hp():
	state._apply_stage(GameStateScript.Stage.SENSEI)
	state.strength = 999999.0
	state.punch()
	state.punch()
	assert_true(state.sensei_defeated)
	assert_eq(state.stage, GameStateScript.Stage.SENSEI)
	assert_eq(state.target_hp, 0.0)
