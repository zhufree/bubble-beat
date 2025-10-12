extends Control

@onready var play_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/PlayButton
@onready var bird_house_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/BirdHouseButton
@onready var atlas_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/AtlasButton
@onready var quit_button: HBoxContainer = $ColorRect/MarginContainer/VBoxContainer/QuitButton

var current_button_index: int = 0
var buttons = []

func _ready():
	buttons = [play_button,bird_house_button, atlas_button, quit_button]
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
		print("按钮按下，当前索引: ", current_button_index)
		if current_button_index == 0:
			print("跳转到歌曲列表")
			get_tree().change_scene_to_file("res://scenes/song_list.tscn")
		elif current_button_index == 1:
			print("跳转到鸟屋")
			var result = get_tree().change_scene_to_file("res://views/bird_house/bird_house_panel.tscn")
			print("场景切换结果: ", result)
		elif current_button_index == 2:
			print("跳转到图鉴")
			get_tree().change_scene_to_file("res://views/atlas/atlas_panel.tscn")
		else:
			print("退出游戏")
			get_tree().quit()

func update_button_selection():
	for button in buttons:
		button.set_selected(false)
	
	buttons[current_button_index].set_selected(true)
