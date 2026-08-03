extends RefCounted

const BrandId = preload("res://src/mahjong/domain/brand_id.gd")

const CHARGES_PER_ACTIVATION := 3
const MAX_ACTIVATIONS := 2

var equipped: Array[StringName] = []
var _charges: Dictionary = {}
var _activations: Dictionary = {}


func configure(loadout: Array[StringName]) -> Error:
	if loadout.size() != 2 or loadout[0] == loadout[1]:
		return ERR_INVALID_PARAMETER
	for brand in loadout:
		if not BrandId.is_valid(brand):
			return ERR_INVALID_PARAMETER
	equipped = loadout.duplicate()
	reset_for_hand()
	return OK


func reset_for_hand() -> void:
	_charges.clear()
	_activations.clear()
	for brand in equipped:
		_charges[brand] = 0
		_activations[brand] = 0


func record_discard(brand: StringName) -> void:
	grant_charge(brand)


func grant_charge(brand: StringName) -> void:
	if not equipped.has(brand) or activations(brand) >= MAX_ACTIVATIONS:
		return
	_charges[brand] = charges(brand) + 1
	if charges(brand) >= CHARGES_PER_ACTIVATION:
		_activations[brand] = activations(brand) + 1
		_charges[brand] = 0


func charges(brand: StringName) -> int:
	return int(_charges.get(brand, 0))


func activations(brand: StringName) -> int:
	return int(_activations.get(brand, 0))


func consume_activation(brand: StringName) -> bool:
	if activations(brand) <= 0:
		return false
	_activations[brand] = activations(brand) - 1
	return true
