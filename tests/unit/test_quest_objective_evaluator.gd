extends RefCounted

const Evaluator = preload("res://src/quests/quest_objective_evaluator.gd")
const QuestEvent = preload("res://src/quests/quest_event.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var objectives: Array = [{"id": "meet", "type": "event_once", "event_kind": "interaction.completed", "match": {"interaction_id": "test.meet"}}]
	var event := QuestEvent.make_interaction(&"test.meet", &"test_source", &"event.one")
	var before := objectives.duplicate(true)
	if Evaluator.matching_objective_ids(objectives, event) != [&"meet"]:
		failures.append("pure evaluation should return exact matching objective IDs")
	if objectives != before:
		failures.append("evaluation should not mutate objective definitions")
	var other := QuestEvent.make_interaction(&"test.other", &"test_source", &"event.two")
	if not Evaluator.matching_objective_ids(objectives, other).is_empty():
		failures.append("non-matching payloads should produce no objective progress")
	if Evaluator.matching_objective_ids(objectives, QuestEvent.make_inventory_report(&"crop_beans", 0, 1, &"test_sync")).size() != 0:
		failures.append("inventory possession reports must not satisfy interaction objectives")
	return failures
