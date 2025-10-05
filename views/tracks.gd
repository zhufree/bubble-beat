extends Control


@onready var judgment_line_1: Area2D = $JudgmentLineContainer/JudgmentLine1
@onready var collision_shape_2d_1: CollisionShape2D = $JudgmentLineContainer/JudgmentLine1/CollisionShape2D1
@onready var judgment_line_2: Area2D = $JudgmentLineContainer/JudgmentLine2
@onready var collision_shape_2d_2: CollisionShape2D = $JudgmentLineContainer/JudgmentLine2/CollisionShape2D2
@onready var color_line_1: ColorRect = $JudgmentLineContainer/ColorLine1
@onready var color_line_2: ColorRect = $JudgmentLineContainer/ColorLine2

var area_width: float = 400.0 # 默认，稍后更新
var track_width: float = 100.0 # 默认
var lanes: int = 4
var song = preload("res://resources/song_data/waiting_for_love.tres")
var beat_interval: float = 60.0 / song.BPM # 0.5秒/拍
var time_since_last_spawn: float = 0.0
var bubble_scene = preload("res://views/bubble.tscn")
var colors = [Enums.BubbleColor.RED, Enums.BubbleColor.BLUE, Enums.BubbleColor.GREEN, Enums.BubbleColor.YELLOW, Enums.BubbleColor.PURPLE, Enums.BubbleColor.BLACK, Enums.BubbleColor.WHITE]
var bubble_nodes = []

# 判定线位置和时间计算
var judgment_line_1_y: float = 0.0
var judgment_line_2_y: float = 0.0
var spawn_y: float = 0.0
var bubble_speed: float = 0.0
var beats_between_lines: float = 2.0 # 两根判定线之间相隔2拍
var beats_to_first_line: float = 4.0 # 从生成到第一根判定线4拍

# 按键判定系统
var bubbles_in_judgment_zone_1: Array = [] # 在第一条判定线区域内的气泡
var bubbles_in_judgment_zone_2: Array = [] # 在第二条判定线区域内的气泡
var input_actions = ["E", "D", "O", "K"] # 对应的输入动作
var color_to_action: Dictionary = {
	Enums.BubbleColor.RED: "red",
	Enums.BubbleColor.YELLOW: "yellow",
	Enums.BubbleColor.BLUE: "blue",
	Enums.BubbleColor.GREEN: "green"
}

# 颜色对应的判定线规则
var color_judgment_rules: Dictionary = {
	Enums.BubbleColor.GREEN: 2, # 绿色只能在第2条判定线消除
	Enums.BubbleColor.BLUE: 2, # 蓝色只能在第2条判定线消除
	Enums.BubbleColor.YELLOW: 1, # 黄色只能在第1条判定线消除
	Enums.BubbleColor.RED: 1 # 红色只能在第1条判定线消除
}
var color_character: Dictionary = {
	Enums.BubbleColor.GREEN: "Duck",
	Enums.BubbleColor.BLUE: "Hippo",
	Enums.BubbleColor.YELLOW: "Chick",
	Enums.BubbleColor.RED: "Parrot"
}


func _ready():
	area_width = get_size().x
	await get_tree().process_frame
	calculate_positions_and_timing()
	setup_judgment_line_signals()
	EventBus.connect("update_judgement_rules", _update_judgement_rules)
	_update_judgement_rules()

func _update_judgement_rules():
	# 从Global获取最新的判定规则
	color_to_action.clear()
	color_judgment_rules.clear()
	color_character.clear()
	colors = song.colors
	if Global.selected_birds.size() != 4:
		print("Error: selected_birds size is not 4")
		return
	update_judgement_rules_by_single_data(Global.selected_birds[0], "E", 1)
	update_judgement_rules_by_single_data(Global.selected_birds[1], "D", 2)
	update_judgement_rules_by_single_data(Global.selected_birds[2], "O", 1)
	update_judgement_rules_by_single_data(Global.selected_birds[3], "K", 2)


