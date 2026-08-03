extends Control

var region_id: StringName
var _status: Label
var _message: Label


func configure(next_region_id: StringName) -> void:

	region_id = next_region_id


func _ready() -> void:

	position = Vector2(18, 92)
	custom_minimum_size = Vector2(320, 0)
	_build()


func _build(message := "") -> void:

	for child in get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	for arc_id in GameSession.community.residents_for_region(region_id):
		var definition: Dictionary = GameSession.community.definitions[arc_id]
		var arc_button := Button.new()
		arc_button.text = "%s: %s" % [String(definition.get("display_name", arc_id)), GameSession.community.stage_label(arc_id)]
		arc_button.pressed.connect(_advance.bind(arc_id))
		box.add_child(arc_button)
		var home_button := Button.new()
		home_button.text = "Visit %s's home" % String(definition.get("display_name", arc_id))
		home_button.pressed.connect(_visit_home.bind(arc_id))
		box.add_child(home_button)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.text = message
	box.add_child(_message)
	_refresh_status()


func _advance(arc_id: StringName) -> void:

	var result: Dictionary = GameSession.community.advance(arc_id, GameSession.community.expected_action(arc_id), GameSession.relationships, GameSession.helpers)
	_build(String(result.get("message", "That arc is already resolved.")))


func _visit_home(arc_id: StringName) -> void:

	var destination: String = GameSession.community.home_scene(arc_id)
	if SceneRouter.change_scene(destination) != OK:
		_message.text = "That home is unavailable."


func _refresh_status() -> void:

	var resolved: int = GameSession.community.completed.size()
	var secrets: int = GameSession.community.discovered_secrets.size()
	_status.text = "COMMUNITY JOURNAL  •  Arcs %d/10  •  Secrets %d/8" % [resolved, secrets]
