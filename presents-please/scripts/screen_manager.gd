class_name ScreenManager
extends Node

@export var main_menu_scene: PackedScene
@export var game_over_scene: PackedScene
@export var game_scene: PackedScene

@onready var screen: Control = $Screen

var current_screen: Node

func show_screen(scene: PackedScene) -> void:
	if current_screen:
		current_screen.queue_free()
	
	current_screen = scene.instantiate()
	screen.add_child(current_screen)

func show_main_menu() -> void:
	show_screen(main_menu_scene)

func show_game() -> void:
	show_screen(game_scene)

func show_game_over() -> void:
	show_screen(game_over_scene)
