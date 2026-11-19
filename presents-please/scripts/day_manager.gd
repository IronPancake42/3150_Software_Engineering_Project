class_name DayManager
extends Node

signal day_started(day: int)
signal present_changed(pair: PresentPair)
signal last_day_ended(win: bool)

var current_day := 0
var total_presents := 5
var current_present := 0

var current_pair: PresentPair
var present_generator: PresentGenerator

func setup(generator: PresentGenerator) -> void:
	present_generator = generator

func reset() -> void:
	current_day = 0
	current_present = 0

func start_day() -> void:
	current_day += 1
	day_started.emit(current_day)
	next_present()

func next_present() -> void:
	current_present += 1
	
	if current_present >= total_presents:
		end_day()
	else:
		current_pair = present_generator.generate_pair()
		present_changed.emit(current_pair)

func end_day() -> void:
	if current_day == 7:
		last_day_ended.emit(true)
	current_present = 0
	start_day()
