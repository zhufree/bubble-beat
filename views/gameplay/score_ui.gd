extends Control

@onready var score_label: Label = $Panel/MarginContainer/VBoxContainer/ScoreContainer/ScoreLabel
@onready var combo_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ComboContainer
@onready var combo_label: Label = $Panel/MarginContainer/VBoxContainer/ComboContainer/ComboLabel
@onready var multiplier_label: Label = $Panel/MarginContainer/VBoxContainer/ComboContainer/MultiplierLabel

var current_score: int = 0
var current_combo: int = 0
var current_multiplier: float = 1.0

func _ready() -> void:
	update_score(0, 0, 1.0)

# 更新分数显示
func update_score(score: int, combo: int, multiplier: float) -> void:
	# 更新分数
	if score != current_score:
		_animate_score_change(current_score, score)
		current_score = score

	# 更新 combo
	if combo != current_combo or multiplier != current_multiplier:
		current_combo = combo
		current_multiplier = multiplier
		_update_combo_display()

# 分数变化动画
func _animate_score_change(from: int, to: int) -> void:
	# 数字滚动动画
	var tween = create_tween()
	tween.tween_method(_set_score_text, float(from), float(to), 0.3)

	# 脉冲效果
	var pulse_tween = create_tween()
	pulse_tween.tween_property(score_label, "scale", Vector2(1.15, 1.15), 0.1)
	pulse_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.15)

# 设置分数文本
func _set_score_text(value: float) -> void:
	score_label.text = str(int(value))

# 更新 combo 显示
func _update_combo_display() -> void:
	if current_combo == 0:
		combo_container.visible = false
		return

	combo_container.visible = true
	combo_label.text = str(current_combo) + " COMBO"

	# 根据倍率设置显示样式
	var color: Color
	var font_size: int
	var show_glow: bool = false

	if current_multiplier >= 10.0:
		color = Color(1.0, 0.2, 1.0, 1.0)  # 紫色
		font_size = 48
		show_glow = true
	elif current_multiplier >= 5.0:
		color = Color(1.0, 0.1, 0.1, 1.0)  # 红色
		font_size = 42
		show_glow = true
	elif current_multiplier >= 3.0:
		color = Color(1.0, 0.5, 0.0, 1.0)  # 橙色
		font_size = 36
	elif current_multiplier >= 2.0:
		color = Color(1.0, 1.0, 0.0, 1.0)  # 黄色
		font_size = 32
	else:
		color = Color(0.5, 1.0, 0.5, 1.0)  # 绿色
		font_size = 28

	combo_label.add_theme_color_override("font_color", color)
	combo_label.add_theme_font_size_override("font_size", font_size)

	# 显示倍率
	if current_multiplier > 1.0:
		multiplier_label.text = "x" + str(current_multiplier)
		multiplier_label.add_theme_color_override("font_color", color)
		multiplier_label.visible = true
	else:
		multiplier_label.visible = false

	# Combo 增加时的动画
	var combo_tween = create_tween()
	combo_tween.set_parallel(true)
	combo_tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
	combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)

	# 高倍率震动效果
	if show_glow:
		_create_shake_effect()

# 震动效果
func _create_shake_effect() -> void:
	var original_pos = combo_container.position
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(combo_container, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(combo_container, "position", original_pos - Vector2(5, 0), 0.05)
	tween.finished.connect(func(): combo_container.position = original_pos)
