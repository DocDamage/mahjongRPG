extends Control

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")
const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MatchWager = preload("res://src/mahjong/domain/match_wager.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const TenderfootTutorial = preload("res://src/mahjong/presentation/tenderfoot_tutorial.gd")
const TenderfootUndo = preload("res://src/mahjong/presentation/tenderfoot_undo.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")

var flow
var opponent_name := "Trailhand"
var opponent_loadout: Array[StringName] = [&"dark", &"green"]
var status_label: Label
var action_box: HBoxContainer
var tiles_box: HBoxContainer
var result_label: Label
var tutorial_label: Label
var tutorial_button: Button
var tutorial
var undo
var wager_tier: StringName = &"friendly"
var _match_started := false
var _ai_turn_pending := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameSession.request_pause(&"mahjong")
	tutorial = TenderfootTutorial.new(GameSession.tutorial_step(&"tenderfoot"))
	undo = TenderfootUndo.new()
	_build_ui()
	_show_wager_selection()

func _exit_tree() -> void:
	GameSession.release_pause(&"mahjong")

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.055, 0.035, 0.96)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-430, -220)
	panel.size = Vector2(860, 440)
	panel.add_theme_constant_override("separation", 12)
	add_child(panel)
	var title := Label.new()
	title.text = "SIX BRANDS • TRAIL RULES vs %s" % opponent_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(status_label)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(result_label)
	tutorial_label = Label.new()
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_color_override("font_color", Color("f4d08b"))
	panel.add_child(tutorial_label)
	tutorial_button = Button.new()
	tutorial_button.pressed.connect(_advance_tutorial)
	panel.add_child(tutorial_button)
	var divider := HSeparator.new()
	panel.add_child(divider)
	tiles_box = HBoxContainer.new()
	tiles_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(tiles_box)
	action_box = HBoxContainer.new()
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	action_box.add_theme_constant_override("separation", 16)
	panel.add_child(action_box)
	var help := Label.new()
	help.text = "Your tiles are face-up. Select a tile to discard. The opponent only uses its hand and public discards."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(help)

func _refresh() -> void:
	if not _match_started:
		_show_wager_selection()
		return
	_clear(action_box)
	_clear(tiles_box)
	status_label.text = "%s Hand  •  %s wager  •  Renown: Doc %d — %s %d  •  Wall: %d\n%s has %d concealed tile(s), %d open group(s)." % [flow.hand_name().capitalize(), MatchWager.label(wager_tier), flow.renown[0], opponent_name, flow.renown[1], flow.wall.size(), opponent_name, flow.hands[1].size(), flow.open_groups[1].size()]
	_refresh_tutorial()
	result_label.text = ""
	if flow.phase == MatchFlow.Phase.MATCH_COMPLETE:
		result_label.text = "Match complete. %s" % _match_outcome_text()
		_add_action("Return to farm", _close_match)
		return
	if flow.phase in [MatchFlow.Phase.COMPLETE, MatchFlow.Phase.EXHAUSTED]:
		var last: Dictionary = flow.hand_results.back()
		result_label.text = "%s: %s. Renown awarded: %d." % [flow.hand_name().capitalize(), "wall exhausted" if int(last["winner"]) < 0 else ("Doc won" if int(last["winner"]) == 0 else "Opponent won"), int(last["award"]["total"])]
		_add_action("Continue match", _advance_match)
		return
	if flow.turn_player == 1:
		result_label.text = "Opponent is considering only visible information…"
		if not _ai_turn_pending:
			_ai_turn_pending = true
			call_deferred("_take_ai_turn")
		return
	undo.begin_turn(flow)
	if undo.can_undo():
		_add_action("Undo turn", _undo_turn)
	if flow.phase == MatchFlow.Phase.DRAW:
		result_label.text = "Your turn: draw, or declare High Noon if this is a waiting hand."
		_add_action("Draw", _draw_player)
		_add_action("Declare High Noon", _declare_high_noon)
		if flow.brand_state(0).activations(&"blue") > 0:
			_add_action("Blue: reclaim latest discard", _activate_blue)
		var blue_claim := _first_claim_indices(&"blue_run")
		if not blue_claim.is_empty():
			_add_action("Blue: claim Run", _claim_brand.bind(&"blue_run", blue_claim[0], blue_claim[1]))
		var orange_claim := _first_claim_indices(&"orange_group")
		if not orange_claim.is_empty():
			_add_action("Orange: claim group", _claim_brand.bind(&"orange_group", orange_claim[0], orange_claim[1]))
		return
	result_label.text = "Your turn: choose one tile to discard."
	if TrailHandValidator.is_winning_hand(flow.combined_hand(0)):
		_add_action("Declare Trail Rules win", _declare_win)
	if flow.brand_state(0).activations(&"orange") > 0:
		_add_action("Orange: draw two, keep first", _activate_orange)
	for tile_index in flow.hands[0].size():
		var tile: Variant = flow.hands[0][tile_index]
		var button := Button.new()
		button.text = _tile_label(tile)
		button.tooltip_text = "Discard %s" % tile.key()
		button.custom_minimum_size = Vector2(66, 86)
		button.pressed.connect(_discard_player.bind(tile_index))
		tiles_box.add_child(button)

