extends Control

const IMPORT_MARKER := "res://assets/source/supplemental/.import_complete.json"
const WAYWARD_FARM_SCENE := "res://src/world/wayward_farm.tscn"

func _ready() -> void:
    _build_foundation_status()

func _build_foundation_status() -> void:
    var background := ColorRect.new()
    background.color = Color("241b16")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var panel := VBoxContainer.new()
    panel.alignment = BoxContainer.ALIGNMENT_CENTER
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-250, -90)
    panel.size = Vector2(500, 180)
    background.add_child(panel)

    var title := Label.new()
    title.text = "SIX BRANDS AT HIGH NOON"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    panel.add_child(title)

    var status := Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.text = _status_text()
    panel.add_child(status)

    var start_button := Button.new()
    start_button.text = "Start at Wayward Farm"
    start_button.custom_minimum_size = Vector2(240, 42)
    start_button.pressed.connect(_start_game)
    panel.add_child(start_button)
    start_button.grab_focus()

func _status_text() -> String:
    if FileAccess.file_exists(IMPORT_MARKER):
        return "Foundation initialized. Supplemental assets verified and imported."
    return "Foundation initialized. Run: python tools/import_supplemental_assets.py"


func _start_game() -> void:
    GameSession.start_new_game(0x5EED)
    SceneRouter.change_scene(WAYWARD_FARM_SCENE)
