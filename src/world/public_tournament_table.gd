extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 21.0, Color("694d35"))
	draw_circle(Vector2(0, -14), 15.0, Color("d8bc74"), false, 3.0)


func _on_interacted(_actor: Node2D) -> void:
	if not GameSession.public_life.is_scheduled(&"town_tournament"):
		feedback.emit("Schedule the Town Tournament at the Hall ledger before taking a seat.")
		return
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	var table := MahjongTable.new()
	table.opponent_id = &"town_tournament"
	table.opponent_name = "Mercy's Wake Finalist"
	table.opponent_loadout = [&"dark", &"purple"]
	table.opponent_ai_profile = {"set_weight": 1.45, "run_weight": 1.15, "seen_tile_weight": 0.7}
	table.ruleset = MatchRuleset.FRONTIER
	table.match_closed.connect(_on_match_closed)
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("Town Tournament seated. Win this public Frontier Rules match to restore Hall stage four.")


func _on_match_closed(winner: int) -> void:
	if winner != 0:
		feedback.emit("The tournament remains scheduled. You may retry the public table or reschedule the event.")
		return
	var result: Dictionary = GameSession.public_life.attend(&"town_tournament", GameSession.day, true)
	if result.has("error"):
		feedback.emit("The tournament result could not be recorded; its schedule remains intact.")
		return
	if int(result.get("hall_stage", 0)) > GameSession.brands.hall_stage:
		GameSession.brands.unlock_hall_stage(int(result["hall_stage"]))
	feedback.emit("Public tournament won. Hall stage four opens, and your rank is now %s." % String(result.get("rank_id", "tenderfoot")).capitalize())
