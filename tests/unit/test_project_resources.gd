extends RefCounted

const SOURCE_ROOT := "res://src"


func run() -> Array[String]:
	var failures: Array[String] = []
	var paths: Array[String] = []
	_collect_paths(SOURCE_ROOT, paths, failures)
	paths.sort()
	for path in paths:
		var resource: Resource = load(path)
		if resource == null:
			failures.append("unable to load resource: %s" % path)
			continue
		if path.ends_with(".gd") and resource is Script and not resource.can_instantiate():
			failures.append("script cannot instantiate: %s" % path)
		if path.ends_with(".tscn") and resource is PackedScene and not resource.can_instantiate():
			failures.append("scene cannot instantiate: %s" % path)
	return failures


func _collect_paths(directory_path: String, paths: Array[String], failures: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("unable to inspect source directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var path := directory_path.path_join(entry)
			if directory.current_is_dir():
				_collect_paths(path, paths, failures)
			elif entry.ends_with(".gd") or entry.ends_with(".tscn"):
				paths.append(path)
		entry = directory.get_next()
	directory.list_dir_end()
