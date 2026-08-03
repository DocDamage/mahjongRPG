extends "res://src/interaction/world_interactable.gd"

const CommunityDialogueFlow = preload("res://src/dialogue/community_dialogue_flow.gd")

signal feedback(message: String)

enum Action { ADVANCE_ARC, DISCOVER_SECRET }

@export var action: Action
@export var arc_id: StringName
var _dialogue_flow


func _ready() -> void:

	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:

	draw_rect(Rect2(-27, -23, 54, 46), Color("5b4432"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("f0d08c"), false, 2.0)
	draw_circle(Vector2(0, -29), 8.0, Color("b9e2c3") if action == Action.DISCOVER_SECRET else Color("f5c45e"))


func _on_interacted(_actor: Node2D) -> void:

	if action == Action.DISCOVER_SECRET:
		var secret_result: int = GameSession.community.discover_secret(arc_id)
		feedback.emit("A community secret joins your journal." if secret_result == OK else "Resolve this resident's arc before examining their keepsake.")
		return
	if not GameSession.community.expected_dialogue_sequence(arc_id).is_empty():
		if _dialogue_flow != null:
			return
		_dialogue_flow = CommunityDialogueFlow.new()
		add_child(_dialogue_flow)
		_dialogue_flow.finished.connect(_on_dialogue_finished)
		if _dialogue_flow.start(arc_id) != OK:
			_dialogue_flow.queue_free()
			_dialogue_flow = null
			feedback.emit("That authored conversation is unavailable.")
		return
	var result: Dictionary = GameSession.community.advance(arc_id, GameSession.community.expected_action(arc_id), GameSession.relationships, GameSession.helpers)
	feedback.emit(String(result.get("message", "That arc is already resolved.")))


func _on_dialogue_finished(message: String) -> void:
	var completed_flow = _dialogue_flow
	_dialogue_flow = null
	if completed_flow != null:
		completed_flow.queue_free()
	feedback.emit(message)