func update_judgement_rules_by_single_data(bird_data: BirdData, key_action: String, line_rule: int):
	# 更新单个鸟类的判定规则
	for color in bird_data.colors:
		color_to_action[color] = key_action
		color_judgment_rules[color] = line_rule
		color_character[color] = bird_data.name

func _physics_process(delta: float) -> void:
	time_since_last_spawn += delta
	var new_width = get_size().x
	
	# 如果窗口大小发生变化，重新计算位置
	if abs(area_width - new_width) > 1.0:
		area_width = new_width
		calculate_positions_and_timing()
	
	var spawn_interval = beat_interval * Global.difficulty
	if time_since_last_spawn >= spawn_interval and Global.game_status == Enums.GameStatus.PLAYING:
		spawn_bubble()
		time_since_last_spawn = 0.0
	
	check_input()

func calculate_positions_and_timing():
	# 获取JudgmentLineContainer的大小（现在占据整个父布局）
	var container = $JudgmentLineContainer
	var container_height = container.get_size().y
	var container_width = container.get_size().x
	
	# 计算JudgmentLineContainer内的三等分位置
	var section_height = container_height / 3.0
	var target_line1_y = section_height # 1/3 处
	var target_line2_y = section_height * 2 # 2/3 处
	
	print("=== 计算判定线位置（基于JudgmentLineContainer） ===")
	print("Container高度: ", container_height)
	print("Container宽度: ", container_width)
	print("每段高度: ", section_height)
	print("目标Line1位置: ", target_line1_y)
	print("目标Line2位置: ", target_line2_y)
	
	# 重新设置判定线位置
	reposition_judgment_lines(target_line1_y, target_line2_y, container_width)
	
	# 更新全局坐标变量（用于气泡计算）
	judgment_line_1_y = judgment_line_1.global_position.y
	judgment_line_2_y = judgment_line_2.global_position.y
	
	# 确保line1在上方，line2在下方
	if judgment_line_1_y > judgment_line_2_y:
		var temp = judgment_line_1_y
		judgment_line_1_y = judgment_line_2_y
		judgment_line_2_y = temp
	
	print("实际Line1全局Y: ", judgment_line_1_y)
	print("实际Line2全局Y: ", judgment_line_2_y)
	
	# 气泡从屏幕最底端生成（使用整个tracks的高度）
	spawn_y = get_size().y
	
	# 计算气泡速度：确保从生成到第一根判定线（上方）用时beats_to_first_line拍
	var distance_to_first_line = spawn_y - judgment_line_1_y
	var time_to_first_line = beats_to_first_line * beat_interval
	bubble_speed = distance_to_first_line / time_to_first_line
	
	print("气泡生成位置: ", spawn_y)
	print("到第一条线距离: ", distance_to_first_line)
	print("气泡速度: ", bubble_speed)

# 重新定位判定线和颜色线
func reposition_judgment_lines(line1_y: float, line2_y: float, width: float):
	# 获取JudgmentLineContainer（现在占据整个父布局）
	var container = $JudgmentLineContainer
	var container_size = container.get_size()
	
	print("Container大小: ", container_size)
	print("Container占据整个父布局")
	
	# 由于container现在占据整个父布局，直接使用计算出的位置
	# line1_y和line2_y已经是相对于整个tracks的位置
	var relative_line1_y = line1_y
	var relative_line2_y = line2_y
	
	print("直接使用的Line1 Y: ", relative_line1_y)
	print("直接使用的Line2 Y: ", relative_line2_y)
	
	# 设置判定线位置
	judgment_line_1.position = Vector2(0, relative_line1_y)
	judgment_line_2.position = Vector2(0, relative_line2_y)
	
	# 设置颜色线位置和大小
	# ColorRect有20px高度，需要调整位置使其中心点在目标Y坐标上
	var color_line_height = 20.0
	color_line_1.position = Vector2(0, relative_line1_y - color_line_height / 2.0)
	color_line_2.position = Vector2(0, relative_line2_y - color_line_height / 2.0)
	color_line_1.size = Vector2(width, color_line_height)
	color_line_2.size = Vector2(width, color_line_height)
	
	# 调整CollisionShape2D的宽度与Area2D一致
	adjust_collision_shapes_width(width)
	
	print("设置完成 - Line1位置: ", judgment_line_1.position)
	print("设置完成 - Line2位置: ", judgment_line_2.position)
	print("设置完成 - ColorLine1位置: ", color_line_1.position)
	print("设置完成 - ColorLine2位置: ", color_line_2.position)

