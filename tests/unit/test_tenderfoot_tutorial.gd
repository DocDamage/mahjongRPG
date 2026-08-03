extends RefCounted

const TenderfootTutorial = preload("res://src/mahjong/presentation/tenderfoot_tutorial.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var tutorial = TenderfootTutorial.new()
	if tutorial.lesson().get("title", "") != "Tile identities" or not tutorial.can_continue_manually():
		failures.append("Tenderfoot should start with an acknowledged tile-identity lesson")
	tutorial.advance()
	if tutorial.step != 1 or tutorial.record_action(&"draw"):
		failures.append("draw-and-discard lesson should wait for both actions")
	if not tutorial.record_action(&"discard") or tutorial.step != 2:
		failures.append("draw-and-discard lesson should advance after both actions")
	for ignored in TenderfootTutorial.LESSONS.size() - tutorial.step:
		tutorial.advance()
	if not tutorial.is_complete() or tutorial.advance():
		failures.append("Tenderfoot should clamp its progress at the final lesson")
	var resumed = TenderfootTutorial.new(999)
	if not resumed.is_complete():
		failures.append("saved tutorial progress should clamp safely")
	return failures
