extends RefCounted

const RuntimeAssetCatalog = preload("res://src/content/runtime_asset_catalog.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	for direction in [&"up", &"down", &"left", &"right"]:
		for action in [&"walk", &"idle", &"draw", &"armed", &"shoot"]:
			var path := RuntimeAssetCatalog.hero_texture_path(direction, action)
			if path.is_empty() or not ResourceLoader.exists(path):
				failures.append("missing runtime hero mapping: %s/%s" % [direction, action])
	for color in [&"black", &"brown", &"golden", &"gray", &"white"]:
		var path := RuntimeAssetCatalog.horse_texture_path(color)
		if path.is_empty() or not ResourceLoader.exists(path):
			failures.append("missing runtime horse mapping: %s" % color)
	if RuntimeAssetCatalog.hero_frame_size() != Vector2i(64, 64):
		failures.append("hero catalog should retain its authored animation grid")
	var expected_counts := {&"walk": 8, &"idle": 15, &"draw": 6, &"armed": 1, &"shoot": 3}
	for action in expected_counts:
		if RuntimeAssetCatalog.hero_frame_count(action) != expected_counts[action]:
			failures.append("hero catalog should retain the authored frame count for %s" % action)
	return failures
