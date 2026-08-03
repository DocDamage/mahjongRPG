extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { SURVIVE_ROUTE, RECORD_SUPERNATURAL, RECOVER_CLUE, RESOLVE_ACCESS, DISCOVER_SECRET }

@export var action: Action
@export var target_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("7c4931"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("e5b66b"), false, 2.0)
	draw_circle(Vector2(0, -28), 8.0, Color("e9dc9a") if action == Action.RECORD_SUPERNATURAL else Color("da6a36"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.SURVIVE_ROUTE:
			feedback.emit("You survive the %s and chart the route." % String(GameSession.weather_id).replace("_", " ") if GameSession.desert.survive_route(target_id, GameSession.weather_id) == OK else "This desert route only opens during dust wind or supernatural fog; rest and watch the forecast.")
		Action.RECORD_SUPERNATURAL:
			feedback.emit("Supernatural record added to the journal." if GameSession.desert.record_supernatural(target_id) == OK else "That supernatural record is already cataloged.")
		Action.RECOVER_CLUE:
			var added: int = GameSession.evidence.discover(target_id)
			GameSession.desert.recover_clue(target_id)
			feedback.emit("Texas King's rule clue recovered: counter the declared category with an exposed conflicting Deed." if added == OK else "That final-rule clue is already in your journal.")
		Action.RESOLVE_ACCESS:
			if not GameSession.desert.route_survived(&"red_testament_windward_pass"):
				feedback.emit("Chart Windward Pass in dust wind or supernatural fog before filing the expedition right.")
			else:
				feedback.emit("Expedition access recorded." if GameSession.properties.resolve(target_id, &"clue") == OK else "The desert expedition access is already recorded.")
		Action.DISCOVER_SECRET:
			feedback.emit("Red Testament secret recorded." if GameSession.desert.discover_secret(target_id) == OK else "That desert secret is already in your journal.")
