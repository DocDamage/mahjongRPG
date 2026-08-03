extends Control

const BasicTrailAi = preload("res://src/mahjong/ai/basic_trail_ai.gd")
const ClaimResolver = preload("res://src/mahjong/domain/claim_resolver.gd")
const FrontierAi = preload("res://src/mahjong/ai/frontier_ai.gd")
const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MatchRuleset = preload("res://src/mahjong/domain/match_ruleset.gd")
const MatchWager = preload("res://src/mahjong/domain/match_wager.gd")
const MahjongAssistance = preload("res://src/mahjong/presentation/mahjong_assistance.gd")
const TileAtlas = preload("res://src/mahjong/presentation/tile_atlas.gd")
const BrandLoadoutPicker = preload("res://src/mahjong/presentation/brand_loadout_picker.gd")
const BrandPatternBadge = preload("res://src/mahjong/presentation/brand_pattern_badge.gd")
const TenderfootAdvisor = preload("res://src/mahjong/presentation/tenderfoot_advisor.gd")
const TenderfootTutorial = preload("res://src/mahjong/presentation/tenderfoot_tutorial.gd")
const MatchReplayExplainer = preload("res://src/mahjong/presentation/match_replay_explainer.gd")
const VisibleKnowledge = preload("res://src/mahjong/ai/visible_knowledge.gd")

var flow
var opponent_id: StringName = &""
var opponent_name := "Trailhand"
var opponent_loadout: Array[StringName] = [&"dark", &"green"]
var opponent_ai_profile: Dictionary = {}
var ruleset: StringName = MatchRuleset.TRAIL
var opponent_upgrades: Dictionary = {}
var status_label: Label; var result_label: Label; var action_box: HBoxContainer; var tiles_box: HBoxContainer
var tutorial_label: Label; var tutorial_button: Button; var tutorial
var wager_tier: StringName = &"friendly"
var _match_started := false
var _ai_turn_pending := false
var _mastery_message := ""
var _effect_message := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_STOP
	GameSession.request_pause(&"mahjong"); SaveService.request_save_restriction(&"mahjong")
	tutorial = TenderfootTutorial.new(GameSession.tutorial_step(&"tenderfoot")); _build_ui(); _show_loadout_selection()


func _exit_tree() -> void:
	GameSession.release_pause(&"mahjong"); SaveService.release_save_restriction(&"mahjong")


func _build_ui() -> void:
	var background := ColorRect.new(); background.color = Color(0.08, 0.055, 0.035, 0.96); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var panel := VBoxContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); panel.position = Vector2(-430, -220); panel.size = Vector2(860, 440); panel.add_theme_constant_override("separation", 10); add_child(panel)
	var title := Label.new(); title.text = "SIX BRANDS • %s vs %s" % [MatchRuleset.display_name(ruleset), opponent_name]; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 26); panel.add_child(title)
	status_label = Label.new(); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; panel.add_child(status_label)
	result_label = Label.new(); result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; panel.add_child(result_label)
	tutorial_label = Label.new(); tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tutorial_label.add_theme_color_override("font_color", Color("f4d08b")); panel.add_child(tutorial_label)
	tutorial_button = Button.new(); tutorial_button.pressed.connect(_advance_tutorial); panel.add_child(tutorial_button)
	tiles_box = HBoxContainer.new(); tiles_box.alignment = BoxContainer.ALIGNMENT_CENTER; tiles_box.size_flags_vertical = Control.SIZE_EXPAND_FILL; panel.add_child(tiles_box)
	action_box = HBoxContainer.new(); action_box.alignment = BoxContainer.ALIGNMENT_CENTER; action_box.add_theme_constant_override("separation", 10); panel.add_child(action_box)
	var help := Label.new(); help.text = "Face-up tiles and every power action identify its Brand with a named pattern; AI explanations use only public information."; help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; panel.add_child(help)


