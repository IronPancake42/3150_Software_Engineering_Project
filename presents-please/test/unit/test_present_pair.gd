extends GutTest

func test_present_stores_init_values():
	var present = Present.new("Teddy Bear", "teddy_1", 1)

	assert_eq(present.name, "Teddy Bear")
	assert_eq(present.asset, "teddy_1")
	assert_eq(present.variant, 1)


func test_letter_stores_init_values():
	var letter = Letter.new("Dear Santa, I want a bear", 2)

	assert_eq(letter.letter_content, "Dear Santa, I want a bear")
	assert_eq(letter.variant, 2)


func test_pair_is_not_defective_when_variants_match():
	var present = Present.new("Teddy Bear", "teddy_1", 1)
	var letter = Letter.new("Dear Santa, I want a soft bear", 1)
	var pair = PresentPair.new(present, letter)

	assert_false(pair.is_defective(), "Matching variants should be a valid present")


func test_pair_is_defective_when_variants_differ():
	var present = Present.new("Pink Teddy Bear", "teddy_2", 2)
	var letter = Letter.new("Dear Santa, I want a soft bear", 1)
	var pair = PresentPair.new(present, letter)

	assert_true(pair.is_defective(), "Mismatched variants should be flagged as defective")
