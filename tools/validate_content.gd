extends SceneTree

const ContentValidationReport = preload("res://src/content/content_validation_report.gd")


func _init() -> void:
	var report: Dictionary = ContentValidationReport.validate_repository()
	print(ContentValidationReport.format_report(report))
	quit(0 if report.get("errors", []).is_empty() else 1)
