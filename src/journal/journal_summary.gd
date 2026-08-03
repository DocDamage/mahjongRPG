extends RefCounted

const FishCatalog = preload("res://src/fishing/fish_catalog.gd")


static func summary(session) -> Dictionary:
	var secret_total := 0
	for definition_value in session.community.definitions.values():
		if not StringName(definition_value.get("secret_id", "")).is_empty():
			secret_total += 1
	var groups := {
		"evidence": _group(session.evidence.discovered.size(), session.evidence.definitions.size()),
		"brands": _group(session.brands.unlocked.size(), 6),
		"fish_records": _group(session.angler.records.size(), FishCatalog.definitions().size()),
		"community_arcs": _group(session.community.completed.size(), session.community.definitions.size()),
		"community_secrets": _group(session.community.discovered_secrets.size(), secret_total),
		"property_cases": _group(session.properties.outcomes.size(), session.properties.definitions.size()),
		"desert_records": _group(session.desert.supernatural_records.size() + session.desert.region_secrets.size(), 2),
	}
	var found := 0
	var total := 0
	for group_value in groups.values():
		found += int(group_value["found"])
		total += int(group_value["total"])
	return {"groups": groups, "total_found": found, "total_available": total, "complete": total > 0 and found >= total}


static func concise_lines(session) -> Array[String]:
	var lines: Array[String] = []
	var groups: Dictionary = summary(session)["groups"]
	for group_id_value in groups:
		var group: Dictionary = groups[group_id_value]
		lines.append("%s %d/%d" % [String(group_id_value).replace("_", " "), int(group["found"]), int(group["total"])])
	lines.sort()
	return lines


static func _group(found: int, total: int) -> Dictionary:
	return {"found": found, "total": total}
