extends RefCounted

const CropDefinition = preload("res://src/crops/crop_definition.gd")
const CropInstance = preload("res://src/crops/crop_instance.gd")
const FarmGrid = preload("res://src/farm/farm_grid.gd")
const FarmService = preload("res://src/farm/farm_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var grid = FarmGrid.new(Rect2i(0, 0, 4, 4))
	grid.set_blocked(Vector2i(0, 0))
	grid.set_required_path([Vector2i(1, 0)])
	var farm = FarmService.new(grid)
	var beans = CropDefinition.new({"id": "beans", "days_to_mature": 3, "wilt_after_days": 2, "die_after_days": 4})
	farm.register_definition(beans)
	if farm.plant(Vector2i(1, 1), &"beans", 1) != ERR_UNAVAILABLE:
		failures.append("crops should require a placed field")
	if farm.place_field(Vector2i(0, 0)) != ERR_ALREADY_EXISTS:
		failures.append("blocked terrain must reject placement")
	if farm.place_field(Vector2i(1, 0)) != ERR_UNAVAILABLE:
		failures.append("required routes must not be sealed by placement")
	var plot := Vector2i(1, 1)
	if farm.place_field(plot) != OK or farm.place_field(plot) != ERR_ALREADY_EXISTS:
		failures.append("farm fields must reject overlapping placement")
	if farm.plant(plot, &"beans", 1) != OK or farm.plant(plot, &"beans", 1) != ERR_ALREADY_EXISTS:
		failures.append("farm grid must reject overlapping crops")
	if farm.remove_field(plot) != ERR_BUSY:
		failures.append("fields with crops must not be removable")
	for day in range(1, 4):
		farm.water(plot, day)
		farm.advance_to_day(day + 1)
	if farm.crop_at(plot).state != CropInstance.State.READY:
		failures.append("watered crops should reach a harvest-ready state")
	if farm.harvest(plot).get("crop_id", "") != "beans" or grid.is_occupied(plot):
		failures.append("harvesting should produce the crop and release its grid cell")
	if farm.remove_field(plot) != OK or farm.has_field(plot):
		failures.append("empty fields should be safely removable")
	if farm.place_field(plot) != OK:
		failures.append("a removed field should be placeable again")
	var snapshot := farm.snapshot()
	var restored = FarmService.new(FarmGrid.new(Rect2i(0, 0, 4, 4)))
	restored.register_definition(beans)
	if restored.restore(snapshot) != OK or not restored.has_field(plot):
		failures.append("placed fields should survive a farm save round-trip")
	var neglected = CropInstance.new(beans, 1)
	neglected.advance_to_day(3)
	if neglected.state != CropInstance.State.WILTED:
		failures.append("neglected crops should wilt before dying")
	neglected.water(3)
	if neglected.state != CropInstance.State.GROWING:
		failures.append("watered wilted crops should recover")
	neglected.advance_to_day(8)
	if neglected.state != CropInstance.State.DEAD:
		failures.append("continued neglect should eventually kill crops")
	return failures
