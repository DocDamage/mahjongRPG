extends RefCounted

const FishCatalog = preload("res://src/fishing/fish_catalog.gd")

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
	var community_total := 0
	if session.community != null:
		for definition_value in session.community.definitions.values():
			if not StringName(definition_value.get("secret_id", "")).is_empty():
				community_total += 1
	var groups := {
		"fish_records": {"found": session.angler.records.size(), "total": FishCatalog.definitions().size()},
		"community_secrets": {"found": session.community.discovered_secrets.size(), "total": community_total},
		"desert_records": {"found": session.desert.supernatural_records.size() + session.desert.region_secrets.size(), "total": 2},
	}
	var found := 0
	var total := 0
	for group_value in groups.values():
		found += int(group_value["found"])
		total += int(group_value["total"])
	return {"ending_provenance": ending_provenance, "groups": groups, "total_found": found, "total_available": total, "complete": total > 0 and found >= total}


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
