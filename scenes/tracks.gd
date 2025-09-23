extends Control


@onready var judgment_line_1: Area2D = $VBoxContainer/JudgmentLineContainer/JudgmentLine1
@onready var judgment_line_2: Area2D = $VBoxContainer/JudgmentLineContainer/JudgmentLine2
@onready var color_line_1: ColorRect = $VBoxContainer/JudgmentLineContainer/ColorLine1
@onready var color_line_2: ColorRect = $VBoxContainer/JudgmentLineContainer/ColorLine2

var area_width: float = 400.0 # 默认，稍后更新
var track_width: float = 100.0 # 默认
var lanes: int = 4
var song = preload("res://resources/song_data/waiting_for_love.tres")
var beat_interval: float = 60.0 / song.BPM # 0.5秒/拍
var time_since_last_spawn: float = 0.0
var bubble_scene = preload("res://scenes/bubble.tscn")
var colors = [Enums.BubbleColor.RED, Enums.BubbleColor.BLUE, Enums.BubbleColor.GREEN, Enums.BubbleColor.YELLOW]
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
var input_actions = ["red", "yellow", "blue", "green"] # 对应的输入动作
var color_to_action = {
	Enums.BubbleColor.RED: "red",
	Enums.BubbleColor.YELLOW: "yellow", 
	Enums.BubbleColor.BLUE: "blue",
	Enums.BubbleColor.GREEN: "green"
}
# 颜色对应的判定线规则
var color_judgment_rules = {
	Enums.BubbleColor.GREEN: 2,  # 绿色只能在第2条判定线消除
	Enums.BubbleColor.BLUE: 2,   # 蓝色只能在第2条判定线消除
	Enums.BubbleColor.YELLOW: 1, # 黄色只能在第1条判定线消除
	Enums.BubbleColor.RED: 1     # 红色只能在第1条判定线消除
}
var color_character = {
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
	# 先获取当前判定线的全局位置作为参考
	judgment_line_1_y = judgment_line_1.global_position.y
	judgment_line_2_y = judgment_line_2.global_position.y
	
	# 确保line1在上方，line2在下方
	if judgment_line_1_y > judgment_line_2_y:
		var temp = judgment_line_1_y
		judgment_line_1_y = judgment_line_2_y
		judgment_line_2_y = temp
	
	print("当前判定线1 Y坐标: ", judgment_line_1_y)
	print("当前判定线2 Y坐标: ", judgment_line_2_y)
	
	# 气泡从屏幕最底端生成
	spawn_y = get_size().y
	
	# 计算气泡速度：确保从生成到第一根判定线（上方）用时beats_to_first_line拍
	var distance_to_first_line = spawn_y - judgment_line_1_y
	var time_to_first_line = beats_to_first_line * beat_interval
	bubble_speed = distance_to_first_line / time_to_first_line
	
	print("气泡生成位置: ", spawn_y)
	print("到第一条线距离: ", distance_to_first_line)
	print("气泡速度: ", bubble_speed)


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
			print("气泡进入第一条判定线区域，颜色: ", bubble.get_bubble_color(), " 当前区域内气泡数: ", bubbles_in_judgment_zone_1.size())

# 气泡的HitArea离开第一条判定线区域
func _on_judgment_line_1_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_1:
			bubbles_in_judgment_zone_1.erase(bubble)
			print("气泡离开第一条判定线区域，颜色: ", bubble.get_bubble_color(), " 当前区域内气泡数: ", bubbles_in_judgment_zone_1.size())

# 气泡的HitArea进入第二条判定线区域
func _on_judgment_line_2_entered(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble not in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.append(bubble)
			print("气泡进入第二条判定线区域，颜色: ", bubble.get_bubble_color(), " 当前区域内气泡数: ", bubbles_in_judgment_zone_2.size())

# 气泡的HitArea离开第二条判定线区域
func _on_judgment_line_2_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.erase(bubble)
			print("气泡离开第二条判定线区域，颜色: ", bubble.get_bubble_color(), " 当前区域内气泡数: ", bubbles_in_judgment_zone_2.size())

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
		print("未找到对应的颜色")
		return
	
	var required_line = color_judgment_rules[target_color]
	var target_bubbles_array = null
	
	animate_judgment_line(target_color)
	
	# 发送信号给对应的角色显示边框
	EventBus.emit_signal("show_character_border", color_character[target_color])
	
	if required_line == 1:
		target_bubbles_array = bubbles_in_judgment_zone_1
		print("查找第一条判定线上的", target_color, "气泡")
	elif required_line == 2:
		target_bubbles_array = bubbles_in_judgment_zone_2
		print("查找第二条判定线上的", target_color, "气泡")
	
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
		print("击破气泡! 颜色: ", target_color, ", 在第", required_line, "条判定线")
		EventBus.emit_signal("update_hit", color_character[target_color], 1)
		EventBus.emit_signal("update_score", (5 - Global.difficulty) * 10)
		
		# 安全地从所有相关数组中删除气泡
		safe_remove_bubble(hit_bubble)
	else:
		print("Miss! 没有在第", required_line, "条判定线找到匹配的气泡，颜色: ", target_color)
		# 调试信息：显示当前判定区域内的气泡
		print("当前第", required_line, "条判定线区域内的气泡数量: ", target_bubbles_array.size())
		for bubble in target_bubbles_array:
			if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
				print("  - 气泡颜色: ", bubble.get_bubble_color())


var is_line_1_animating = false  # 第1条判定线是否在动画中
var is_line_2_animating = false  # 第2条判定线是否在动画中

func animate_judgment_line(target_color):
	var required_line = color_judgment_rules[target_color]
	
	# 检查对应的判定线是否已在动画中
	if required_line == 1 and is_line_1_animating:
		print("第1条判定线正在动画中，跳过动画")
		return
	elif required_line == 2 and is_line_2_animating:
		print("第2条判定线正在动画中，跳过动画")
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
			print("第1条判定线动画结束")
		else:
			is_line_2_animating = false
			print("第2条判定线动画结束")
	)

# 安全地删除气泡，确保从所有相关数组中移除
func safe_remove_bubble(bubble):
	if not is_instance_valid(bubble):
		return
	
	# 从判定区域数组中移除
	if bubble in bubbles_in_judgment_zone_1:
		bubbles_in_judgment_zone_1.erase(bubble)
		print("从第一条判定线区域移除气泡")
	
	if bubble in bubbles_in_judgment_zone_2:
		bubbles_in_judgment_zone_2.erase(bubble)
		print("从第二条判定线区域移除气泡")
	
	# 从总气泡列表中移除
	if bubble in bubble_nodes:
		bubble_nodes.erase(bubble)
		print("从气泡节点列表移除气泡")
	
	# 销毁气泡节点
	bubble.queue_free()
	print("气泡已标记为删除")
