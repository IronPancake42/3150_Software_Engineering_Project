class_name Present
extends RefCounted

var name: String
var asset: String
var variant: int

func _init(name_: String, asset_: String, variant_: int) -> void:
	name = name_
	asset = asset_
	variant = variant_
