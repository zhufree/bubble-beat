extends Control

class_name GameResultModal

@onready var background: ColorRect = $Background
@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ComboLabel
@onready var return_button: Button = $CenterContainer/ModalPanel/VBoxContainer/ReturnButton

func _ready():
	EventBus.game_finished.connect(_on_game_finished)
	visible = false

func _on_game_finished(final_score: int, max_combo: int):
	show_result(final_score, max_combo)

func show_result(final_score: int, max_combo: int):
	score_label.text = "Final Score: " + str(final_score)
	combo_label.text = "Max Combo: " + str(max_combo)
	
	visible = true
	
	var tween = create_tween()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(func(): return_button.grab_focus())

func _on_return_button_pressed():
	get_tree().change_scene_to_file("res://scenes/song_list.tscn")

func _input(event):
	if visible and event.is_action_pressed("ok"):
		_on_return_button_pressed()
