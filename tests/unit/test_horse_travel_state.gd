extends RefCounted

const HorseTravelState = preload("res://src/horses/horse_travel_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var horse = HorseTravelState.new()
	if horse.mount(false) != ERR_UNAVAILABLE or horse.mount(true) != OK:
		failures.append("horse mounting must reject invalid locations and accept valid ones")
	horse.discover(&"wayward_farm")
	if not horse.can_fast_travel(&"wayward_farm"):
		failures.append("mounted players should travel only to discovered hitching posts")
	if horse.dismount(false) != ERR_UNAVAILABLE or horse.dismount(true) != OK:
		failures.append("horse dismounting must require a safe position")
	var restored = HorseTravelState.new()
	if restored.restore(horse.snapshot()) != OK or restored.snapshot() != horse.snapshot():
		failures.append("horse selection and discovered posts must be saveable")
	return failures
