extends SceneTree

const SUITES := [
	"res://tests/unit/test_game_session.gd",
	"res://tests/unit/test_input_service.gd",
	"res://tests/unit/test_brand_claims.gd",
	"res://tests/unit/test_match_flow.gd",
	"res://tests/unit/test_trail_hand_validator.gd",
	"res://tests/unit/test_wall_builder.gd",
	"res://tests/unit/test_player.gd",
	"res://tests/unit/test_save_service.gd",
]


func _init() -> void:
	_run_suites()


func _run_suites() -> void:
	var failures: Array[String] = []
	for suite_path in SUITES:
		var suite_script = load(suite_path)
		if suite_script == null:
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
