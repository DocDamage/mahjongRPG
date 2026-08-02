extends RefCounted

const BrandId = preload("res://src/mahjong/domain/brand_id.gd")

var identity
var brand: StringName


func _init(next_identity, next_brand: StringName) -> void:
	identity = next_identity
	brand = next_brand
	if identity == null or not identity.is_valid() or not BrandId.is_valid(brand):
		push_error("Invalid Mahjong tile")


func identity_key() -> String:
	return identity.key()


func key() -> String:
	return "%s|%s" % [identity_key(), brand]
