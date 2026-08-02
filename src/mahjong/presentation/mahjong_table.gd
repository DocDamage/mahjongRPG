extends Control

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const TrailHandValidator = preload("res://src/mahjong/domain/trail_hand_validator.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")

var flow
var status_label: Label
var action_box: HBoxContainer
var tiles_box: HBoxContainer
var result_label: Label
var _ai_turn_pending := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameSession.request_pause(&"mahjong")
	flow = MatchFlow.new(GameSession.seed + GameSession.day * 100 + GameSession.minute_of_day)
	flow.start_match()
	_build_ui()
	_refresh()


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
	title.text = "SIX BRANDS • TRAIL RULES"
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
	_clear(action_box)
	_clear(tiles_box)
	status_label.text = "%s Hand  •  Renown: Doc %d — Opponent %d  •  Wall: %d\nOpponent has %d concealed tile(s), %d open group(s)." % [flow.hand_name().capitalize(), flow.renown[0], flow.renown[1], flow.wall.size(), flow.hands[1].size(), flow.open_groups[1].size()]
	result_label.text = ""
	if flow.phase == MatchFlow.Phase.MATCH_COMPLETE:
		result_label.text = "Match complete. %s" % ("Doc wins!" if flow.match_winner == 0 else "Opponent wins." if flow.match_winner == 1 else "The match ends tied.")
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
	if flow.phase == MatchFlow.Phase.DRAW:
		result_label.text = "Your turn: draw, or declare High Noon if this is a waiting hand."
		_add_action("Draw", _draw_player)
		_add_action("Declare High Noon", _declare_high_noon)
		return
	result_label.text = "Your turn: choose one tile to discard."
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
	_refresh()


func _declare_high_noon() -> void:
	if flow.declare_high_noon() != OK:
		result_label.text = "High Noon is available only with a valid one-tile wait."
		return
	_refresh()


func _discard_player(tile_index: int) -> void:
	flow.discard_at(tile_index)
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
	GameSession.complete_mahjong_match()
	queue_free()


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
