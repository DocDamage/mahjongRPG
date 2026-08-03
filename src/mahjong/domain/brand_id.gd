extends RefCounted

const ALL := [&"blue", &"dark", &"green", &"orange", &"pink", &"purple"]


static func is_valid(brand: StringName) -> bool:
	return brand in ALL
