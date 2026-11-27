extends GutTest

const MAIN_SCENE = preload("res://scenes/main.tscn")

var game_manager: GameManager


func before_each():
	game_manager = MAIN_SCENE.instantiate()
	add_child_autofree(game_manager)


func test_ready_initializes_main_menu_and_zero_mistakes():
	assert_eq(game_manager.screen_manager.current_screen.name, "MainMenuScene")
	assert_eq(game_manager.mistakes, 0)
	assert_not_null(game_manager.day_manager.present_generator)


func test_start_game_loads_game_scene_and_starts_day_one():
	game_manager.start_game()

	assert_eq(game_manager.screen_manager.current_screen.name, "GameScene")
	assert_eq(game_manager.day_manager.current_day, 1)
	assert_eq(game_manager.day_manager.current_present, 1)
	assert_eq(game_manager.mistakes, 0)
	assert_not_null(game_manager.day_manager.current_pair)


func test_correct_decision_keeps_mistakes_unchanged_and_advances():
	game_manager.start_game()

	# True = burn (for defective), False = proceed (for valid)
	var correct_decision = game_manager.day_manager.current_pair.is_defective()
	game_manager.decide(correct_decision)

	assert_eq(game_manager.mistakes, 0)
	assert_eq(game_manager.day_manager.current_present, 2)


func test_wrong_decision_increments_mistakes_and_advances():
	game_manager.start_game()

	var wrong_decision = not game_manager.day_manager.current_pair.is_defective()
	game_manager.decide(wrong_decision)

	assert_eq(game_manager.mistakes, 1)
	assert_eq(game_manager.day_manager.current_present, 2)


func test_three_mistakes_shows_game_over_loss_screen():
	game_manager.start_game()

	for i in range(3):
		var wrong_decision = not game_manager.day_manager.current_pair.is_defective()
		game_manager.decide(wrong_decision)

	assert_eq(game_manager.mistakes, 3)
	assert_eq(game_manager.screen_manager.current_screen.name, "GameOverScene")
	assert_eq(game_manager.screen_manager.current_screen.main_label.text, "Game Over")
	assert_eq(game_manager.screen_manager.current_screen.mistakes_label.text, "MISTAKES MADE: 3")


func test_third_mistake_on_final_present_of_day_seven_still_loses():
	game_manager.start_game()
	game_manager.mistakes = 2
	game_manager.day_manager.current_day = 7
	game_manager.day_manager.current_present = game_manager.day_manager.total_presents

	var wrong_decision = not game_manager.day_manager.current_pair.is_defective()
	game_manager.decide(wrong_decision)

	assert_eq(
		game_manager.screen_manager.current_screen.main_label.text,
		"Game Over",
		"3rd mistake on the final present should lose, not overwrite with a Win screen"
	)


func test_completing_day_seven_shows_win_screen():
	game_manager.start_game()
	game_manager.day_manager.current_day = 7
	game_manager.day_manager.current_present = game_manager.day_manager.total_presents

	var correct_decision = game_manager.day_manager.current_pair.is_defective()
	game_manager.decide(correct_decision)

	assert_eq(game_manager.screen_manager.current_screen.name, "GameOverScene")
	assert_eq(game_manager.screen_manager.current_screen.main_label.text, "You Win!")
	assert_eq(game_manager.screen_manager.current_screen.days_label.text, "DAYS COMPLETED: 7")


func test_restart_from_game_over_resets_state():
	game_manager.start_game()
	for i in range(3):
		var wrong_decision = not game_manager.day_manager.current_pair.is_defective()
		game_manager.decide(wrong_decision)

	# Wait one frame so Godot finishes queue_free() on the previous GameScene
	await get_tree().process_frame

	# Simulate clicking the Restart button on GameOverScene
	game_manager.screen_manager.current_screen.get_node("RestartButton").pressed.emit()

	assert_eq(game_manager.screen_manager.current_screen.name, "GameScene")
	assert_eq(game_manager.mistakes, 0)
	assert_eq(game_manager.day_manager.current_day, 1)
	assert_eq(game_manager.day_manager.current_present, 1)
