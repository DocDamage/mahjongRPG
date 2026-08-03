extends RefCounted

var _arc_id: StringName
var _action_id: StringName
var _sequence_id: StringName
var _community
var _relationships
var _helpers
var _has_consumer := Callable()
var _publish_event := Callable()
var _finished := true


func begin(arc_id: StringName, sequence: Dictionary, community, relationships, helpers, has_consumer := Callable(), publish_event := Callable()) -> Error:
	if community == null or relationships == null or helpers == null or arc_id.is_empty() or not _finished:
		return ERR_INVALID_PARAMETER
	var sequence_id := StringName(sequence.get("id", ""))
	var action_id: StringName = community.expected_action(arc_id)
	if action_id.is_empty() or sequence_id.is_empty() or community.expected_dialogue_sequence(arc_id) != sequence_id:
		return ERR_UNAVAILABLE
	_arc_id = arc_id
	_action_id = action_id
	_sequence_id = sequence_id
	_community = community
	_relationships = relationships
	_helpers = helpers
	_has_consumer = has_consumer
	_publish_event = publish_event
	_finished = false
	return OK


func cancel() -> void:
	_finished = true


func commit_terminal() -> Dictionary:
	if _finished:
		return {"error": ERR_ALREADY_IN_USE}
	_finished = true
	if _community.expected_action(_arc_id) != _action_id or _community.expected_dialogue_sequence(_arc_id) != _sequence_id:
		return {"error": ERR_UNAVAILABLE}
	var result: Dictionary = _community.advance(_arc_id, _action_id, _relationships, _helpers)
	if result.has("error"):
		return result
	var event := {
		"contract_version": 1,
		"event_id": StringName("dialogue.%s" % _sequence_id),
		"kind": &"dialogue.seen",
		"source_id": &"community_dialogue",
		"payload": {"sequence_id": _sequence_id},
	}
	if _has_consumer.is_valid() and bool(_has_consumer.call(event)) and _publish_event.is_valid():
		_publish_event.call(event.duplicate(true))
	return result
