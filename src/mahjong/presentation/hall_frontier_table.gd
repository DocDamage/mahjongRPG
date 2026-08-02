extends "res://src/interaction/world_interactable.gd"

const MahjongTable = preload("res://src/mahjong/presentation/mahjong_table.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")

signal feedback(message: String)


func _ready() -> void:
	interacted.connect(_on_interacted)
	_update_prompt()


func _on_interacted(_actor: Node2D) -> void:
	if not GameSession.quests.completed.has(&"first_lantern"):
		feedback.emit("Mabel must restore the First Lantern before the Hall can reopen its tables.")
		return
	if not GameSession.brands.can_play_frontier():
		feedback.emit("Hall cleanup needs one winning rematch against Mayor Bell, River Rose, and Dynamite Bill. The three mastery Brands will reopen this table.")
		return
	if get_tree().get_first_node_in_group(&"mahjong_table_overlay") != null:
		return
	var table := MahjongTable.new()
	table.opponent_id = &"hall_frontier"
	table.opponent_name = "Frontier Marshal"
	table.opponent_loadout = [&"dark", &"purple"]
	table.opponent_ai_profile = {"set_weight": 1.6, "run_weight": 1.0, "seen_tile_weight": 0.55}
	table.ruleset = MatchRuleset.FRONTIER
	table.add_to_group(&"mahjong_table_overlay")
	get_tree().root.add_child(table)
	feedback.emit("The reopened table teaches Frontier Rules: a 136-tile wall, 14-tile hands, and legal quads.")


func _update_prompt() -> void:
	prompt_text = "Play Frontier Rules" if GameSession.brands.can_play_frontier() else "Inspect Hall cleanup"
