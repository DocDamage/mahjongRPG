extends RefCounted

const ENDINGS := {
	&"protect_town:speak_truth": {"id": &"open_hall", "title": "The Open Hall", "category": "Mercy's Wake chooses a fair, public table."},
	&"protect_town:end_reign": {"id": &"mercy_at_sunrise", "title": "Mercy at Sunrise", "category": "Mercy's Wake is protected without inheriting the King's cruelty."},
	&"preserve_records:speak_truth": {"id": &"keeper_of_truth", "title": "Keeper of Truth", "category": "The Hall's records become a public defense against false claims."},
	&"preserve_records:end_reign": {"id": &"keeper_mercy", "title": "The Last Witness", "category": "The records preserve the truth after the King's reign ends."},
}


static func evaluate(consequence: StringName, response: StringName) -> Dictionary:
	var result: Dictionary = ENDINGS.get(StringName("%s:%s" % [consequence, response]), {})
	return result.duplicate(true)
