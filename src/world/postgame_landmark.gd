extends "res://src/interaction/world_interactable.gd"

const JournalSummary = preload("res://src/journal/journal_summary.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("294e52"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("9fe3db"), false, 2.0)
	draw_circle(Vector2(0, -30), 8.0, Color("f0c978"))


func _on_interacted(_actor: Node2D) -> void:
	if not GameSession.postgame.is_active():
		feedback.emit("This completion ledger opens after credits. Your pre-finale world remains safely available in the dedicated backup.")
		return
	var ending: Dictionary = GameSession.finale.ending_summary()
	var collections: Dictionary = GameSession.postgame.collection_summary(GameSession)
	var progress := JournalSummary.concise_lines(GameSession)
	feedback.emit("Postgame • %s • %s • Journal: %s. Farm, animals, fishing, King's Reach, and unfinished arcs remain available." % [String(ending.get("title", "earned ending")), String(ending.get("category", "")), " • ".join(progress)])
