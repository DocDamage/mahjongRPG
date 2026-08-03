extends RefCounted

signal investigation_updated()

var definition: Dictionary = {}
var chain_validated := false
var bargain_discovered := false
var choices: Dictionary = {}
var explained_rules: Dictionary = {}
var silas_alive_proven := false
var kings_reach_sites: Dictionary = {}
var final_warning_accepted := false


func register_definition(data: Dictionary) -> Error:
	if not definition.is_empty() or StringName(data.get("id", "")) != &"act_three" or not data.get("clue_chain", []) is Array or not data.get("altered_rules", []) is Array or not data.get("kings_reach_sites", []) is Array:
		return ERR_INVALID_DATA
	definition = data.duplicate(true)
	return OK


func validate_clue_chain(evidence) -> Error:
	if chain_validated or evidence == null:
		return ERR_ALREADY_IN_USE
	for clue_id_value in definition.get("clue_chain", []):
		if not evidence.has(StringName(clue_id_value)):
			return ERR_UNAVAILABLE
	chain_validated = true
	evidence.discover(&"investigation_chain_validated")
	investigation_updated.emit()
	return OK


func missing_clues(evidence) -> Array[StringName]:
	var missing: Array[StringName] = []
	if evidence == null:
		return missing
	for clue_id_value in definition.get("clue_chain", []):
		var clue_id := StringName(clue_id_value)
		if not evidence.has(clue_id):
			missing.append(clue_id)
	return missing


func journal_status() -> String:
	return "Chain: %s • bargain: %s • rules: %d/%d • Silas: %s • King's Reach: %d/%d • final warning: %s" % ["validated" if chain_validated else "incomplete", "discovered" if bargain_discovered else "unfound", explained_rules.size(), definition.get("altered_rules", []).size(), "proven alive" if silas_alive_proven else "unproven", kings_reach_sites.size(), definition.get("kings_reach_sites", []).size(), "recorded" if final_warning_accepted else "pending"]


func discover_bargain(evidence) -> Error:
	if not chain_validated:
		return ERR_UNAVAILABLE
	if bargain_discovered:
		return ERR_ALREADY_IN_USE
	bargain_discovered = true
	evidence.discover(&"silas_bargain_record")
	investigation_updated.emit()
	return OK


func choose_consequence(choice_id: StringName) -> Error:
	if not bargain_discovered or not choices.is_empty() or not _known_id("choices", choice_id):
		return ERR_UNAVAILABLE
	choices[choice_id] = true
	investigation_updated.emit()
	return OK


func explain_rule(rule_id: StringName, evidence) -> Error:
	if not bargain_discovered or not _known_id("altered_rules", rule_id) or explained_rules.has(rule_id):
		return ERR_UNAVAILABLE
	var rule: Dictionary = _entry("altered_rules", rule_id)
	var evidence_id := StringName(rule.get("evidence_id", ""))
	if not evidence_id.is_empty() and (evidence == null or not evidence.has(evidence_id)):
		return ERR_UNAVAILABLE
	explained_rules[rule_id] = true
	investigation_updated.emit()
	return OK


func prove_silas_alive(evidence) -> Error:
	if not bargain_discovered or not all_rules_explained() or silas_alive_proven:
		return ERR_UNAVAILABLE
	silas_alive_proven = true
	evidence.discover(&"silas_alive_signal")
	investigation_updated.emit()
	return OK


func can_enter_kings_reach() -> bool:
	return chain_validated and bargain_discovered and all_rules_explained() and silas_alive_proven


func explore_kings_reach(site_id: StringName) -> Error:
	if not can_enter_kings_reach() or not _known_id("kings_reach_sites", site_id) or kings_reach_sites.has(site_id):
		return ERR_UNAVAILABLE
	kings_reach_sites[site_id] = true
	investigation_updated.emit()
	return OK


func all_rules_explained() -> bool:
	var rules: Array = definition.get("altered_rules", [])
	if rules.is_empty():
		return false
	for rule_value in rules:
		if not explained_rules.has(StringName(rule_value.get("id", ""))):
			return false
	return true


func all_reach_sites_explored() -> bool:
	var sites: Array = definition.get("kings_reach_sites", [])
	if sites.is_empty():
		return false
	for site_value in sites:
		if not kings_reach_sites.has(StringName(site_value.get("id", ""))):
			return false
	return true


func accept_final_warning(public_life, community) -> Error:
	if final_warning_accepted or choices.is_empty() or not can_enter_kings_reach() or not all_reach_sites_explored() or public_life == null or not public_life.is_scheduled(&"final_championship") or community == null or not community.finale_support.has(&"community_allies_ready"):
		return ERR_UNAVAILABLE
	final_warning_accepted = true
	investigation_updated.emit()
	return OK


func snapshot() -> Dictionary:
	return {"chain_validated": chain_validated, "bargain_discovered": bargain_discovered, "choices": choices.duplicate(true), "explained_rules": explained_rules.duplicate(true), "silas_alive_proven": silas_alive_proven, "kings_reach_sites": kings_reach_sites.duplicate(true), "final_warning_accepted": final_warning_accepted}


func restore(data: Dictionary) -> Error:
	for key in ["choices", "explained_rules", "kings_reach_sites"]:
		if not data.get(key, {}) is Dictionary:
			return ERR_INVALID_DATA
	for rule_id_value in data["explained_rules"]:
		if not _known_id("altered_rules", StringName(rule_id_value)):
			return ERR_INVALID_DATA
	if data["choices"].size() > 1:
		return ERR_INVALID_DATA
	for choice_id_value in data["choices"]:
		if not _known_id("choices", StringName(choice_id_value)):
			return ERR_INVALID_DATA
	for site_id_value in data["kings_reach_sites"]:
		if not _known_id("kings_reach_sites", StringName(site_id_value)):
			return ERR_INVALID_DATA
	chain_validated = bool(data.get("chain_validated", false))
	bargain_discovered = bool(data.get("bargain_discovered", false))
	choices = data["choices"].duplicate(true)
	explained_rules = data["explained_rules"].duplicate(true)
	silas_alive_proven = bool(data.get("silas_alive_proven", false))
	kings_reach_sites = data["kings_reach_sites"].duplicate(true)
	final_warning_accepted = bool(data.get("final_warning_accepted", false))
	if (bargain_discovered and not chain_validated) or (silas_alive_proven and not can_enter_kings_reach()) or (final_warning_accepted and not all_reach_sites_explored()):
		return ERR_INVALID_DATA
	return OK


func _known_id(collection_key: StringName, target_id: StringName) -> bool:
	return not _entry(collection_key, target_id).is_empty()


func _entry(collection_key: StringName, target_id: StringName) -> Dictionary:
	for entry_value in definition.get(collection_key, []):
		if entry_value is Dictionary and StringName(entry_value.get("id", "")) == target_id:
			return entry_value
	return {}
