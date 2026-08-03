extends "res://src/world/interior.gd"

const CommunityPortrait = preload("res://src/dialogue/community_portrait.gd")

@export var resident_id: StringName


func _ready() -> void:
	super._ready()
	if resident_id.is_empty() or GameSession.community == null:
		return
	var definition: Dictionary = GameSession.community.definitions.get(resident_id, {})
	if definition.is_empty():
		return
	var portrait := CommunityPortrait.new()
	portrait.position = Vector2(744, 126)
	portrait.configure(definition, "warm" if GameSession.community.is_completed(resident_id) else "steady")
	add_child(portrait)
