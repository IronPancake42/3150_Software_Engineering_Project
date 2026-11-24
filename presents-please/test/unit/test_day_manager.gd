extends GutTest

var day_manager: DayManager
var generator: PresentGenerator


func before_each():
	generator = PresentGenerator.new()
	day_manager = autofree(DayManager.new())
	day_manager.setup(generator)
	watch_signals(day_manager)


func test_initial_state():
	assert_eq(day_manager.current_day, 0)
	assert_eq(day_manager.current_present, 0)
	assert_eq(day_manager.total_presents, 5)
	assert_null(day_manager.current_pair)


func test_start_day_increments_day_and_loads_first_present():
	day_manager.start_day()

	assert_eq(day_manager.current_day, 1)
	assert_eq(day_manager.current_present, 1)
	assert_not_null(day_manager.current_pair)
	assert_signal_emitted_with_parameters(day_manager, "day_started", [1])
	assert_signal_emitted(day_manager, "present_changed")


func test_reset_clears_day_and_present_counters():
	day_manager.start_day()
	day_manager.next_present()

	day_manager.reset()

	assert_eq(day_manager.current_day, 0)
	assert_eq(day_manager.current_present, 0)


func test_day_serves_all_total_presents_before_advancing_day():
	day_manager.start_day() # Present 1 of 5

	# Presents 2, 3, 4, and 5 should all still be on Day 1
	for expected_present in range(2, day_manager.total_presents + 1):
		day_manager.next_present()
		assert_eq(
			day_manager.current_day,
			1,
			"Should still be Day 1 while on present %d of %d" % [expected_present, day_manager.total_presents]
		)

	# Finishing the 5th present should start Day 2
	day_manager.next_present()
	assert_eq(day_manager.current_day, 2, "Should advance to Day 2 after all 5 presents")
	assert_eq(day_manager.current_present, 1, "Day 2 should start on present 1")


func test_finishing_day_seven_emits_win_and_stops():
	day_manager.current_day = 7
	day_manager.end_day()

	assert_signal_emitted_with_parameters(day_manager, "last_day_ended", [true])
	assert_eq(day_manager.current_day, 7, "Should not start a Day 8 after winning on Day 7")
