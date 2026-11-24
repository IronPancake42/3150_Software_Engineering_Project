class_name GameManager
extends Node

@onready var day_manager: DayManager = $DayManager
@onready var screen_manager: ScreenManager = $ScreenManager

var present_generator = PresentGenerator.new()
var mistakes := 0

func _ready() -> void:
	show_main_menu()
	present_generator = PresentGenerator.new()
	day_manager.setup(present_generator)
	day_manager.last_day_ended.connect(end_game)

func show_main_menu() -> void:
	screen_manager.show_main_menu()
	var screen = screen_manager.current_screen
	screen.play_request.connect(start_game)
	screen.quit_request.connect(quit_game)

func start_game() -> void:
	show_game()
	day_manager.reset()
	day_manager.start_day()
	mistakes = 0

func show_game() -> void:
	screen_manager.show_game()
	var screen = screen_manager.current_screen
	screen.setup(day_manager)
	screen.decision_request.connect(decide)

func decide(defect: bool) -> void:
	if day_manager.current_pair.is_defective() != defect:
		mistakes += 1
		if mistakes == 3:
			end_game(false)
			return
	day_manager.next_present()

func end_game(win: bool) -> void:
	show_game_over(win)

func show_game_over(win: bool) -> void:
	screen_manager.show_game_over()
	var screen = screen_manager.current_screen
	screen.setup(win, day_manager.current_day, mistakes)
	screen.restart_request.connect(start_game)
	screen.quit_request.connect(quit_game)

func quit_game() -> void:
	get_tree().quit()

#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
