extends RefCounted

const ContentValidationReport = preload("res://src/content/content_validation_report.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var report: Dictionary = ContentValidationReport.validate_repository()
	if not report.get("errors", []).is_empty():
		failures.append("production content catalogs should pass the shared validation report: %s" % report.get("errors", []))
	for required_key in ["errors", "warnings", "source_lengths", "summary"]:
		if not report.has(required_key):
			failures.append("content report must include contributor-facing %s output" % required_key)
	_test_invalid_catalog_diagnostics(failures)
	_test_source_policy_report(failures)
	_test_advisory_files(failures)
	return failures


func _test_invalid_catalog_diagnostics(failures: Array[String]) -> void:
	var catalogs: Dictionary = ContentValidationReport.load_catalogs()
	var quests: Dictionary = catalogs["quests"].duplicate(true)
	quests["schema_version"] = 99
	catalogs["quests"] = quests
	var dialogue: Dictionary = catalogs["dialogue"].duplicate(true)
	dialogue["sequences"][0]["nodes"][0]["text_key"] = "missing.key"
	catalogs["dialogue"] = dialogue
	var report: Dictionary = ContentValidationReport.validate_catalogs(catalogs)
	if not _has_fragment(report.get("errors", []), "unsupported quest catalog schema"):
		failures.append("content report must identify unsupported quest schema versions")
	if not _has_fragment(report.get("errors", []), "localization key does not exist"):
		failures.append("content report must identify missing dialogue references with production validators")
	var missing_title := ContentValidationReport.load_catalogs()
	missing_title["quests"]["quests"][0]["title_key"] = "quest.missing.title"
	if not _has_fragment(ContentValidationReport.validate_catalogs(missing_title).get("errors", []), "quest title localization key does not exist"):
		failures.append("content report must identify missing quest title localization references")
	var newer: Dictionary = ContentValidationReport.load_catalogs()
	newer["quests"]["quests"][0]["required_save_schema"] = 22
	if not _has_fragment(ContentValidationReport.validate_catalogs(newer).get("errors", []), "requires save schema 22"):
		failures.append("content report must reject quests requiring a newer save schema")
	newer["quests"]["quests"][0]["required_save_schema"] = "future"
	if not _has_fragment(ContentValidationReport.validate_catalogs(newer).get("errors", []), "required save schema must be a positive integer"):
		failures.append("content report must reject malformed quest save-schema requirements")


func _test_source_policy_report(failures: Array[String]) -> void:
	var diagnostics: Dictionary = ContentValidationReport.validate_source_lengths({"src/new_ok.gd": 220, "src/review.gd": 250, "src/too_large.gd": 301})
	if not _has_fragment(diagnostics.get("warnings", []), "review.gd"):
		failures.append("handwritten files at the review threshold must be reported")
	if not _has_fragment(diagnostics.get("errors", []), "too_large.gd"):
		failures.append("handwritten files over policy maximum must fail content validation")


func _test_advisory_files(failures: Array[String]) -> void:
	for path in ["res://.pre-commit-config.yaml", "res://docs/contributing/content-validation.md", "res://tools/validate_content.gd"]:
		if not FileAccess.file_exists(path):
			failures.append("Q4 contributor tooling is missing: %s" % path)


func _has_fragment(diagnostics: Array, fragment: String) -> bool:
	for diagnostic in diagnostics:
		if fragment in String(diagnostic):
			return true
	return false
