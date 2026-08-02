extends RefCounted

const LESSONS := [
	{"title": "Tile identities", "body": "Each tile shows its rank, suit initial, and Brand initial. Brand colors do not change the tile's normal identity.", "actions": []},
	{"title": "Draw and discard", "body": "Draw to eleven tiles, then discard back to ten. Your draw and discard buttons are always legal when they appear.", "actions": [&"draw", &"discard"]},
	{"title": "Runs", "body": "A Run is three connected numbered tiles in one suit, such as 4–5–6. Keep nearby ranks together.", "actions": []},
	{"title": "Sets", "body": "A Set is three matching identities. Brands can differ; the traditional tile identity must match.", "actions": []},
	{"title": "The pair", "body": "Every Trail Rules hand also needs one pair. A pair is two matching identities.", "actions": []},
	{"title": "Claims", "body": "An opponent's public discard can complete a legal claim. Brand claim buttons appear only when the domain approves them.", "actions": []},
	{"title": "Brands", "body": "Choose two Brands before a match. Discarding tiles in your equipped Brands earns charges for their powers.", "actions": []},
	{"title": "Orange", "body": "Orange can draw two and keep one, or make a special group claim. It costs a stored Orange activation.", "actions": [&"orange"]},
	{"title": "Blue", "body": "Blue can reclaim a recent discard or make a special Run claim. It costs a stored Blue activation.", "actions": [&"blue"]},
	{"title": "High Noon", "body": "With a one-tile wait, declare High Noon for a visible three-draw countdown. Your Brand powers lock while it is active.", "actions": [&"high_noon"]},
	{"title": "Deeds and Renown", "body": "Winning hands earn Renown. Deeds add bonuses for achievements such as a self-made win or a High Noon finish.", "actions": []},
	{"title": "Wagers", "body": "Matches can carry friendly, serious, or high-stakes terms. Never risk a progression item: important losses must remain recoverable.", "actions": []},
]

var step := 0
var _seen_actions: Dictionary = {}


func _init(saved_step := 0) -> void:
	step = clampi(saved_step, 0, LESSONS.size())


func is_complete() -> bool:
	return step >= LESSONS.size()


func lesson() -> Dictionary:
	if is_complete():
		return {}
	return LESSONS[step].duplicate(true)


func progress_text() -> String:
	if is_complete():
		return "Tenderfoot complete: keep the legal-action highlights on whenever you want a refresher."
	var current := lesson()
	return "Tenderfoot %d/%d — %s\n%s" % [step + 1, LESSONS.size(), current["title"], current["body"]]


func record_action(action: StringName) -> bool:
	if is_complete():
		return false
	_seen_actions[action] = true
	var required_actions: Array = lesson().get("actions", [])
	if required_actions.is_empty():
		return false
	for required_action in required_actions:
		if not _seen_actions.has(StringName(required_action)):
			return false
	advance()
	return true


func advance() -> bool:
	if is_complete():
		return false
	step += 1
	_seen_actions.clear()
	return true


func can_continue_manually() -> bool:
	if is_complete():
		return false
	var required_actions: Array = lesson().get("actions", [])
	return required_actions.is_empty() or not _seen_actions.is_empty()
