extends Node

const DialogueCatalog = preload("res://src/dialogue/dialogue_catalog.gd")
const DialogueSequenceRunner = preload("res://src/dialogue/dialogue_sequence_runner.gd")
const DialogueSequenceValidator = preload("res://src/dialogue/dialogue_sequence_validator.gd")
const CommunityDialogueCoordinator = preload("res://src/dialogue/community_dialogue_coordinator.gd")
const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")
const PAUSE_REASON := &"dialogue_sequence"

signal finished(message: String)

var _runner
var _coordinator
var _pause_held := false


func _exit_tree() -> void:
	_release_pause()


func start(arc_id: StringName) -> Error:
	if _runner != null:
		return ERR_BUSY
	var sequence_id: StringName = GameSession.community.expected_dialogue_sequence(arc_id)
	var sequence := DialogueCatalog.sequence(sequence_id)
	if sequence.is_empty():
		return ERR_DOES_NOT_EXIST
	var context := {
		"localization_keys": DialogueCatalog.localization_keys(),
		"speaker_ids": GameSession.community.definitions.keys(),
		"portrait_speaker_ids": RuntimeAssetCatalog.portrait_residents(),
		"portrait_expressions": RuntimeAssetCatalog.portrait_expressions(),
	}
	if not DialogueSequenceValidator.validate(sequence, DialogueCatalog.TABLE_PATH, context).is_empty():
		return ERR_INVALID_DATA
	_coordinator = CommunityDialogueCoordinator.new()
	if _coordinator.begin(arc_id, sequence, GameSession.community, GameSession.relationships, GameSession.helpers) != OK:
		_coordinator = null
		return ERR_UNAVAILABLE
	_runner = DialogueSequenceRunner.new()
	add_child(_runner)
	_runner.terminal_acknowledged.connect(_on_terminal_acknowledged)
	_runner.cancelled.connect(_on_cancelled)
	GameSession.request_pause(PAUSE_REASON)
	_pause_held = true
	var open_result: Error = _runner.open_sequence(sequence, Callable(DialogueCatalog, "text"), GameSession.community.definitions, GamePreferences, SaveService, GameSession.session_gate)
	if open_result != OK:
		_release_pause()
		_runner.queue_free()
		_runner = null
		_coordinator = null
	return open_result


func _on_terminal_acknowledged(_sequence_id: StringName) -> void:
	var result: Dictionary = _coordinator.commit_terminal()
	_runner.finish_commit()
	_release_pause()
	var message := String(result.get("message", "That conversation can no longer be committed."))
	_cleanup()
	finished.emit(message)


func _on_cancelled(_sequence_id: StringName) -> void:
	_coordinator.cancel()
	_release_pause()
	_cleanup()
	finished.emit("Conversation paused before commitment.")


func _release_pause() -> void:
	if not _pause_held:
		return
	GameSession.release_pause(PAUSE_REASON)
	_pause_held = false


func _cleanup() -> void:
	if _runner != null:
		_runner.queue_free()
	_runner = null
	_coordinator = null
