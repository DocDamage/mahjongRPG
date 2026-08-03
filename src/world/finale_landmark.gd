extends "res://src/interaction/world_interactable.gd"

const CreditsRoll = preload("res://src/ui/credits_roll.gd")

signal feedback(message: String)

enum Action { YIELD_TO_CLAIM, SPEAK_TRUTH, END_REIGN, RETRY_STANDOFF, SHOW_CREDITS, REVIEW_SUMMARY }

@export var action: Action


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("542c34"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("ffd78c"), false, 2.0)
	draw_circle(Vector2(0, -30), 8.0, Color("f0c978"))


func _on_interacted(_actor: Node2D) -> void:
	if action == Action.RETRY_STANDOFF:
		feedback.emit("The standoff is reset locally. Choose how to answer the King; Mahjong is already complete." if GameSession.finale.retry_standoff() == OK else "There is no failed standoff to retry.")
		return
	if action == Action.SHOW_CREDITS:
		if GameSession.finale.phase != &"ending":
			feedback.emit("Earn an ending before the credits can roll.")
			return
		var credits := CreditsRoll.new()
		get_tree().root.add_child(credits)
		feedback.emit("Credits are rolling. Continue from the accessible button to enter postgame.")
		return
	if action == Action.REVIEW_SUMMARY:
		var summary: Dictionary = GameSession.finale.ending_summary()
		feedback.emit("%s — %s" % [String(summary.get("title", "Ending pending")), String(summary.get("category", ""))])
		return
	var response := _response_for_action()
	var result: Error = GameSession.finale.resolve_standoff(response, GameSession.story)
	if result == OK:
		var ending: Dictionary = GameSession.finale.ending_summary()
		feedback.emit("%s. %s %s" % [String(ending["title"]), String(ending["father_reveal"]), String(ending["silas_return"])])
	elif action == Action.YIELD_TO_CLAIM and GameSession.finale.can_retry_standoff():
		feedback.emit("The King nearly binds the claim again. Retry the standoff here; the championship win is safely preserved.")
	else:
		feedback.emit("The standoff is not ready. Defeat Texas King first, then answer from the evidence you uncovered.")


func _response_for_action() -> StringName:
	if action == Action.YIELD_TO_CLAIM:
		return &"yield_to_claim"
	if action == Action.SPEAK_TRUTH:
		return &"speak_truth"
	return &"end_reign"
