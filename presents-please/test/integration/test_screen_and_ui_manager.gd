extends GutTest

const MAIN_SCENE = preload("res://scenes/main.tscn")
const GAME_SCENE = preload("res://scenes/game_scene.tscn")
const GAME_OVER_SCENE = preload("res://scenes/game_over_scene.tscn")


func test_screen_manager_swaps_scenes_and_frees_previous():
	var main = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	var screen_manager = main.screen_manager

	var menu_screen = screen_manager.current_screen
	assert_eq(menu_screen.name, "MainMenuScene", "Should boot onto the Main Menu")

	screen_manager.show_game()
	assert_true(menu_screen.is_queued_for_deletion(), "Old Main Menu should be queued for cleanup")
	var game_screen = screen_manager.current_screen
	assert_eq(game_screen.name, "GameScene")

	screen_manager.show_game_over()
	assert_true(game_screen.is_queued_for_deletion(), "Old Game Scene should be queued for cleanup")
	assert_eq(screen_manager.current_screen.name, "GameOverScene")


func test_game_scene_updates_ui_from_day_manager_signals():
	var game_scene = GAME_SCENE.instantiate()
	add_child_autofree(game_scene)

	var day_manager = autofree(DayManager.new())
	day_manager.setup(PresentGenerator.new())
	game_scene.setup(day_manager)

	day_manager.start_day()

	assert_eq(game_scene.day_counter_label.text, "DAY: 1")
	assert_eq(
		game_scene.letter_content_label.text,
		day_manager.current_pair.letter.letter_content,
		"Letter UI should match the generated pair's letter"
	)


func test_burn_button_emits_true_decision():
	var game_scene = GAME_SCENE.instantiate()
	add_child_autofree(game_scene)
	watch_signals(game_scene)

	game_scene.get_node("UI/BurnButton").pressed.emit()

	assert_signal_emitted_with_parameters(game_scene, "decision_request", [true])


func test_proceed_button_emits_false_decision():
	var game_scene = GAME_SCENE.instantiate()
	add_child_autofree(game_scene)
	watch_signals(game_scene)

	game_scene.get_node("UI/ProceedButton").pressed.emit()

	assert_signal_emitted_with_parameters(game_scene, "decision_request", [false])


func test_game_over_scene_displays_win_and_loss_stats():
	var game_over = GAME_OVER_SCENE.instantiate()
	add_child_autofree(game_over)

	game_over.setup(true, 7, 1)
	assert_eq(game_over.main_label.text, "You Win!")
	assert_eq(game_over.days_label.text, "DAYS COMPLETED: 7")
	assert_eq(game_over.mistakes_label.text, "MISTAKES MADE: 1")

	game_over.setup(false, 3, 3)
	assert_eq(game_over.main_label.text, "Game Over")
	assert_eq(game_over.days_label.text, "DAYS COMPLETED: 3")
	assert_eq(game_over.mistakes_label.text, "MISTAKES MADE: 3")
