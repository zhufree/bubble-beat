extends Control


@onready var judgment_line_1: Area2D = $JudgmentLineContainer/JudgmentLine1
@onready var collision_shape_2d_1: CollisionShape2D = $JudgmentLineContainer/JudgmentLine1/CollisionShape2D1
@onready var judgment_line_2: Area2D = $JudgmentLineContainer/JudgmentLine2
@onready var collision_shape_2d_2: CollisionShape2D = $JudgmentLineContainer/JudgmentLine2/CollisionShape2D2
@export var color_lines:Array[ColorLine]

var area_width: float = 400.0 # 默认，稍后更新
var beat_interval: float
var bubble_scene = preload("res://views/bubble.tscn")
var colors: Array
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
var input_actions = ["E", "D", "K", "O"] # 对应的输入动作
var color_to_action: Dictionary = {}

# 颜色对应的判定线规则
var color_judgment_rules: Dictionary = {}


func _ready():
	area_width = get_size().x
	await get_tree().process_frame
	calculate_positions()
	setup_judgment_line_signals()
	EventBus.connect("update_judgement_rules", _update_judgement_rules)
	EventBus.connect("pat", _on_pat_received)
	_update_judgement_rules()

func _update_judgement_rules():
	# 从Global获取最新的判定规则
	color_to_action.clear()
	color_judgment_rules.clear()

	# 使用Global.selected_song并更新beat_interval
	if Global.selected_song:
		colors = Global.selected_song.colors
		beat_interval = 60.0 / Global.selected_song.BPM
		# 重新计算时机（确保beat_interval正确）
		calculate_timing()
	else:
		print("Error: Global.selected_song is null")
		return
	if Global.selected_birds.size() != 4:
		print("Error: selected_birds size is not 4")
		return
	update_judgement_rules_by_single_data(Global.selected_birds[0], "E", 1)
	update_judgement_rules_by_single_data(Global.selected_birds[1], "D", 2)
	update_judgement_rules_by_single_data(Global.selected_birds[2], "K", 2)
	update_judgement_rules_by_single_data(Global.selected_birds[3], "O", 1)


func update_judgement_rules_by_single_data(bird: BirdSlot, key_action: String, line_rule: int):
	# 更新单个鸟类的判定规则
	var color = bird.bird_data.bubble_color
	color_to_action[color] = key_action
	color_judgment_rules[color] = line_rule

func _on_pat_received(pos: int):
	# 当收到节拍信号时，检查是否应该生成气泡
	if pos >= 0 and Global.game_status == Enums.GameStatus.PLAYING:
		var difficulty = Global.difficulty
		var spawn_interval = 1  # 默认每拍都发射

		# 根据难度设置发射间隔
		match difficulty:
			1:
				spawn_interval = 4  # 最简单：每4拍发射一次
			2:
				spawn_interval = 2  # 中等：每2拍发射一次
			3:
				spawn_interval = 1  # 最难：每拍发射一次
			_:
				spawn_interval = 4  # 其他情况默认每4拍发射

		# 检查当前节拍是否能被发射间隔整除
		if pos % spawn_interval == 0:
			spawn_bubble()

func _physics_process(_delta: float) -> void:

	var new_width = get_size().x

	# 如果窗口大小发生变化，重新计算位置
	if abs(area_width - new_width) > 1.0:
		area_width = new_width
		calculate_positions()

	check_input()

func calculate_positions():
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

	# 气泡从屏幕最底端生成（使用整个tracks的高度）
	spawn_y = get_size().y

func calculate_timing():
	# 更新全局坐标变量（确保位置信息是最新的）
	judgment_line_1_y = judgment_line_1.global_position.y
	judgment_line_2_y = judgment_line_2.global_position.y

	# 气泡从屏幕最底端生成（使用整个tracks的高度）
	spawn_y = get_size().y

	# 计算气泡速度：确保从生成到第一根判定线（上方）用时beats_to_first_line拍
	var distance_to_first_line = spawn_y - judgment_line_1_y
	var time_to_first_line = beats_to_first_line * beat_interval

	# 检查beat_interval是否有效，避免除以零
	if beat_interval > 0:
		bubble_speed = distance_to_first_line / time_to_first_line
	else:
		print("Error: beat_interval is 0 or negative, using default speed")
		bubble_speed = 200.0  # 默认速度

	print("=== 计算气泡时机 ===")
	print("气泡生成位置: ", spawn_y)
	print("到第一条线距离: ", distance_to_first_line)
	print("节拍间隔: ", beat_interval)
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
	
	# 调整CollisionShape2D的宽度与Area2D一致
	adjust_collision_shapes_width(width)
	
	print("设置完成 - Line1位置: ", judgment_line_1.position)
	print("设置完成 - Line2位置: ", judgment_line_2.position)
	
	# 设置颜色线位置和颜色
	for i in color_lines.size():
		color_lines[i].lane_index = i
		color_lines[i].position.x = 0 if (i <= 1) else container_size.x
		color_lines[i].position.y = relative_line1_y if (color_lines[i].line_index == 1) else relative_line2_y
		color_lines[i].set_end_point_x(container_size.x)
		color_lines[i].gradient_line.gradient = Global.selected_birds[i].bird_data.gradient

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
	var bubble = bubble_scene.instantiate()
	bubble.set_beat_interval(beat_interval)

	# 确保bubble_speed有效
	if bubble_speed > 0:
		bubble.set_speed(bubble_speed)
	else:
		printerr("Warning: bubble_speed is 0 or negative, using default")
		bubble.set_speed(200.0)

	# 随机选择一个按键（轨道）
	var random_key_index = randi() % input_actions.size()
	var selected_key = input_actions[random_key_index]

	# 找到对应的鸟的颜色
	var target_color = null
	for color in color_to_action:
		if color_to_action[color] == selected_key:
			target_color = color
			break

	# 设置气泡颜色和轨道
	if target_color != null:
		bubble.set_color(target_color)
		# 根据按键设置轨道索引（从左到右：E=1, D=2, K=3, O=4）
		match selected_key:
			"E":
				bubble.setup_for_lane(1)  # 最左边
			"D":
				bubble.setup_for_lane(2)  # 第二个
			"K":
				bubble.setup_for_lane(3)  # 第三个
			"O":
				bubble.setup_for_lane(4)  # 最右边
		# 设置显示颜色
		bubble.set_display_color(target_color)
	else:
		# 如果找不到对应颜色，使用默认颜色和轨道
		bubble.set_color(Enums.BubbleColor.DEFAULT)
		bubble.setup_for_lane(1)
		bubble.set_display_color(Enums.BubbleColor.DEFAULT)

	bubble.set_bubble_position(area_width, spawn_y)
	add_child(bubble)
	bubble_nodes.append(bubble)


