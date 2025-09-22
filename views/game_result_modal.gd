extends Control

class_name GameResultModal

@onready var background: ColorRect = $Background
@onready var modal_panel: Panel = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ComboLabel
@onready var return_button: Button = $CenterContainer/ModalPanel/VBoxContainer/ReturnButton

signal return_to_song_list

func _ready():
	# 连接按钮信号
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 连接游戏结束信号
	EventBus.game_finished.connect(_on_game_finished)
	
	# 初始时隐藏
	visible = false

func _on_game_finished(final_score: int, max_combo: int):
	show_result(final_score, max_combo)

func show_result(final_score: int, max_combo: int):
	score_label.text = "最终得分: " + str(final_score)
	combo_label.text = "最高连击: " + str(max_combo)
	
	# 显示弹窗
	visible = true
	
	# 添加显示动画
	var tween = create_tween()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(func(): return_button.grab_focus())

func _on_return_button_pressed():
	# 发送返回信号
	return_to_song_list.emit()
	
	# 切换回歌曲列表场景
	get_tree().change_scene_to_file("res://scenes/song_list.tscn")

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_return_button_pressed()
