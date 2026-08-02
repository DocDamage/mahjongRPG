extends PanelContainer

signal confirmed(loadout: Array[StringName])

var _selected: Array[StringName] = []
var _state
var _status: Label


func configure(state) -> void:
	_state = state
	_selected = state.last_selected.duplicate() if state != null else []


func open() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	position = Vector2(-250, -155)
	size = Vector2(500, 310)
	_build()
	GameSession.request_pause(&"brand_loadout")


func _exit_tree() -> void:
	GameSession.release_pause(&"brand_loadout")


func _build() -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := Label.new()
	title.text = "CHOOSE YOUR TWO BRANDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)
	for brand in _state.unlocked_brands():
		var button := CheckButton.new()
		button.text = "%s Brand" % String(brand).capitalize()
		button.button_pressed = brand in _selected
		button.toggled.connect(_toggle.bind(brand))
		content.add_child(button)
	var confirm := Button.new()
	confirm.text = "Confirm loadout"
	confirm.pressed.connect(_confirm)
	content.add_child(confirm)
	_refresh_status()


func _toggle(enabled: bool, brand: StringName) -> void:
	if enabled and not brand in _selected:
		_selected.append(brand)
	elif not enabled:
		_selected.erase(brand)
	_refresh_status()


func _refresh_status() -> void:
	_status.text = "Selected: %s. %s" % [", ".join(_selected).capitalize(), "Choose exactly two." if _selected.size() != 2 else "This loadout stays locked for the match."]


func _confirm() -> void:
	if _state == null or _state.select(_selected) != OK:
		_status.text = "Choose two different unlocked Brands."
		return
	confirmed.emit(_selected.duplicate())
	queue_free()