func _refresh() -> void:
	if not _match_started: _show_wager_selection(); return
	_clear(action_box); _clear(tiles_box)
	status_label.text = "%s • %s • Renown: Doc %d — %s %d • Wall: %d\n%s" % [flow.hand_name().capitalize(), MahjongAssistance.label(GamePreferences.mahjong_assistance), flow.renown[0], opponent_name, flow.renown[1], flow.wall.size(), _charge_text()]
	_refresh_tutorial()
	result_label.text = ""
	if flow.phase == MatchFlow.Phase.MATCH_COMPLETE:
		_record_mastery(); result_label.text = "Match complete. %s %s %s\nReplay: %s" % [_match_outcome_text(), _effect_message, _mastery_message, MatchReplayExplainer.summary(flow.replay.snapshot())]; _add_action("Return to town", _close_match); return
	if flow.phase in [MatchFlow.Phase.COMPLETE, MatchFlow.Phase.EXHAUSTED]:
		var last: Dictionary = flow.hand_results.back(); result_label.text = "%s: %s. Renown: %d. %s" % [flow.hand_name().capitalize(), "wall exhausted" if int(last["winner"]) < 0 else ("Doc won" if int(last["winner"]) == 0 else "Opponent won"), int(last["award"]["total"]), _deed_text(last)]
		_add_action("Continue match", _advance_match); return
	if flow.turn_player == 1: _queue_ai_turn(); return
	if flow.phase == MatchFlow.Phase.DRAW: _draw_actions(); return
	_discard_actions()


func _draw_actions() -> void:
	result_label.text = "Your turn: draw, claim a legal public discard, or use a charged Brand."
	_add_action("Draw", _draw_player); _add_action("High Noon", _declare_high_noon)
	if not flow.corrals[0].is_empty(): _add_action("Green: recover Corral", _release_green)
	if flow.brand_state(0).activations(&"blue") > 0: _add_action("Blue: recover discard", _activate_blue)
	if flow.brand_state(0).activations(&"dark") > 0: _add_action("Dark: deny discard", _activate_dark)
	var claim_kinds := [&"blue_run", &"orange_group", &"green_set", &"pink_pair"]
	if ruleset == MatchRuleset.FRONTIER: claim_kinds.append(&"frontier_quad")
	for kind in claim_kinds:
		var indices := _claim_indices(kind)
		if not indices.is_empty(): _add_action("%s claim" % String(kind).replace("_", " ").capitalize(), _claim_brand.bind(kind, indices))


func _discard_actions() -> void:
	if flow.is_winning_hand(flow.combined_hand(0)): _add_action("Declare win", _declare_win)
	if flow.brand_state(0).activations(&"orange") > 0: _add_action("Orange: draw and choose", _activate_orange)
	if flow.brand_state(0).activations(&"green") > 0: _add_action("Green: store first tile", _activate_green)
	if flow.brand_state(0).activations(&"pink") > 0: _add_action("Pink: neutral exchange", _activate_pink)
	if flow.brand_state(0).activations(&"purple") > 0: _add_action("Purple: reorder next tiles", _activate_purple)
	var advice := TenderfootAdvisor.recommend_discard(flow.hands[0], flow.discard_river, flow.open_groups)
	result_label.text = "Choose one tile to discard." if not MahjongAssistance.show_recommendation(GamePreferences.mahjong_assistance) else "Choose one tile to discard. Recommendation: %s — %s" % [_tile_label(advice.get("tile")), advice.get("reason", "")]
	for index in flow.hands[0].size(): _add_tile(index)


func _add_tile(index: int) -> void:
	var tile = flow.hands[0][index]; var button := Button.new(); button.icon = TileAtlas.texture_for(tile); button.expand_icon = true; button.modulate = TileAtlas.brand_color(tile.brand)
	button.tooltip_text = "Discard %s • %s Brand, %s pattern" % [tile.key(), String(tile.brand).capitalize(), TileAtlas.brand_pattern_label(tile.brand)]; button.custom_minimum_size = Vector2(52, 72); button.pressed.connect(_discard_player.bind(index))
	var badge := BrandPatternBadge.new(); badge.configure(tile.brand); button.add_child(badge); tiles_box.add_child(button)


func _queue_ai_turn() -> void:
	result_label.text = "Opponent is considering only visible information…"
	if not _ai_turn_pending: _ai_turn_pending = true; call_deferred("_take_ai_turn")


