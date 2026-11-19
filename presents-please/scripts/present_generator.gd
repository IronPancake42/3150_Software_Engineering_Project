class_name PresentGenerator
extends RefCounted

const PRESENTS = preload("res://data/presents.json").data

func generate_pair() -> PresentPair:
	var entry = PRESENTS.pick_random()
	var variant_count = entry["names"].size()
	
	var original_variant = randi_range(1, variant_count)
	
	var present_variant = original_variant
	var letter_variant = original_variant
	
	if randf() < 0.30:
		present_variant = get_different_variant(original_variant, variant_count)
	if randf() < 0.30:
		letter_variant = get_different_variant(original_variant, variant_count)
	
	var present = Present.new(
		entry["names"][present_variant - 1], 
		entry["assets"][present_variant - 1], 
		present_variant
	)
	
	var letter = Letter.new(
		entry["letter_contents"][letter_variant - 1],
		letter_variant
	)
	
	return PresentPair.new(present, letter)

#https://www.reddit.com/r/learnjavascript/s/X5xhABLTgf
func get_different_variant(original: int, max_variants: int) -> int:
	var variant = randi_range(1, max_variants - 1)
	if variant >= original:
		variant += 1
	return variant
