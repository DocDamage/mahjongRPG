extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

const QUEST_ID := &"first_lantern"
const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")


func _ready() -> void:
	interacted.connect(_on_interacted)
	GameSession.quests.quest_completed.connect(_on_quest_completed)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-16, -2, 32, 30), Color("7a4b78"))
	draw_rect(Rect2(-18, -30, 36, 8), Color("32231f"))
	draw_circle(Vector2(-6, -14), 2.0, Color("33251c"))
	draw_circle(Vector2(6, -14), 2.0, Color("33251c"))
	if GameSession.quests.completed.has(QUEST_ID):
		draw_circle(Vector2(0, -50), 11.0, Color("f5c45e", 0.25))
		draw_rect(Rect2(-4, -58, 8, 16), Color("f3b648"))
		draw_circle(Vector2(0, -50), 4.0, Color("fff1ae"))


func _on_interacted(_actor: Node2D) -> void:
	if GameSession.quests.completed.has(QUEST_ID):
		feedback.emit(DialogueCatalog.text(&"first_lantern.after"))
		return
	if not GameSession.quests.is_active(QUEST_ID):
		GameSession.quests.start(QUEST_ID)
		GameSession.quests.advance(QUEST_ID)
		feedback.emit("%s\n%s" % [DialogueCatalog.text(&"first_lantern.intro"), DialogueCatalog.text(&"first_lantern.gather")])
		return
	if GameSession.quests.stage(QUEST_ID) == 2:
		_complete_lantern()
		return
	var bean_count: int = GameSession.quests.requirement_count(QUEST_ID, GameSession.inventory, &"crop_beans")
	var fish_count: int = GameSession.quests.requirement_count(QUEST_ID, GameSession.inventory, &"any_fish")
	if bean_count < 1 or fish_count < 1:
		feedback.emit(DialogueCatalog.text(&"first_lantern.missing", {"beans": bean_count, "fish": fish_count}))
		return
	GameSession.inventory.remove_item(&"crop_beans")
	_remove_one_fish()
	GameSession.quests.advance(QUEST_ID)
	feedback.emit(DialogueCatalog.text(&"first_lantern.delivery"))


func _remove_one_fish() -> void:
	for key_value in GameSession.inventory.items.keys():
		var item_id := StringName(key_value)
		if String(item_id).begins_with("fish_"):
			GameSession.inventory.remove_item(item_id)
			return


func _complete_lantern() -> void:
	if GameSession.quests.complete(QUEST_ID) != OK:
		return
	var save_result: Error = SaveService.autosave(&"quest_completion")
	var completion_text := DialogueCatalog.text(&"first_lantern.complete")
	feedback.emit("%s%s" % [completion_text, " Autosaved." if save_result == OK else ""])
	queue_redraw()


func _on_quest_completed(quest_id: StringName) -> void:
	if quest_id == QUEST_ID:
		queue_redraw()
