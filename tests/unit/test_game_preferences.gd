extends RefCounted

const GamePreferences = preload("res://src/accessibility/game_preferences.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var preferences := GamePreferences.new()
	Engine.get_main_loop().root.add_child(preferences)
	var initial_ui_scale := preferences.ui_scale
	preferences.cycle_ui_scale()
	preferences.cycle_text_scale()
	preferences.cycle_dialogue_speed()
	preferences.toggle_interaction_mode()
	preferences.toggle_reduced_motion()
	preferences.toggle_subtitles()
	preferences.cycle_controller_glyph_set()
	var restored := GamePreferences.new()
	if restored.load_preferences() != OK or is_equal_approx(restored.ui_scale, initial_ui_scale) or restored.interaction_mode != preferences.interaction_mode or restored.reduced_motion != preferences.reduced_motion or restored.subtitles != preferences.subtitles or restored.controller_glyph_set != preferences.controller_glyph_set:
		failures.append("accessibility preferences must persist text/UI, dialogue, interaction, motion, subtitles, and glyph settings")
	DirAccess.remove_absolute(GamePreferences.CONFIG_PATH)
	preferences.queue_free()
	restored.free()
	return failures