# 设置判定线的碰撞检测信号
func setup_judgment_line_signals():
	# 连接判定线1的信号（Area2D检测Area2D）
	if judgment_line_1.area_entered.connect(_on_judgment_line_1_entered) != OK:
		printerr("Failed to connect judgment_line_1 area_entered signal")
	if judgment_line_1.area_exited.connect(_on_judgment_line_1_exited) != OK:
		printerr("Failed to connect judgment_line_1 area_exited signal")
	
	# 连接判定线2的信号
	if judgment_line_2.area_entered.connect(_on_judgment_line_2_entered) != OK:
		printerr("Failed to connect judgment_line_2 area_entered signal")
	if judgment_line_2.area_exited.connect(_on_judgment_line_2_exited) != OK:
		printerr("Failed to connect judgment_line_2 area_exited signal")

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

func calculate_score_and_shield(lane_index: int, base_score: int, combo: int) -> Dictionary:
	# 获取对应轨道的鸟类数据
	if lane_index < 0 or lane_index >= Global.selected_birds.size():
		return {"score": base_score, "shield_generated": 0.0}

	var bird = Global.selected_birds[lane_index]
	if not bird or not bird.skill_balls:
		return {"score": base_score, "shield_generated": 0.0}

	# 计算各种颜色的技能球数量
	var yellow_balls = 0
	var red_balls = 0
	var blue_balls = 0
	var green_balls = 0

	for skill_ball in bird.skill_balls:
		if skill_ball.skill_color == Enums.SkillColor.YELLOW:
			yellow_balls += 1
		elif skill_ball.skill_color == Enums.SkillColor.RED:
			red_balls += 1
		elif skill_ball.skill_color == Enums.SkillColor.BLUE:
			blue_balls += 1
		elif skill_ball.skill_color == Enums.SkillColor.GREEN:
			green_balls += 1

	# 基础分计算
	var score_multiplier = 1.0

	# 黄球加成：基础分 * (1 + 0.5 * 黄球个数)
	score_multiplier *= (1.0 + 0.5 * yellow_balls)

	# 连击加成
	if combo < 50:
		# 连击小于50：基础分 * (1 + 连击数/50 * (1 + 红球个数))
		score_multiplier *= (1.0 + float(combo) / 50.0 * (1.0 + red_balls))
	else:
		# 连击大于50：基础分 * (1 + (1 + 红球个数))
		score_multiplier *= (1.0 + (1.0 + red_balls))

	# 计算护盾生成（蓝球影响）
	var shield_generated = 0.0
	if blue_balls > 0:
		shield_generated = 0.2 * blue_balls

	return {
		"score": int(base_score * score_multiplier),
		"shield_generated": shield_generated,
		"heal_amount": green_balls * 20
	}

func calculate_score(lane_index: int, base_score: int, combo: int) -> int:
	var result = calculate_score_and_shield(lane_index, base_score, combo)
	return result.score

# 处理按键按下
func handle_key_press(action: String):
	var target_color = null
	for color in color_to_action:
		if color_to_action[color] == action:
			target_color = color
			break

	if target_color == null:
		return

	# 动画逻辑改了，分布在每条线里了
	var index = input_actions.find(action)
	if index >= 0:
		color_lines[index].animate_line()
	else:
		printerr("handle_key_press未找到action的索引值。")

	# 剩下的判定逻辑我不改了，虽然还是有点繁琐
	var required_line = color_judgment_rules[target_color]
	var target_bubbles_array = null

	# 发送信号给对应的角色显示边框
	EventBus.emit_signal("show_character_border", Global.selected_birds[index])

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
		color_lines[index].animate_gradient_line()
		EventBus.emit_signal("update_hit", index, 1)

		# 获取当前连击数和基础分（移除难度影响）
		var base_score = 100  # 固定基础分100
		var current_combo = get_current_combo()

		# 计算基于技能球的得分和护盾
		var result = calculate_score_and_shield(index, base_score, current_combo)
		var final_score = result.score
		var shield_generated = result.shield_generated
		var heal_amount = result.heal_amount

		# 添加得分
		Global.update_score(final_score)

		# 生成护盾（如果有蓝球）
		if shield_generated > 0:
			Global.add_shield(shield_generated)

		# 回复生命值（如果有绿球）
		if heal_amount > 0:
			Global.heal(heal_amount)

		safe_remove_bubble(hit_bubble)
	else:
		for bubble in target_bubbles_array:
			if is_instance_valid(bubble) and bubble.has_method("get_bubble_color"):
				print("  - 气泡颜色: ", bubble.get_bubble_color())

# 获取当前连击数
func get_current_combo() -> int:
	# 直接从Global获取当前连击数
	return Global.combo



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