# 调整碰撞形状的宽度
func adjust_collision_shapes_width(width: float):
	# 获取CollisionShape2D的形状资源
	var shape1 = collision_shape_2d_1.shape
	var shape2 = collision_shape_2d_2.shape
	
	print("=== 调整CollisionShape宽度 ===")
	print("目标宽度: ", width)
	
	# 如果是RectangleShape2D，调整其大小
	if shape1 is RectangleShape2D:
		var rect_shape1 = shape1 as RectangleShape2D
		var current_height1 = rect_shape1.size.y
		rect_shape1.size = Vector2(width, current_height1)
		print("CollisionShape1调整为: ", rect_shape1.size)
	
	if shape2 is RectangleShape2D:
		var rect_shape2 = shape2 as RectangleShape2D
		var current_height2 = rect_shape2.size.y
		rect_shape2.size = Vector2(width, current_height2)
		print("CollisionShape2调整为: ", rect_shape2.size)
	
	# 确保CollisionShape2D的位置居中
	# RectangleShape2D以中心点为基准，所以X需要设置为宽度的一半
	# Y坐标需要根据判定线的位置来计算，确保中心点对齐
	collision_shape_2d_1.position.x = width / 2.0
	collision_shape_2d_1.position.y = 0
	collision_shape_2d_2.position.x = width / 2.0
	collision_shape_2d_2.position.y = 0
	
	print("CollisionShape位置调整为: x = ", width / 2.0, ", y = 0")
	
	print("CollisionShape宽度调整完成")


func spawn_bubble():
	print("spawn_bubble()")
	var bubble = bubble_scene.instantiate()
	bubble.set_beat_interval(beat_interval)
	bubble.set_speed(bubble_speed)
	bubble.set_color(randi() % colors.size())
	bubble.set_bubble_position(area_width, spawn_y)
	add_child(bubble)
	bubble_nodes.append(bubble)


# 设置判定线的碰撞检测信号
func setup_judgment_line_signals():
	# 连接判定线1的信号（Area2D检测Area2D）
	if judgment_line_1.area_entered.connect(_on_judgment_line_1_entered) != OK:
		print("Failed to connect judgment_line_1 area_entered signal")
	if judgment_line_1.area_exited.connect(_on_judgment_line_1_exited) != OK:
		print("Failed to connect judgment_line_1 area_exited signal")
	
	# 连接判定线2的信号
	if judgment_line_2.area_entered.connect(_on_judgment_line_2_entered) != OK:
		print("Failed to connect judgment_line_2 area_entered signal")
	if judgment_line_2.area_exited.connect(_on_judgment_line_2_exited) != OK:
		print("Failed to connect judgment_line_2 area_exited signal")

