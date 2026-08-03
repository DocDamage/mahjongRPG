extends RefCounted

const AudioService = preload("res://src/audio/audio_service.gd")
const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")
const GamePreferences = preload("res://src/accessibility/game_preferences.gd")
const GameSession = preload("res://src/core/game_session.gd")
const InputService = preload("res://src/input/input_service.gd")
const JournalSummary = preload("res://src/journal/journal_summary.gd")
const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_check_presentation_catalog(failures)
	_check_localization_and_journal(failures)
	_check_accessibility_migration(failures)
	_check_audio_catalog(failures)
	_check_public_save_migrations(failures)
	_check_release_contract(failures)
	return failures


func _check_presentation_catalog(failures: Array[String]) -> void:
	for art_id in [&"menu_closed", &"inventory_slot", &"attention_marker"]:
		if not ResourceLoader.exists(RuntimeAssetCatalog.ui_texture_path(art_id)):
			failures.append("P17 UI art mapping should resolve %s" % art_id)
	if not ResourceLoader.exists(RuntimeAssetCatalog.atlas_path(&"mahjong_faces")):
		failures.append("P17 must retain a runtime Mahjong atlas")
	for resident_id in [&"mayor_bell", &"river_rose", &"dynamite_bill", &"ada_rook", &"gideon_shaw", &"registrar_elise", &"constable_mara", &"mariner_ves", &"captain_coral", &"witness_ash"]:
		for expression in [&"steady", &"determined", &"warm"]:
			if not RuntimeAssetCatalog.portrait_expression_supported(resident_id, expression):
				failures.append("P17 portrait coverage should include %s/%s" % [resident_id, expression])
	var input_service = InputService.new()
	input_service.install_default_actions()
	input_service.reset_controller_bindings(&"interact")
	if input_service.controller_glyph_text(&"interact", &"xbox") != "A" or input_service.controller_glyph_text(&"interact", &"playstation") != "Cross":
		failures.append("P17 controller glyph variants should expose family-specific labels")
	input_service.free()


func _check_localization_and_journal(failures: Array[String]) -> void:
	var session = GameSession.new()
	session.start_new_game(1718)
	for evidence_value in session.evidence.definitions.values():
		var evidence: Dictionary = evidence_value
		if not DialogueCatalog.has_text(StringName(evidence.get("title_key", ""))) or not DialogueCatalog.has_text(StringName(evidence.get("text_key", ""))):
			failures.append("P17 evidence entries must have English title and text coverage")
	for arc_id_value in session.community.definitions:
		var arc_id := String(arc_id_value)
		var arc: Dictionary = session.community.definitions[arc_id_value]
		for stage_value in arc["stages"]:
			if not DialogueCatalog.has_text(StringName("community.%s.%s" % [arc_id, String(stage_value["action"])])):
				failures.append("P17 community stage must have localized text: %s" % arc_id)
	for key in DialogueCatalog.release_required_keys():
		if not DialogueCatalog.has_text(key):
			failures.append("P17 release UI localization key is missing: %s" % key)
	var journal: Dictionary = JournalSummary.summary(session)
	for group_id in [&"evidence", &"brands", &"fish_records", &"community_arcs", &"community_secrets", &"property_cases", &"desert_records"]:
		if not journal.get("groups", {}).has(group_id):
			failures.append("P17 journal should include %s" % group_id)
	session.free()


