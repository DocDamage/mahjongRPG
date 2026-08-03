extends PanelContainer

signal closed()

const AUDIO_BUSES := [&"Master", &"Music", &"Ambience", &"SFX", &"Mahjong", &"UI"]

var _first_slider: HSlider


func _ready() -> void:
	_build()


func open() -> void:
	visible = true
	if _first_slider != null:
		_first_slider.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _build() -> void:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := Label.new()
	title.text = "AUDIO SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	for bus_name in AUDIO_BUSES:
		_add_volume_row(content, bus_name)
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(0, 36)
	back_button.pressed.connect(close)
	content.add_child(back_button)
	visible = false


func _add_volume_row(content: VBoxContainer, bus_name: StringName) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var label := Label.new()
	label.text = String(bus_name)
	label.custom_minimum_size = Vector2(104, 32)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var service = get_node_or_null("/root/AudioService")
	slider.value = 1.0 if service == null else maxf(0.0, service.bus_volume(bus_name))
	slider.value_changed.connect(_set_volume.bind(bus_name))
	row.add_child(slider)
	if _first_slider == null:
		_first_slider = slider


func _set_volume(value: float, bus_name: StringName) -> void:
	var service = get_node_or_null("/root/AudioService")
	if service != null:
		service.set_bus_volume(bus_name, value)
