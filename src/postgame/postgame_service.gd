extends RefCounted

const JournalSummary = preload("res://src/journal/journal_summary.gd")

signal postgame_entered(ending_id: StringName)

var active := false
var ending_provenance: StringName = &""


func enter(finale, _public_life) -> Error:
	if active or finale == null or not finale.credits_seen or finale.ending_id.is_empty():
		return ERR_UNAVAILABLE
	active = true
	ending_provenance = finale.ending_id
	postgame_entered.emit(ending_provenance)
	return OK


func is_active() -> bool:
	return active


func collection_summary(session) -> Dictionary:
	var journal := JournalSummary.summary(session)
	journal["ending_provenance"] = ending_provenance
	return journal


func snapshot() -> Dictionary:
	return {"active": active, "ending_provenance": str(ending_provenance)}


func restore(data: Dictionary) -> Error:
	var next_active := bool(data.get("active", false))
	var next_provenance := StringName(data.get("ending_provenance", ""))
	if next_active and next_provenance.is_empty():
		return ERR_INVALID_DATA
	if not next_active and not next_provenance.is_empty():
		return ERR_INVALID_DATA
	active = next_active
	ending_provenance = next_provenance
	return OK