func _draw_player() -> void:
	flow.draw()
	undo.record_player_action()
	_record_tutorial_action(&"draw")
	_refresh()
func _declare_high_noon() -> void:
	if flow.declare_high_noon() != OK:
		result_label.text = "High Noon is available only with a valid one-tile wait."
		return
	_record_tutorial_action(&"high_noon")
	undo.record_player_action()
	_refresh()
func _activate_orange() -> void:
	if flow.activate_orange(0) != OK:
		result_label.text = "Orange needs a stored activation and two tiles left in the wall."
		return
	_record_tutorial_action(&"orange")
	undo.record_player_action()
	_refresh()
func _activate_blue() -> void:
	if flow.activate_blue(0) != OK:
		result_label.text = "Blue can reclaim one of your two latest discards when available."
		return
	_record_tutorial_action(&"blue")
	undo.record_player_action()
	_refresh()
func _claim_brand(kind: StringName, first_index: int, second_index: int) -> void:
	if flow.claim_brand_group_from_last_discard(0, kind, [first_index, second_index]) != OK:
		result_label.text = "That Brand claim is no longer legal."
		return
	undo.record_player_action()
	_refresh()
func _discard_player(tile_index: int) -> void:
	flow.discard_at(tile_index)
	undo.record_player_action()
	_record_tutorial_action(&"discard")
	_refresh()
func _declare_win() -> void:
	if flow.declare_win() != OK:
		result_label.text = "This hand is not a legal Trail Rules win."
		return
	_refresh()
func _undo_turn() -> void:
	var restored: Variant = undo.restore()
	if restored == null:
		result_label.text = "No turn action is available to undo."
		return
	flow = restored
	_refresh()
func _take_ai_turn() -> void:
	_ai_turn_pending = false
	if flow.phase != MatchFlow.Phase.DRAW or flow.turn_player != 1:
		_refresh()
		return
	flow.draw()
	if flow.phase == MatchFlow.Phase.DISCARD:
		if TrailHandValidator.is_winning_hand(flow.combined_hand(1)):
			flow.declare_win()
		else:
			var knowledge := VisibleKnowledge.new()
			for entry in flow.discard_river:
				knowledge.observe_discard(int(entry["player"]), entry["tile"])
			var decision: Dictionary = BasicTrailAi.new().choose_discard_index(flow.hands[1], knowledge)
			flow.discard_at(int(decision.get("index", 0)))
	_refresh()
func _advance_match() -> void:
	flow.advance_match()
	_refresh()
