extends GutTest

var generator: PresentGenerator


func before_each():
	generator = PresentGenerator.new()


func test_presents_json_data_loaded():
	assert_gt(PresentGenerator.PRESENTS.size(), 0, "presents.json should have at least one entry")


func test_generate_pair_returns_valid_objects():
	var pair = generator.generate_pair()

	assert_not_null(pair)
	assert_not_null(pair.present)
	assert_not_null(pair.letter)


func test_generate_pair_uses_matching_data_for_selected_variants():
	# Run multiple times because generate_pair() relies on RNG
	for i in range(30):
		var pair = generator.generate_pair()
		var found_matching_entry = false

		for entry in PresentGenerator.PRESENTS:
			var p_idx = pair.present.variant - 1
			var l_idx = pair.letter.variant - 1

			if p_idx >= 0 and p_idx < entry["names"].size() and l_idx >= 0 and l_idx < entry["letter_contents"].size():
				if (
					entry["names"][p_idx] == pair.present.name
					and entry["assets"][p_idx] == pair.present.asset
					and entry["letter_contents"][l_idx] == pair.letter.letter_content
				):
					found_matching_entry = true
					break

		assert_true(found_matching_entry, "Generated pair fields should match an entry in presents.json")


func test_get_different_variant_never_returns_original():
	var max_variants = 3
	for original in range(1, max_variants + 1):
		for i in range(30):
			var result = generator.get_different_variant(original, max_variants)
			assert_ne(result, original, "Should not return the original variant")
			assert_between(result, 1, max_variants, "Variant must stay in valid 1..max range")


func test_get_different_variant_works_with_two_variants():
	assert_eq(generator.get_different_variant(1, 2), 2)
	assert_eq(generator.get_different_variant(2, 2), 1)