func _check_accessibility_migration(failures: Array[String]) -> void:
	DirAccess.remove_absolute(GamePreferences.CONFIG_PATH)
	var legacy := ConfigFile.new()
	legacy.set_value("accessibility", "ui_scale", 1.15)
	legacy.set_value("accessibility", "controller_glyph_set", "playstation")
	if legacy.save(GamePreferences.CONFIG_PATH) != OK:
		failures.append("P17 test could not create a schema-one preferences file")
		return
	var preferences = GamePreferences.new()
	Engine.get_main_loop().root.add_child(preferences)
	if preferences.load_preferences() != OK or preferences.timing_assist != &"standard" or not preferences.haptics_enabled or preferences.controller_glyph_set != &"playstation":
		failures.append("P17 settings schema one must migrate to safe assist and glyph defaults")
	preferences.cycle_timing_assist()
	preferences.toggle_haptics()
	preferences.toggle_high_contrast()
	var contrast_overlay = Engine.get_main_loop().root.get_node_or_null("AccessibilityHighContrast")
	if contrast_overlay == null or not contrast_overlay.visible:
		failures.append("P17 high-contrast preference must enable the global contrast overlay")
	var restored = GamePreferences.new()
	if preferences.save_preferences() != OK:
		failures.append("P17 settings schema two should save")
	else:
		if restored.load_preferences() != OK or restored.timing_assist != &"relaxed" or restored.haptics_enabled or not restored.high_contrast or not is_equal_approx(restored.timing_window_multiplier(), 1.75):
			failures.append("P17 assist settings must persist and affect timing")
		var config := ConfigFile.new()
		if config.load(GamePreferences.CONFIG_PATH) != OK or int(config.get_value("accessibility", "schema_version", 0)) != GamePreferences.SETTINGS_SCHEMA_VERSION:
			failures.append("P17 settings files must record their explicit schema")
	DirAccess.remove_absolute(GamePreferences.CONFIG_PATH)
	Engine.get_main_loop().root.remove_child(preferences)
	preferences.free()
	restored.free()


func _check_audio_catalog(failures: Array[String]) -> void:
	var service = AudioService.new()
	Engine.get_main_loop().root.add_child(service)
	if service.load_runtime_catalog() != OK:
		failures.append("P17 full audio catalog should load")
		return
	for track_id in [&"title", &"exploration", &"mahjong", &"finale", &"credits"]:
		if not ResourceLoader.exists(service.music_path(track_id)):
			failures.append("P17 music mapping should resolve %s" % track_id)
	if service.play_catalog_music(&"title") != OK or service.play_catalog_music(&"missing") != ERR_DOES_NOT_EXIST:
		failures.append("P17 music tracks should play through the Music bus and reject missing keys")
	for event_id in [&"ui_confirm", &"journal_updated", &"crop_watered", &"animal_cared", &"fishing_caught", &"mahjong_win", &"quest_completed", &"region_unlocked", &"credits_open"]:
		if not service.has_catalog_event(event_id) or not ResourceLoader.exists(service.event_path(event_id)):
			failures.append("P17 event-keyed audio should resolve %s" % event_id)
	Engine.get_main_loop().root.remove_child(service)
	service.free()


func _check_public_save_migrations(failures: Array[String]) -> void:
	var session = GameSession.new()
	session.start_new_game(1818)
	var snapshot := session.snapshot()
	for schema_version in range(1, GameSession.SAVE_SCHEMA_VERSION + 1):
		var public_save := snapshot.duplicate(true)
		public_save["schema_version"] = schema_version
		var restored = GameSession.new()
		if restored.restore(public_save) != OK or int(restored.snapshot().get("schema_version", 0)) != GameSession.SAVE_SCHEMA_VERSION:
			failures.append("P18 public save schema %d must restore forward" % schema_version)
		restored.free()
	session.free()


func _check_release_contract(failures: Array[String]) -> void:
	var file := FileAccess.open("res://data/release/release_candidate.json", FileAccess.READ)
	var metadata: Variant = JSON.parse_string(file.get_as_text()) if file != null else {}
	if not metadata is Dictionary or metadata.get("version", "") != "1.0.0-rc.1" or metadata.get("engine_project_version", "") != "1.0.0" or int(metadata.get("save_schema", {}).get("current", 0)) != GameSession.SAVE_SCHEMA_VERSION:
		failures.append("P18 must keep versioned release metadata aligned with the current save schema")
