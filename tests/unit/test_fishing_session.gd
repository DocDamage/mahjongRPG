extends RefCounted

const FishDefinition = preload("res://src/fishing/fish_definition.gd")
const FishingSession = preload("res://src/fishing/fishing_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var fish_definitions: Array = [FishDefinition.new({"id": "test_fish", "difficulty": 0.1, "sell_value_cents": 100, "hours": [6, 20], "weather": ["clear"]})]
	var session = FishingSession.new(44)
	if session.cast(fish_definitions, 8, &"clear") != OK:
		failures.append("eligible fish should cast successfully")
	session.tick(0.1)
	session.tick(3.0)
	if session.state != FishingSession.State.BITE:
		failures.append("a cast should progress through wait into bite")
	if session.hook_set() != OK or session.state != FishingSession.State.STRUGGLE:
		failures.append("a bite should enter struggle only after a legal hook set")
	for ignored in 20:
		if session.state == FishingSession.State.CATCH:
			break
		session.apply_struggle_input(session.target_direction, true, false, 0.25)
	if session.state != FishingSession.State.CATCH:
		failures.append("controlled reeling should be able to catch a low-difficulty fish")
	if session.present_result() != OK or session.cleanup() != OK:
		failures.append("catch result should advance through presentation and cleanup")
	var escape_session = FishingSession.new(45)
	escape_session.cast(fish_definitions, 8, &"clear")
	escape_session.tick(0.1)
	escape_session.tick(3.0)
	escape_session.hook_set()
	escape_session.apply_struggle_input(0.0, true, false, 10.0)
	if escape_session.state != FishingSession.State.ESCAPE:
		failures.append("excessive tension should escape the fish without losing gear")
	return failures
