extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { RESOLVE_PROPERTY, SCHEDULE_EVENT, ATTEND_EVENT, RESCHEDULE_EVENT, INSPECT_STATUS }

@export var action: Action
@export var target_id: StringName
@export var resolution_method: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("553d31"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("ffd78c"), false, 2.0)
	draw_circle(Vector2(0, -30), 8.0, Color("8fe0bd") if action == Action.ATTEND_EVENT else Color("f5a84c"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.RESOLVE_PROPERTY:
			var result: Error = GameSession.properties.resolve(target_id, resolution_method, GameSession.inventory)
			if result == OK:
				GameSession.public_life.sync_property_contributions(GameSession.properties)
				feedback.emit("%s is resolved. Its public contribution is now recorded at the Hall." % String(GameSession.properties.definitions[target_id].get("display_name", target_id)))
			else:
				feedback.emit("That property cannot be resolved by this route, or it has already been settled.")
		Action.SCHEDULE_EVENT:
			var result: Error = GameSession.public_life.schedule(target_id, GameSession.day, GameSession.properties, GameSession.community, GameSession.brands.hall_stage)
			feedback.emit("%s is scheduled for today. Return to the posted gathering to attend." % String(GameSession.public_life.definitions.get(target_id, {}).get("display_name", target_id)) if result == OK else "That public event still needs its listed disputes, contributions, Hall stage, or community support.")
		Action.ATTEND_EVENT:
			var result: Dictionary = GameSession.public_life.attend(target_id, GameSession.day)
			if result.has("error"):
				feedback.emit("Schedule this event first, then attend on or after its posted day.")
				return
			var hall_stage := int(result.get("hall_stage", 0))
			if hall_stage > GameSession.brands.hall_stage:
				GameSession.brands.unlock_hall_stage(hall_stage)
			var note := " Hall stage %d is restored." % hall_stage if hall_stage > 0 else ""
			feedback.emit("%s attended. Rank: %s.%s" % [String(GameSession.public_life.definitions[target_id].get("display_name", target_id)), String(result.get("rank_id", "tenderfoot")).capitalize(), note])
		Action.RESCHEDULE_EVENT:
			var result: Error = GameSession.public_life.reschedule(target_id, GameSession.day + 1)
			feedback.emit("The event has been rescheduled for tomorrow." if result == OK else "Only a currently scheduled event can be rescheduled.")
		Action.INSPECT_STATUS:
			feedback.emit("Public rank: %s • points: %d • property contributions: %d • Hall: %d/5." % [String(GameSession.public_life.rank_id).capitalize(), GameSession.public_life.rank_points, GameSession.public_life.contribution_total(), GameSession.brands.hall_stage])
