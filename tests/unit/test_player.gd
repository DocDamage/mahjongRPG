extends RefCounted

const PlayerScript = preload("res://src/player/player.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var player = PlayerScript.new()
	var diagonal := player.velocity_from_direction(Vector2(1.0, 1.0))
	if not is_equal_approx(diagonal.length(), player.WALK_SPEED):
		failures.append("diagonal movement must be normalized")
	player.running = true
	if not is_equal_approx(player.velocity_from_direction(Vector2.RIGHT).length(), player.RUN_SPEED):
		failures.append("running should use the configured accelerated walk speed")
	player.free()
	return failures
