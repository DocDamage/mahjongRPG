extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 21.0, Color("28505c"))
	draw_circle(Vector2(0, -14), 15.0, Color("9fe3db"), false, 3.0)


func _on_interacted(_actor: Node2D) -> void:
	if not GameSession.postgame.is_active():
		feedback.emit("The advanced Hall table opens after the credits, so unfinished world play remains available.")
		return
	if not GameSession.public_life.is_scheduled(&"postgame_tournament"):
		var schedule: Error = GameSession.public_life.schedule(&"postgame_tournament", GameSession.day, GameSession.properties, GameSession.community, GameSession.brands.hall_stage)
		if schedule != OK:
			feedback.emit("The Hall Legends Tournament cannot be scheduled yet.")
			return
		feedback.emit("Hall Legends Tournament scheduled for today. Interact again to play its advanced Frontier table.")
		return
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	var table := MahjongTable.new()
	table.opponent_id = &"hall_legends"
	table.opponent_name = "Hall Legends"
	table.opponent_loadout = [&"purple", &"dark"]
	table.opponent_ai_profile = {"set_weight": 2.0, "run_weight": 1.65, "seen_tile_weight": 1.0}
	table.ruleset = MatchRuleset.FRONTIER
	table.match_closed.connect(_on_match_closed)
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("Hall Legends seated. This repeatable advanced table never removes your world progress.")


func _on_match_closed(winner: int) -> void:
	if winner != 0:
		feedback.emit("The Legends Tournament remains scheduled. Try again whenever you are ready.")
		return
	var result: Dictionary = GameSession.public_life.attend(&"postgame_tournament", GameSession.day, true)
	feedback.emit("Hall Legends win recorded. The repeatable tournament is available again." if not result.has("error") else "The tournament result could not be recorded.")
