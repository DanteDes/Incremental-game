extends GutTest

var GameStateScript = load("res://scripts/GameState.gd")
var state

func before_each():
	state = GameStateScript.new()
	add_child_autofree(state)

func test_air_stage_awards_flat_gold_regardless_of_damage():
	for i in range(5):
		state.punch()
	assert_eq(state.gold, 5)

func test_non_air_stage_awards_gold_from_damage_formula():
	state._apply_stage(GameStateScript.Stage.HAY)
	state.strength = 40.0
	state.technique = 0.0
	state.punch()
	assert_eq(state.gold, 10)

func test_non_air_stage_gold_floors_at_one():
	state._apply_stage(GameStateScript.Stage.HAY)
	state.strength = 2.0
	state.technique = 0.0
	state.punch()
	assert_eq(state.gold, 1)

func test_destroying_target_adds_stage_bonus_gold():
	state._apply_stage(GameStateScript.Stage.HAY)
	state.strength = 999999.0
	state.technique = 0.0
	state.punch()
	assert_eq(state.gold, 250059)

func test_gold_changed_signal_emitted_on_punch():
	watch_signals(state)
	state.punch()
	assert_signal_emit_count(state, "gold_changed", 1)

func test_stage_changed_signal_emitted_on_advance():
	for i in range(24):
		state.punch()
	watch_signals(state)
	state.punch()
	assert_signal_emitted_with_parameters(state, "stage_changed", [GameStateScript.Stage.HAY])