func _take_ai_turn() -> void:
	_ai_turn_pending = false
	if flow.phase != MatchFlow.Phase.DRAW or flow.turn_player != 1: _refresh(); return
	flow.draw()
	if flow.phase == MatchFlow.Phase.DISCARD:
		if flow.is_winning_hand(flow.combined_hand(1)): flow.declare_win()
		else: flow.discard_at(int(_ai_decision().get("index", 0)))
	_refresh()


func _ai_decision() -> Dictionary:
	var knowledge := VisibleKnowledge.new()
	for entry in flow.discard_river: knowledge.observe_discard(int(entry["player"]), entry["tile"])
	for player in 2:
		for group in flow.open_groups[player]: knowledge.observe_open_group(player, group)
	return FrontierAi.new().choose_discard_index(flow.hands[1], knowledge, opponent_ai_profile) if ruleset == MatchRuleset.FRONTIER else BasicTrailAi.new().choose_discard_index(flow.hands[1], knowledge, opponent_ai_profile)


func _draw_player() -> void: flow.draw(); _record_tutorial_action(&"draw"); _refresh()
func _declare_high_noon() -> void: flow.declare_high_noon(); _record_tutorial_action(&"high_noon"); _refresh()
func _activate_orange() -> void: flow.activate_orange(0); _record_tutorial_action(&"orange"); _refresh()
func _activate_blue() -> void: flow.activate_blue(0); _record_tutorial_action(&"blue"); _refresh()
func _activate_green() -> void: flow.activate_green(0); _record_tutorial_action(&"green"); _refresh()
func _release_green() -> void: flow.release_green(); _refresh()
func _activate_pink() -> void: flow.activate_pink(0); _record_tutorial_action(&"pink"); _refresh()
func _activate_dark() -> void: flow.activate_dark(); _record_tutorial_action(&"dark"); _refresh()
func _activate_purple() -> void:
	var count := 4 if flow.upgrade_rank(0, &"purple") > 0 else 3
	var order: Array[int] = []
	for index in range(count - 1, -1, -1): order.append(index)
	flow.activate_purple(order); _record_tutorial_action(&"purple"); _refresh()
func _claim_brand(kind: StringName, indices: Array[int]) -> void: flow.claim_brand_group_from_last_discard(0, kind, indices); _refresh()
func _discard_player(index: int) -> void: flow.discard_at(index); _record_tutorial_action(&"discard"); _refresh()
func _declare_win() -> void: flow.declare_win(); _refresh()
func _advance_match() -> void: flow.advance_match(); _refresh()


func _close_match() -> void:
	if _match_started: MatchWager.settle(GameSession.inventory, wager_tier, flow.match_winner)
	GameSession.complete_mahjong_match(); SaveService.release_save_restriction(&"mahjong"); SaveService.autosave(&"mahjong_match"); queue_free()


func _show_wager_selection() -> void:
	_clear(action_box); _clear(tiles_box); status_label.text = "Loadout: %s. Choose table terms with %s." % [", ".join(GameSession.brands.last_selected).capitalize(), opponent_name]; result_label.text = "Friendly matches have no cash stake."
	for tier in MatchWager.TERMS: _add_action("%s — %s" % [MatchWager.label(tier), "no cash" if MatchWager.stake_cents(tier) == 0 else "$%.2f" % (MatchWager.stake_cents(tier) / 100.0)], _start_match.bind(StringName(tier)))


func _start_match(next_wager_tier: StringName) -> void:
	if not MatchWager.can_start(next_wager_tier, GameSession.inventory.money_cents, GameSession.inventory): return
	wager_tier = next_wager_tier; flow = MatchFlow.new(GameSession.seed + GameSession.day * 100 + GameSession.minute_of_day); flow.configure_ruleset(ruleset); flow.configure_loadouts(GameSession.brands.last_selected, opponent_loadout); flow.configure_upgrades(GameSession.brands.upgrades, opponent_upgrades); flow.start_match()
	var bonus: int = int(GameSession.effects.consume_for_match(&"mahjong_charge"))
	if bonus > 0:
		flow.brand_state(0).grant_charge(flow.brand_state(0).equipped[0])
		_effect_message = "Your prepared food gives %d opening Brand charge." % bonus
	_match_started = true; _refresh()


func _show_loadout_selection() -> void:
	var picker := BrandLoadoutPicker.new(); picker.configure(GameSession.brands); picker.confirmed.connect(func(_loadout): _show_wager_selection()); get_tree().root.add_child(picker); picker.open()


