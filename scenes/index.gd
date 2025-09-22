extends Control

@onready var play_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/PlayButton
@onready var quit_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/QuitButton

var current_button_index: int = 0
var buttons = []

func _ready():
	buttons = [play_button, quit_button]
	update_button_selection()

func _process(_delta):
	if Input.is_action_just_pressed("up"):
		current_button_index = (current_button_index - 1) % buttons.size()
		if current_button_index < 0:
			current_button_index = buttons.size() - 1
		update_button_selection()
		
	elif Input.is_action_just_pressed("down"):
		current_button_index = (current_button_index + 1) % buttons.size()
		update_button_selection()

	elif Input.is_action_just_pressed("ok"):
		if current_button_index == 0:
			get_tree().change_scene_to_file("res://scenes/song_list.tscn")
		else:
			get_tree().quit()

func update_button_selection():
	for button in buttons:
		button.set_selected(false)
	
	buttons[current_button_index].set_selected(true)
