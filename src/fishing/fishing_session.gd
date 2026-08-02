extends RefCounted

const FishDefinition = preload("res://src/fishing/fish_definition.gd")

enum State { AIM, CAST, WAIT, BITE, HOOKED, STRUGGLE, CATCH, ESCAPE, PRESENTATION, CLEANUP }

const MAX_TENSION := 1.0
const HOOK_WINDOW_SECONDS := 1.5

var state := State.AIM
var seed: int
var fish
var tension := 0.0
var progress := 0.0
var target_direction := 0.0
var _rng := RandomNumberGenerator.new()
var _wait_remaining := 0.0
var _hook_remaining := 0.0
var _struggle_remaining := 0.0


func _init(next_seed: int) -> void:
	seed = next_seed
	_rng.seed = seed


func cast(fish_definitions: Array, hour: int, weather_id: StringName) -> Error:
	if state != State.AIM:
		return ERR_INVALID_DATA
	var eligible: Array = []
	for definition in fish_definitions:
		if definition is FishDefinition and definition.matches(hour, weather_id):
			eligible.append(definition)
	if eligible.is_empty():
		return ERR_DOES_NOT_EXIST
	fish = eligible[_rng.randi_range(0, eligible.size() - 1)]
	state = State.CAST
	_wait_remaining = _rng.randf_range(0.7, 1.5) + fish.difficulty
	tension = 0.0
	progress = 0.0
	return OK


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if state == State.CAST:
		state = State.WAIT
	elif state == State.WAIT:
		_wait_remaining -= delta
		if _wait_remaining <= 0.0:
			state = State.BITE
			_hook_remaining = HOOK_WINDOW_SECONDS
	elif state == State.BITE:
		_hook_remaining -= delta
		if _hook_remaining <= 0.0:
			_escape()
	elif state == State.STRUGGLE:
		_struggle_remaining -= delta
		if _struggle_remaining <= 0.0:
			_escape()


func hook_set() -> Error:
	if state != State.BITE:
		return ERR_INVALID_DATA
	state = State.HOOKED
	_start_struggle()
	return OK


func apply_struggle_input(direction: float, reeling: bool, releasing: bool, delta: float) -> Error:
	if state != State.STRUGGLE or delta <= 0.0:
		return ERR_INVALID_DATA
	var alignment := clampf(direction, -1.0, 1.0) * target_direction
	var control := (alignment + 1.0) * 0.5
	if reeling:
		tension += (0.22 + fish.difficulty * 0.35) * delta
		progress += (0.15 + control * 0.25) * delta
	if releasing:
		tension -= 0.45 * delta
		progress -= 0.04 * delta
	if not reeling and not releasing:
		tension -= 0.08 * delta
	tension = clampf(tension, 0.0, MAX_TENSION)
	progress = clampf(progress, 0.0, 1.0)
	if tension >= MAX_TENSION:
		_escape()
	elif progress >= 1.0:
		state = State.CATCH
	return OK


func present_result() -> Error:
	if state not in [State.CATCH, State.ESCAPE]:
		return ERR_INVALID_DATA
	state = State.PRESENTATION
	return OK


func cleanup() -> Error:
	if state != State.PRESENTATION:
		return ERR_INVALID_DATA
	state = State.CLEANUP
	return OK


func reset() -> void:
	state = State.AIM
	fish = null
	tension = 0.0
	progress = 0.0


func _start_struggle() -> void:
	state = State.STRUGGLE
	target_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	_struggle_remaining = 8.0 + (1.0 - fish.difficulty) * 4.0


func _escape() -> void:
	state = State.ESCAPE