func _close_match() -> void:
	if _match_started:
		MatchWager.settle(GameSession.inventory, wager_tier, flow.match_winner)
	GameSession.complete_mahjong_match()
	queue_free()
func _show_wager_selection() -> void:
	_clear(action_box)
	_clear(tiles_box)
	status_label.text = "Choose the table terms with %s. You have $%.2f available." % [opponent_name, GameSession.inventory.money_cents / 100.0]
	result_label.text = "Friendly matches have no cash stake. Serious and High Stakes losses deduct cash only after the final result."
	tutorial_label.text = tutorial.progress_text()
	tutorial_button.visible = false
	for tier in MatchWager.TERMS:
		var stake := MatchWager.stake_cents(tier)
		var label := "%s — %s" % [MatchWager.label(tier), "no cash" if stake == 0 else "$%.2f" % (stake / 100.0)]
		_add_action(label, _start_match.bind(StringName(tier)))
func _start_match(next_wager_tier: StringName) -> void:
	if not MatchWager.can_start(next_wager_tier, GameSession.inventory.money_cents):
		result_label.text = "You need $%.2f available for that wager." % (MatchWager.stake_cents(next_wager_tier) / 100.0)
		return
	wager_tier = next_wager_tier
	flow = MatchFlow.new(GameSession.seed + GameSession.day * 100 + GameSession.minute_of_day)
	flow.configure_loadouts([&"orange", &"blue"], opponent_loadout)
	flow.start_match()
	_match_started = true
	_refresh()
func _match_outcome_text() -> String:
	var outcome := "Doc wins!" if flow.match_winner == 0 else "Opponent wins." if flow.match_winner == 1 else "The match ends tied."
	var stake := MatchWager.stake_cents(wager_tier)
	if stake == 0 or flow.match_winner < 0:
		return outcome
	return "%s %s $%.2f settles when you return to the world." % [outcome, "You win" if flow.match_winner == 0 else "You lose", stake / 100.0]
func _add_action(text_value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(150, 42)
	button.pressed.connect(callback)
	action_box.add_child(button)
func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
func _tile_label(tile) -> String:
	var suit := String(tile.identity.suit).substr(0, 1).to_upper()
	var rank := str(tile.identity.rank) if tile.identity.is_numbered() else String(tile.identity.suit).substr(0, 1).to_upper()
	return "%s%s\n%s" % [rank, suit, String(tile.brand).substr(0, 1).to_upper()]
func _refresh_tutorial() -> void:
	tutorial_label.text = tutorial.progress_text()
	tutorial_button.visible = not tutorial.is_complete()
	if tutorial_button.visible:
		tutorial_button.text = "Continue lesson" if tutorial.can_continue_manually() else "Draw, then discard to continue"
func _advance_tutorial() -> void:
	if tutorial.advance():
		GameSession.set_tutorial_step(&"tenderfoot", tutorial.step)
	_refresh()
func _record_tutorial_action(action: StringName) -> void:
	if tutorial.record_action(action):
		GameSession.set_tutorial_step(&"tenderfoot", tutorial.step)
func _first_claim_indices(kind: StringName) -> Array[int]:
	if flow.turn_player != 0 or flow.phase != MatchFlow.Phase.DRAW or flow.discard_river.is_empty():
		return []
	var discard: Dictionary = flow.discard_river.back()
	if int(discard.get("player", -1)) == 0 or bool(discard.get("claimed", false)):
		return []
	var tile: Variant = discard.get("tile")
	for first_index in flow.hands[0].size():
		for second_index in range(first_index + 1, flow.hands[0].size()):
			var claim := {"player": 0, "kind": String(kind), "equipped": flow.brand_state(0).equipped, "tiles": [flow.hands[0][first_index], flow.hands[0][second_index]]}
			var resolved := ClaimResolver.resolve(tile, [claim])
			if not resolved.is_empty():
				return [first_index, second_index]
	return []
