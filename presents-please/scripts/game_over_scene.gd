extends Control

@onready var main_label: Label = $MainLabel
@onready var days_label: Label = $DaysLabel
@onready var mistakes_label: Label = $MistakesLabel

signal restart_request
signal quit_request

func setup(win: bool, days: int, mistakes: int):
	main_label.text = "You Win!" if win else "Game Over"
	days_label.text = "DAYS COMPLETED: %d" % days
	mistakes_label.text = "MISTAKES MADE: %d" % mistakes

func _on_restart_button_pressed() -> void:
	restart_request.emit()

func _on_quit_button_pressed() -> void:
	quit_request.emit()
