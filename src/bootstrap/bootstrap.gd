extends Control

const IMPORT_MARKER := "res://assets/source/supplemental/.import_complete.json"
const WAYWARD_FARM_SCENE := "res://src/world/wayward_farm.tscn"
const AccessibilitySettings = preload("res://src/ui/accessibility_settings.gd")
const ReleaseUiArt = preload("res://src/ui/release_ui_art.gd")

var _panel: VBoxContainer
var _status: Label
var _accessibility

func _ready() -> void:
	AudioService.play_catalog_music(&"title")
	_build_title_shell()

func _build_title_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("241b16")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	ReleaseUiArt.add_art(background, &"menu_closed", Vector2(38, 54), Vector2(128, 128))
	ReleaseUiArt.add_art(background, &"attention_marker", Vector2(800, 62), Vector2(76, 76))

	_panel = VBoxContainer.new()
	_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-250, -180)
	_panel.size = Vector2(500, 360)
	_panel.add_theme_constant_override("separation", 10)
	background.add_child(_panel)

	var title := Label.new()
	title.text = "SIX BRANDS AT HIGH NOON"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	_panel.add_child(title)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = _status_text()
	_panel.add_child(_status)

	var start_button := _add_button("New game", _start_game)
	start_button.grab_focus()
	_add_button("Load autosave", _load_autosave)
	_add_button("Accessibility & settings", _open_accessibility)
	_add_button("Quit", get_tree().quit)
	_accessibility = AccessibilitySettings.new()
	_accessibility.configure(GamePreferences)
	_accessibility.position = Vector2(230, 78)
	_accessibility.size = Vector2(500, 386)
	add_child(_accessibility)

func _status_text() -> String:
	if FileAccess.file_exists(IMPORT_MARKER):
		return "Demo foundation ready. New Game begins at Wayward Farm; loading supports automatic backup recovery."
	return "Demo foundation ready. Supplemental source assets are optional for the tracked debug build."


func _start_game() -> void:
	GameSession.start_new_game(0x5EED)
	SceneRouter.change_scene(WAYWARD_FARM_SCENE)


func _load_autosave() -> void:
	var result := SaveService.load_current_session(SaveService.SLOT_AUTOSAVE)
	_status.text = "Autosave loaded." if result == OK else "No valid autosave was found. A corrupt primary save will use its backup automatically."


func _open_accessibility() -> void:
	_accessibility.open()


func _add_button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(280, 42)
	button.pressed.connect(callback)
	_panel.add_child(button)
	return button
