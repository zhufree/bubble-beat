extends Control
class_name ShieldOverlay

# 护盾颜色配置
@export var shield_color: Color = Color(0.3, 0.6, 1.0)  # 蓝色基调
@export var border_alpha: float = 0.65  # 边框透明度（低透明度，更明显）
@export var fill_alpha: float = 0.18    # 填充透明度（高透明度，不遮挡）
@export var border_width: float = 3.0
@export var corner_radius: float = 16.0

# 脉动动画配置
@export var pulse_enabled: bool = true
@export var pulse_speed: float = 2.0
@export var pulse_intensity: float = 0.15

var time: float = 0.0
var tween: Tween

func _ready() -> void:
	# 设置为不接收输入，完全透明传递
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 初始隐藏
	modulate.a = 0.0

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	
	# 计算脉动效果
	var pulse_factor = 1.0
	if pulse_enabled:
		pulse_factor = 1.0 + sin(time * pulse_speed) * pulse_intensity
	
	# 绘制填充
	var fill_color = Color(shield_color.r, shield_color.g, shield_color.b, fill_alpha * pulse_factor)
	_draw_rounded_rect_filled(Rect2(Vector2.ZERO, size), corner_radius, fill_color)
	
	# 绘制边框
	var border_color = Color(shield_color.r, shield_color.g, shield_color.b, border_alpha * pulse_factor)
	_draw_rounded_rect_outline(Rect2(Vector2.ZERO, size), corner_radius, border_width, border_color)

func _process(delta: float) -> void:
	if pulse_enabled and modulate.a > 0:
		time += delta
		queue_redraw()

# 绘制圆角矩形填充 - 使用多个矩形组合
func _draw_rounded_rect_filled(rect: Rect2, radius: float, color: Color) -> void:
	# 限制圆角半径
	var r = min(radius, min(rect.size.x / 2.0, rect.size.y / 2.0))
	
	# 中心矩形（水平）
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
	
	# 左右矩形
	draw_rect(Rect2(rect.position.x, rect.position.y + r, r, rect.size.y - r * 2), color)
	draw_rect(Rect2(rect.position.x + rect.size.x - r, rect.position.y + r, r, rect.size.y - r * 2), color)
	
	# 四个圆角
	_draw_circle_sector(rect.position + Vector2(r, r), r, PI, PI * 1.5, color)  # 左上
	_draw_circle_sector(rect.position + Vector2(rect.size.x - r, r), r, PI * 1.5, PI * 2.0, color)  # 右上
	_draw_circle_sector(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0.0, PI * 0.5, color)  # 右下
	_draw_circle_sector(rect.position + Vector2(r, rect.size.y - r), r, PI * 0.5, PI, color)  # 左下

# 绘制圆弧扇形
func _draw_circle_sector(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points: PackedVector2Array = [center]
	var num_points = 10
	
	for i in range(num_points + 1):
		var angle = start_angle + (end_angle - start_angle) * i / num_points
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	draw_colored_polygon(points, color)

# 绘制圆角矩形轮廓
func _draw_rounded_rect_outline(rect: Rect2, radius: float, width: float, color: Color) -> void:
	# 限制圆角半径
	var r = min(radius, min(rect.size.x / 2.0, rect.size.y / 2.0))
	
	# 四条直线段
	# 上边
	draw_line(
		rect.position + Vector2(r, 0),
		rect.position + Vector2(rect.size.x - r, 0),
		color, width
	)
	# 右边
	draw_line(
		rect.position + Vector2(rect.size.x, r),
		rect.position + Vector2(rect.size.x, rect.size.y - r),
		color, width
	)
	# 下边
	draw_line(
		rect.position + Vector2(rect.size.x - r, rect.size.y),
		rect.position + Vector2(r, rect.size.y),
		color, width
	)
	# 左边
	draw_line(
		rect.position + Vector2(0, rect.size.y - r),
		rect.position + Vector2(0, r),
		color, width
	)
	
	# 四个圆角弧线
	_draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, color, width)  # 左上
	_draw_arc(rect.position + Vector2(rect.size.x - r, r), r, PI * 1.5, PI * 2.0, color, width)  # 右上
	_draw_arc(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0.0, PI * 0.5, color, width)  # 右下
	_draw_arc(rect.position + Vector2(r, rect.size.y - r), r, PI * 0.5, PI, color, width)  # 左下

# 绘制圆弧
func _draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	var num_points = 10
	
	for i in range(num_points + 1):
		var angle = start_angle + (end_angle - start_angle) * i / num_points
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	draw_polyline(points, color, width, true)

## 显示护盾
func show_shield() -> void:
	# 淡入动画
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	# 添加轻微的缩放效果
	scale = Vector2(0.95, 0.95)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

## 隐藏护盾
func hide_shield() -> void:
	# 淡出动画
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

