extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

@export_file("*.tscn") var destination_scene: String
@export var required_hall_milestone: StringName
@export var required_region: StringName
@export var unlock_region_on_access: StringName
@export var required_property: StringName
@export var required_fulfilled_order: StringName
@export var required_story_entry := false

var _transition_requested := false


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-24, -32, 48, 64), Color("3c2b1b"))
	draw_rect(Rect2(-24, -32, 48, 64), Color("d9c18a"), false, 3.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), Color("d9c18a"), 3.0)


func _on_interacted(_actor: Node2D) -> void:
	if _transition_requested:
		return
	if not required_hall_milestone.is_empty() and not GameSession.quests.hall_milestones.has(required_hall_milestone):
		feedback.emit("Access is disputed until the Six Brands Hall restores %s." % required_hall_milestone.capitalize())
		return
	if not unlock_region_on_access.is_empty() and not GameSession.regions.is_unlocked(unlock_region_on_access):
		GameSession.regions.unlock(unlock_region_on_access)
	if not required_region.is_empty() and not GameSession.regions.is_unlocked(required_region):
		feedback.emit("This region is still locked. Follow its trail lead first.")
		return
	if not required_property.is_empty() and not GameSession.properties.is_resolved(required_property):
		feedback.emit("This route opens when the linked property case is resolved.")
		return
	if not required_fulfilled_order.is_empty() and not GameSession.regions.fulfilled_orders.has(required_fulfilled_order):
		feedback.emit("Finish the posted local work before taking this route.")
		return
	if required_story_entry and (GameSession.story == null or not GameSession.story.can_enter_kings_reach()):
		feedback.emit("King's Reach is sealed until the validated investigation proves Silas is alive and explains every altered rule.")
		return
	if destination_scene.is_empty():
		feedback.emit("That route is closed for now.")
		return
	_transition_requested = true
	if SceneRouter.change_scene(destination_scene) != OK:
		_transition_requested = false
		feedback.emit("That route is closed for now.")
