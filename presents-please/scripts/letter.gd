class_name Letter
extends RefCounted

var letter_content: String
var variant: int

func _init(letter_content_: String, variant_: int) -> void:
	letter_content = letter_content_
	variant = variant_
