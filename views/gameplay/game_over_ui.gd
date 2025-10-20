class_name GameOverUI
extends Control

## 游戏结束UI
## 显示游戏结果（胜利/失败）和最终分数
## 键盘控制：Enter重新开始，Esc返回列表

signal restart_requested
signal back_to_menu_requested

@onready var result_label: Label = $Panel/VBoxContainer/ResultLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $Panel/VBoxContainer/ComboLabel
@onready var time_bonus_label: Label = $Panel/VBoxContainer/TimeBonusLabel
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var panel: Panel = $Panel

var is_showing: bool = false

func _ready() -> void:
	# 默认隐藏
	hide()

func _input(event: InputEvent) -> void:
	if not is_showing:
		return

	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ENTER:
				_on_restart_pressed()
			KEY_ESCAPE:
				_on_back_to_menu_pressed()

## 显示游戏胜利界面
func show_victory(final_score: int, max_combo: int, time_bonus: int = 0) -> void:
	if result_label:
		result_label.text = "胜利！"
		result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3, 1.0))

	_show_score_info(final_score, max_combo, time_bonus)
	_show_with_animation()

## 显示游戏失败界面
func show_defeat(final_score: int, max_combo: int) -> void:
	if result_label:
		result_label.text = "失败"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

	if time_bonus_label:
		time_bonus_label.hide()

	_show_score_info(final_score, max_combo, 0)
	_show_with_animation()

## 显示分数信息
func _show_score_info(final_score: int, max_combo: int, time_bonus: int) -> void:
	if score_label:
		score_label.text = "最终分数: %d" % final_score

	if combo_label:
		combo_label.text = "最高连击: %d" % max_combo

	if time_bonus_label and time_bonus > 0:
		time_bonus_label.text = "时间奖励: +%d" % time_bonus
		time_bonus_label.show()
	elif time_bonus_label:
		time_bonus_label.hide()

	if hint_label:
		hint_label.text = "按 Enter 重新开始 | 按 Esc 返回列表"
		hint_label.show()

## 显示动画
func _show_with_animation() -> void:
	is_showing = true
	show()

	# 从透明到不透明
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# 面板从小到大弹出
	if panel:
		panel.scale = Vector2(0.5, 0.5)
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BACK)
		scale_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)

## 重新开始 (Enter键)
func _on_restart_pressed() -> void:
	is_showing = false
	restart_requested.emit()

## 返回菜单 (Esc键)
func _on_back_to_menu_pressed() -> void:
	is_showing = false
	back_to_menu_requested.emit()
