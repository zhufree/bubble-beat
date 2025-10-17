extends ColorRect
class_name EnergyCell

var is_filled: bool = false
var pulse_tween: Tween

# 颜色配置
var empty_color: Color = Color(0.2, 0.2, 0.25, 0.4)  # 深色半透明
var filled_color: Color = Color(1.0, 0.8, 0.2, 1.0)  # 金黄色

func _ready() -> void:
	color = empty_color

# 填充能量格
func fill(animate: bool = true) -> void:
	if is_filled:
		return

	is_filled = true

	# 停止可能存在的脉冲动画
	stop_full_animation()

	if animate:
		# 使用 Tween 创建填充动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		# 颜色过渡：empty -> bright -> filled
		var bright_color = Color(
			filled_color.r * 1.3,
			filled_color.g * 1.3,
			filled_color.b * 1.3,
			1.0
		)

		# 第一阶段：放大到亮色
		tween.set_parallel(true)
		tween.tween_property(self, "color", bright_color, 0.15)
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)

		# 第二阶段：恢复到正常状态
		tween.set_parallel(false)
		tween.tween_property(self, "color", filled_color, 0.15)
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		color = filled_color

# 清空能量格
func drain(animate: bool = true) -> void:
	if not is_filled:
		return

	is_filled = false

	# 停止脉冲动画
	stop_full_animation()

	if animate:
		# 使用 Tween 创建清空动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "color", empty_color, 0.2)
	else:
		color = empty_color

# 开始满能量动画
func start_full_animation() -> void:
	if not is_filled:
		return

	# 停止之前的脉冲动画
	if pulse_tween:
		pulse_tween.kill()

	# 创建循环脉冲动画
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.set_trans(Tween.TRANS_SINE)

	# 颜色脉冲
	var bright_color = Color(
		filled_color.r * 1.3,
		filled_color.g * 1.3,
		filled_color.b * 1.3,
		1.0
	)

	# 第一阶段：变亮放大
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(self, "color", bright_color, 0.5)
	pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5)

	# 第二阶段：恢复正常
	pulse_tween.set_parallel(false)
	pulse_tween.tween_property(self, "color", filled_color, 0.5)
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

# 停止满能量动画
func stop_full_animation() -> void:
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null

	# 恢复到正常状态
	scale = Vector2(1.0, 1.0)
	if is_filled:
		color = filled_color
	else:
		color = empty_color

# 设置填充颜色
func set_filled_color(new_color: Color) -> void:
	filled_color = new_color
	if is_filled:
		color = filled_color