func _claim_indices(kind: StringName) -> Array[int]:
	if flow.phase != MatchFlow.Phase.DRAW or flow.discard_river.is_empty(): return []
	var count := 1 if kind == &"pink_pair" else 3 if kind == &"frontier_quad" else 2
	var discard: Dictionary = flow.discard_river.back()
	if int(discard.get("player", -1)) == 0 or bool(discard.get("claimed", false)): return []
	return _find_claim(kind, discard["tile"], count, [], 0)


func _find_claim(kind: StringName, tile, count: int, chosen: Array[int], start: int) -> Array[int]:
	if chosen.size() == count:
		var tiles: Array = []; for index in chosen: tiles.append(flow.hands[0][index])
		var resolved := ClaimResolver.resolve(tile, [{"player": 0, "kind": String(kind), "equipped": flow.brand_state(0).equipped, "tiles": tiles}])
		return chosen if not resolved.is_empty() else []
	for index in range(start, flow.hands[0].size()):
		var next: Array[int] = chosen.duplicate(); next.append(index); var result: Array[int] = _find_claim(kind, tile, count, next, index + 1)
		if not result.is_empty(): return result
	return []


func _record_mastery() -> void:
	if not _mastery_message.is_empty() or flow.match_winner != 0: return
	for hand_result in flow.hand_results:
		var award: Variant = hand_result.get("award", {})
		if award is Dictionary: GameSession.brands.record_deeds(award.get("deeds", []))
	var result: Dictionary = GameSession.brands.record_match_win(opponent_id, ruleset)
	if opponent_id in [&"ada_rook", &"gideon_shaw", &"registrar_elise", &"constable_mara", &"mariner_ves", &"captain_coral", &"witness_ash"]:
		GameSession.regions.record_table_win(opponent_id)
	var property_note := ""
	if opponent_id == &"registrar_elise":
		if GameSession.properties.resolve(&"saints_landing_depot", &"match") == OK:
			GameSession.brands.unlock_hall_stage(3)
			property_note = " The Landing Depot dispute is settled; Ironhook and Hall practice are open."
	var unlocked: Array = result.get("unlocked_brands", [])
	var names: Array[String] = []
	for brand in unlocked: names.append(String(brand).capitalize())
	_mastery_message = ("Unlocked %s Brand. " % " and ".join(names) if not names.is_empty() else "") + ("Hall cleanup complete: the Frontier table is open." if bool(result.get("hall_reopened", false)) else "") + property_note


func _refresh_tutorial() -> void:
	tutorial_label.text = tutorial.progress_text()
	tutorial_button.visible = not tutorial.is_complete()
	if tutorial_button.visible: tutorial_button.text = "Continue lesson" if tutorial.can_continue_manually() else "Complete the highlighted action"


func _advance_tutorial() -> void:
	if tutorial.advance(): GameSession.set_tutorial_step(&"tenderfoot", tutorial.step)
	_refresh()


func _record_tutorial_action(action: StringName) -> void:
	if tutorial.record_action(action): GameSession.set_tutorial_step(&"tenderfoot", tutorial.step)


func _charge_text() -> String:
	var parts: Array[String] = []
	for brand in flow.brand_state(0).equipped: parts.append("%s %d/3, %d ready" % [String(brand).capitalize(), flow.brand_state(0).charges(brand), flow.brand_state(0).activations(brand)])
	return " • ".join(parts)
func _deed_text(last: Dictionary) -> String:
	var deeds: Array = last.get("award", {}).get("deeds", []); return " ".join(deeds.map(func(deed): return String(deed.get("explanation", ""))))
func _match_outcome_text() -> String: return "Doc wins!" if flow.match_winner == 0 else "Opponent wins." if flow.match_winner == 1 else "The match ends tied."
func _tile_label(tile) -> String: return tile.key() if tile != null else "none"
func _add_action(text_value: String, callback: Callable) -> void: var button := Button.new(); button.text = text_value; button.custom_minimum_size = Vector2(142, 42); button.pressed.connect(callback); action_box.add_child(button)
func _clear(node: Node) -> void: for child in node.get_children(): child.queue_free()
