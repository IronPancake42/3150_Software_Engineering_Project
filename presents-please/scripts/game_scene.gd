extends Node2D

@onready var present_sprite_2d: Sprite2D = $PresentSprite2D
@onready var letter_content_label: Label = $UI/LetterContentLabel
@onready var day_counter_label: Label = $UI/DayCounterLabel
@onready var mistake_counter_label: Label = $UI/MistakeCounterLabel

var day_manager: DayManager

signal decision_request(defect: bool)

func setup(manager):
	day_manager = manager
	day_manager.day_started.connect(set_day)
	day_manager.present_changed.connect(present_changed)

func set_day(day: int) -> void:
	day_counter_label.text = "DAY: %d" % day

func present_changed(present_pair: PresentPair) -> void:
	letter_content_label.text = present_pair.letter.letter_content
	var path = "res://assets_psx/" + present_pair.present.asset + ".png"
	present_sprite_2d.texture = load(path)

func _on_burn_button_pressed() -> void:
	decision_request.emit(true)

func _on_proceed_button_pressed() -> void:
	decision_request.emit(false)
