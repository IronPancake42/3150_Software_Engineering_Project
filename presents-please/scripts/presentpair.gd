class_name PresentPair
extends RefCounted

var present: Present
var letter: Letter

func _init(p: Present, l: Letter) -> void:
	present = p
	letter = l

func is_defective() -> bool:
	return present.variant != letter.variant
