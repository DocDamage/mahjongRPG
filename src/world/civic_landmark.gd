extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { TALK, RESOLVE_PROPERTY, HALL_PRACTICE, DISCOVER_CLUE }

@export var action: Action
@export var target_id: StringName
@export var relationship_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("496471"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("f0d08c"), false, 2.0)
	draw_circle(Vector2(0, -31), 8.0, Color("f5c45e") if action == Action.DISCOVER_CLUE else Color("9fc4b6"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.TALK:
			var choice_id := StringName("%s_welcome" % relationship_id)
			GameSession.relationships.record_choice(choice_id, relationship_id, 1)
			feedback.emit(GameSession.relationships.dialogue_line(relationship_id))
		Action.RESOLVE_PROPERTY:
			var result: Error = GameSession.properties.resolve(target_id, &"quest", GameSession.inventory)
			if result == OK:
				GameSession.brands.unlock_hall_stage(3)
				feedback.emit("The petition settles the property dispute. Ironhook's road and the Hall practice stage are open.")
			else:
				feedback.emit("Bring one artisan cheese to file the petition, or defeat Registrar Elise at her table.")
		Action.HALL_PRACTICE:
			if GameSession.brands.hall_stage < 3:
				feedback.emit("The practice stage needs the Landing Depot dispute resolved first.")
			else:
				feedback.emit("Hall practice stage restored: civic cases may now be settled by a legal Frontier Rules match.")
		Action.DISCOVER_CLUE:
			var result: Error = GameSession.evidence.discover(target_id)
			feedback.emit("The government record joins your evidence journal." if result == OK else "That government record is already in your journal.")