# 气泡的HitArea进入第一条判定线区域
func _on_judgment_line_1_entered(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble not in bubbles_in_judgment_zone_1:
			bubbles_in_judgment_zone_1.append(bubble)

# 气泡的HitArea离开第一条判定线区域
func _on_judgment_line_1_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_1:
			bubbles_in_judgment_zone_1.erase(bubble)

# 气泡的HitArea进入第二条判定线区域
func _on_judgment_line_2_entered(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble not in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.append(bubble)

# 气泡的HitArea离开第二条判定线区域
func _on_judgment_line_2_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.erase(bubble)

# 检测按键输入
func check_input():
	for action in input_actions:
		if Input.is_action_just_pressed(action):
			handle_key_press(action)

# 处理按键按下
func handle_key_press(action: String):
	var target_color = null
	for color in color_to_action:
		if color_to_action[color] == action:
			target_color = color
			break
	
	if target_color == null:
		return
	
	var required_line = color_judgment_rules[target_color]
	var target_bubbles_array = null
	
	animate_judgment_line(target_color)
	
	# 发送信号给对应的角色显示边框
	EventBus.emit_signal("show_character_border", color_character[target_color])
	
	if required_line == 1:
		target_bubbles_array = bubbles_in_judgment_zone_1
	elif required_line == 2:
		target_bubbles_array = bubbles_in_judgment_zone_2
	
	var hit_bubble = null
	# 创建目标数组的副本，避免在遍历时修改原数组
	var target_bubbles_copy = target_bubbles_array.duplicate()
	
	for bubble in target_bubbles_copy:
		# 验证气泡仍然存在且有效
		if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
			if bubble.get_bubble_color() == target_color:
				hit_bubble = bubble
				break
	
	if hit_bubble:
		EventBus.emit_signal("update_hit", color_character[target_color], 1)
		EventBus.emit_signal("update_score", (5 - Global.difficulty) * 10)
		safe_remove_bubble(hit_bubble)
	else:
		for bubble in target_bubbles_array:
			if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
				print("  - 气泡颜色: ", bubble.get_bubble_color())


var is_line_1_animating = false # 第1条判定线是否在动画中
var is_line_2_animating = false # 第2条判定线是否在动画中

func animate_judgment_line(target_color):
	var required_line = color_judgment_rules[target_color]
	
	# 检查对应的判定线是否已在动画中
	if required_line == 1 and is_line_1_animating:
		return
	elif required_line == 2 and is_line_2_animating:
		return
	
	# 标记对应的判定线为动画中
	if required_line == 1:
		is_line_1_animating = true
	else:
		is_line_2_animating = true
	
	var line_to_animate = null
	var original_width = 0
	var original_color = Color.WHITE
	var target_line_color = Color.WHITE
	
	match target_color:
		Enums.BubbleColor.RED:
			target_line_color = Color(1, 0, 0) # 红色
		Enums.BubbleColor.YELLOW:
			target_line_color = Color(1, 1, 0) # 黄色
		Enums.BubbleColor.BLUE:
			target_line_color = Color(0, 0, 1) # 蓝色
		Enums.BubbleColor.GREEN:
			target_line_color = Color(0, 1, 0) # 绿色
		Enums.BubbleColor.PURPLE:
			target_line_color = Color(0.5, 0, 0.5)
		Enums.BubbleColor.BLACK:
			target_line_color = Color(0, 0, 0)
		Enums.BubbleColor.WHITE:
			target_line_color = Color(1, 1, 1)
	
	# 选择要激活的判定线
	if required_line == 1:
		line_to_animate = color_line_1
	else:
		line_to_animate = color_line_2
	
	original_width = line_to_animate.size.y
	original_color = line_to_animate.color
	
	var tween = create_tween()
	
	tween.tween_property(line_to_animate, "size:y", original_width * 1.5, 0.1)
	tween.parallel().tween_property(line_to_animate, "color", target_line_color, 0.1)
	
	for i in range(2):
		tween.tween_property(line_to_animate, "color", Color.WHITE, 0.05)
		tween.tween_property(line_to_animate, "color", target_line_color, 0.05)
	
	tween.tween_property(line_to_animate, "size:y", original_width, 0.1)
	tween.parallel().tween_property(line_to_animate, "color", original_color, 0.1)

	# 动画结束时重置对应判定线的动画状态
	tween.finished.connect(func():
		if required_line == 1:
			is_line_1_animating = false
		else:
			is_line_2_animating = false
	)

# 安全地删除气泡，确保从所有相关数组中移除
func safe_remove_bubble(bubble):
	if not is_instance_valid(bubble):
		return
	
	# 从判定区域数组中移除
	if bubble in bubbles_in_judgment_zone_1:
		bubbles_in_judgment_zone_1.erase(bubble)
	
	if bubble in bubbles_in_judgment_zone_2:
		bubbles_in_judgment_zone_2.erase(bubble)
	
	# 从总气泡列表中移除
	if bubble in bubble_nodes:
		bubble_nodes.erase(bubble)
	
	# 销毁气泡节点
	bubble.queue_free()
