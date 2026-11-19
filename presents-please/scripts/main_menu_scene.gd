extends Control

signal play_request
signal quit_request

func _on_play_button_pressed() -> void:
	play_request.emit()

func _on_quit_button_pressed() -> void:
	quit_request.emit()
