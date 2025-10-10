extends Line2D
class_name ColorLine

@onready var gradient_line: Line2D = $Gradient
@export var line_index:int = 1  ## line1为上面那根线，line2为下面那根线
var lane_index:int = 0

# 是否在动画中
var is_line_animating
var is_gradient_line_animating

## 显示底色线动画
func animate_line():
	if is_line_animating:
		return
	is_line_animating = true
	var original_width = 20.0
	
	# 不要前摇，一步到位
	width = original_width * 1.5
	
	# 后摇收回动画
	var tween = create_tween()
	tween.tween_property(self, "width", original_width, 0.1)
	tween.finished.connect(func():
		is_line_animating = false
	)

## 显示渐变线动画，只在打中时显示
func animate_gradient_line():
	#$Bo.play()#不喜欢可以换成Kick
	$Kick.play()
	if is_gradient_line_animating:
		return
	is_gradient_line_animating = true
	var original_width = 20.0
	var original_points:PackedVector2Array = [Vector2(0,0),Vector2(0,0)]
	var animate_points:PackedVector2Array = [Vector2(0,0),points[1]]
	
	# 不要前摇，一步到位
	gradient_line.width = original_width * 1.5
	gradient_line.points = animate_points
	
	# 后摇收回动画
	var tween = create_tween()
	tween.tween_property(gradient_line, "width", original_width, 0.1)
	tween.set_trans(Tween.TRANS_CUBIC)#前慢后快的插值
	tween.parallel().tween_property(gradient_line, "points", original_points, 0.1)
	tween.finished.connect(func():
		is_gradient_line_animating = false
	)

## 设置线条终点位置
func set_end_point_x(container_width: float):
	var track_width = container_width / 4
	match lane_index:
		0:
			points[1].x = track_width * 0.5 # 左上轨中心
		1:
			points[1].x = track_width * 1.5 # 左下轨中心
		2:
			points[1].x = -track_width * 1.5 # 右下轨中心
		3:
			points[1].x = -track_width * 0.5 # 右上轨中心
