extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

const QUEST_ID := &"first_lantern"


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 12.0, Color("e7c28f"))
	draw_rect(Rect2(-16, -2, 32, 30), Color("7a4b78"))
	draw_rect(Rect2(-18, -30, 36, 8), Color("32231f"))
	draw_circle(Vector2(-6, -14), 2.0, Color("33251c"))
	draw_circle(Vector2(6, -14), 2.0, Color("33251c"))


func _on_interacted(_actor: Node2D) -> void:
	if GameSession.quests.completed.has(QUEST_ID):
		feedback.emit("Mabel keeps the first lantern bright. Helper unlocked: Mabel.")
		return
	if not GameSession.quests.is_active(QUEST_ID):
		GameSession.quests.start(QUEST_ID)
		feedback.emit("Mabel: Bring one bean crop and any fish. We'll light the hall's first lantern.")
		return
	var bean_count: int = GameSession.quests.requirement_count(QUEST_ID, GameSession.inventory, &"crop_beans")
	var fish_count: int = GameSession.quests.requirement_count(QUEST_ID, GameSession.inventory, &"any_fish")
	if bean_count < 1 or fish_count < 1:
		feedback.emit("Mabel: I still need one bean crop and any fish. Beans: %d, fish: %d." % [bean_count, fish_count])
		return
	GameSession.inventory.remove_item(&"crop_beans")
	_remove_one_fish()
	if GameSession.quests.complete(QUEST_ID) == OK:
		feedback.emit("The first lantern shines. Mabel joins Wayward Farm, and the Six Brands Hall begins to return.")


func _remove_one_fish() -> void:
	for key_value in GameSession.inventory.items.keys():
		var item_id := StringName(key_value)
		if String(item_id).begins_with("fish_"):
			GameSession.inventory.remove_item(item_id)
			return
