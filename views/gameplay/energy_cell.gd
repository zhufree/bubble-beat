extends ColorRect
class_name EnergyCell

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_filled: bool = false

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

	if animate and animation_player:
		animation_player.play("fill")
	else:
		color = filled_color

# 清空能量格
func drain(animate: bool = true) -> void:
	if not is_filled:
		return

	is_filled = false

	if animate and animation_player:
		animation_player.play("drain")
	else:
		color = empty_color

# 开始满能量动画
func start_full_animation() -> void:
	if animation_player and is_filled:
		animation_player.play("pulse")

# 停止满能量动画
func stop_full_animation() -> void:
	if animation_player:
		animation_player.stop()
		if is_filled:
			color = filled_color
		else:
			color = empty_color

# 设置填充颜色
func set_filled_color(new_color: Color) -> void:
	filled_color = new_color
	if is_filled:
		color = filled_color
