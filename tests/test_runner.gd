extends SceneTree

const SUITES := [
	"res://tests/unit/test_game_session.gd",
	"res://tests/unit/test_weather_catalog.gd",
	"res://tests/unit/test_project_resources.gd",
	"res://tests/unit/test_input_service.gd",
	"res://tests/unit/test_input_settings.gd",
	"res://tests/unit/test_display_preferences.gd",
	"res://tests/unit/test_audio_service.gd",
	"res://tests/unit/test_runtime_asset_catalog.gd",
	"res://tests/unit/test_opponent_schedule.gd",
	"res://tests/unit/test_tile_atlas.gd",
	"res://tests/unit/test_inventory_service.gd",
	"res://tests/unit/test_shipping_service.gd",
	"res://tests/unit/test_quest_service.gd",
	"res://tests/integration/test_vertical_slice_progression.gd",
	"res://tests/unit/test_brand_claims.gd",
	"res://tests/unit/test_brand_mastery.gd",
	"res://tests/unit/test_six_brand_powers.gd",
	"res://tests/unit/test_phase_one_services.gd",
	"res://tests/unit/test_game_preferences.gd",
	"res://tests/unit/test_basic_trail_ai.gd",
	"res://tests/unit/test_farm_service.gd",
	"res://tests/unit/test_crop_catalog.gd",
	"res://tests/unit/test_animal_care_service.gd",
	"res://tests/unit/test_fishing_session.gd",
	"res://tests/unit/test_fishing_gear_catalog.gd",
	"res://tests/unit/test_horse_travel_state.gd",
	"res://tests/unit/test_match_flow.gd",
	"res://tests/unit/test_match_wager.gd",
	"res://tests/unit/test_match_replay_explainer.gd",
	"res://tests/unit/test_trail_match_series.gd",
	"res://tests/unit/test_trail_hand_validator.gd",
	"res://tests/unit/test_wall_builder.gd",
	"res://tests/unit/test_frontier_rules.gd",
	"res://tests/unit/test_frontier_ai.gd",
	"res://tests/unit/test_phase_three_four_migration.gd",
	"res://tests/unit/test_phase_five_six.gd",
	"res://tests/unit/test_phase_seven_eight.gd",
	"res://tests/unit/test_player.gd",
	"res://tests/unit/test_tenderfoot_tutorial.gd",
	"res://tests/unit/test_tenderfoot_advisor.gd",
	"res://tests/unit/test_save_service.gd",
]


func _init() -> void:
	call_deferred("_run_suites")


func _run_suites() -> void:
	var failures: Array[String] = []
	for suite_path in SUITES:
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("Unable to load test suite: %s" % suite_path)
			continue
		var suite = suite_script.new()
		var suite_failures: Array = suite.run()
		for failure in suite_failures:
			failures.append("%s: %s" % [suite_path, failure])
	if failures.is_empty():
		print("All %d test suites passed." % SUITES.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
