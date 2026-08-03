extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -14), 23.0, Color("4e2132"))
	draw_circle(Vector2(0, -14), 16.0, Color("f0c978"), false, 3.0)


func _on_interacted(_actor: Node2D) -> void:
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	if GameSession.finale.phase == &"unstarted":
		if GameSession.finale.begin_championship(GameSession.story, GameSession.public_life) != OK:
			feedback.emit("The final table remains gated by the warning, allies, Hall reopening, and scheduled championship.")
			return
	if GameSession.finale.phase == &"championship" and not GameSession.finale.pre_finale_checkpoint_captured:
		if SaveService.save_pre_finale() != OK or GameSession.finale.confirm_pre_finale_checkpoint() != OK:
			feedback.emit("The dedicated pre-finale backup could not be saved. The championship will not seat; try again after checking save storage.")
			return
	if not GameSession.finale.can_start_championship_table():
		feedback.emit("Texas King can only be seated after the dedicated pre-finale backup is safely captured.")
		return
	var opponent: Dictionary = GameSession.finale.opponent()
	var table := MahjongTable.new()
	table.opponent_id = &"texas_king"
	table.opponent_name = String(opponent.get("display_name", "Texas King"))
	table.opponent_loadout = [&"dark", &"purple"]
	table.opponent_ai_profile = opponent.get("ai", {}).duplicate(true)
	table.ruleset = MatchRuleset.FRONTIER
	table.match_closed.connect(_on_match_closed)
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	AudioService.play_catalog_event(&"finale_challenge")
	feedback.emit("Texas King sits. Frontier Rules apply; the exposed counter-Deed and truthful declared category keep this final table legal and counterable.")


func _on_match_closed(winner: int) -> void:
	if winner != 0:
		GameSession.finale.record_championship_result(false, GameSession.public_life, GameSession.day)
		feedback.emit("Texas King holds the table, but the championship remains seated. Retry without losing the pre-finale backup.")
		return
	if GameSession.finale.record_championship_result(true, GameSession.public_life, GameSession.day) != OK:
		feedback.emit("The final result could not be recorded; the scheduled championship remains protected.")
		return
	GameSession.brands.record_match_win(&"texas_king", MatchRuleset.FRONTIER)
	AudioService.play_catalog_event(&"finale_victory")
	SaveService.autosave(&"texas_king_defeated")
	feedback.emit("Texas King is defeated. Go to King's Reach for the standoff; a failed dialogue choice can retry there without replaying Mahjong.")
