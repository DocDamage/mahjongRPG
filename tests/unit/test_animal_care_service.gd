extends RefCounted

const AnimalCareService = preload("res://src/animals/animal_care_service.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var animals = AnimalCareService.new()
	var definition := {"id": "hens", "display_name": "Hens", "product_id": "animal_egg", "product_quantity": 2}
	if animals.register_definition(definition) != OK or animals.feed(&"hens", 1) != OK:
		failures.append("animal groups should register and accept one daily feeding")
	animals.advance_to_day(2)
	if animals.collect(&"hens", 2) != 2 or animals.happiness(&"hens") != 65:
		failures.append("fed animal groups should raise happiness and produce on the next day")
	if animals.feed(&"hens", 2) != OK or animals.feed(&"hens", 2) != ERR_ALREADY_IN_USE:
		failures.append("animal groups should reject duplicate daily feeding")
	animals.advance_to_day(3)
	var restored = AnimalCareService.new()
	restored.register_definition(definition)
	if restored.restore(animals.snapshot()) != OK or restored.snapshot() != animals.snapshot():
		failures.append("animal care state should round-trip through saves")
	return failures
