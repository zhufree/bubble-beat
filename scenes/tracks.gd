extends Control


@onready var judgment_line_1: Area2D = $VBoxContainer/JudgmentLineContainer/JudgmentLine1
@onready var judgment_line_2: Area2D = $VBoxContainer/JudgmentLineContainer/JudgmentLine2

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
var difficulty: float = 4.0 # 难度系数

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
	Enums.BubbleColor.GREEN: 2,  # 绿色只能在第一条判定线消除
	Enums.BubbleColor.BLUE: 2,   # 蓝色只能在第一条判定线消除
	Enums.BubbleColor.YELLOW: 1, # 黄色只能在第二条判定线消除
	Enums.BubbleColor.RED: 1     # 红色只能在第二条判定线消除
}


func _ready():
	area_width = get_size().x
	# 等待一帧确保节点位置正确
	await get_tree().process_frame
	calculate_positions_and_timing()
	# 连接判定线的信号
	setup_judgment_line_signals()

func _process(delta):
	# 节奏生成泡泡
	time_since_last_spawn += delta
	area_width = get_size().x
	
	# 每隔beats_between_lines拍生成一个气泡
	var spawn_interval = beat_interval * difficulty
	if time_since_last_spawn >= spawn_interval:
		print("time_since_last_spawn: ", time_since_last_spawn, " spawn_interval: ", spawn_interval)
		spawn_bubble()
		time_since_last_spawn = 0.0
	
	# 检测按键输入
	check_input()

func calculate_positions_and_timing():
	# 获取判定线的Y坐标
	judgment_line_1_y = judgment_line_1.global_position.y
	judgment_line_2_y = judgment_line_2.global_position.y
	
	# 确保line1在上方，line2在下方
	if judgment_line_1_y > judgment_line_2_y:
		var temp = judgment_line_1_y
		judgment_line_1_y = judgment_line_2_y
		judgment_line_2_y = temp
	
	# 气泡从屏幕最底端生成
	spawn_y = get_size().y
	
	# 计算气泡速度：确保从生成到第一根判定线（上方）用时beats_to_first_line拍
	var distance_to_first_line = spawn_y - judgment_line_1_y
	var time_to_first_line = beats_to_first_line * beat_interval
	bubble_speed = distance_to_first_line / time_to_first_line
	
	print("判定线位置: Line1（上方）=", judgment_line_1_y, ", Line2（下方）=", judgment_line_2_y)
	print("生成位置（屏幕底端）: ", spawn_y)
	print("气泡速度: ", bubble_speed, " 像素/秒")
	print("从生成到上方判定线预计用时: ", time_to_first_line, " 秒（", beats_to_first_line, " 拍）")

func spawn_bubble():
	print("spawn_bubble()")
	var bubble = bubble_scene.instantiate()
	bubble.set_beat_interval(beat_interval)
	bubble.set_speed(bubble_speed)
	bubble.set_color(randi() % colors.size())
	bubble.set_bubble_position(area_width, spawn_y)
	add_child(bubble)
	bubble_nodes.append(bubble)

func get_judgment_line_positions() -> Array:
	return [judgment_line_1_y, judgment_line_2_y]

# 获取判定区域内的气泡数量（调试用）
func get_judgment_zone_info():
	pass

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
	if bubble.has_method("get_bubble_color"):
		if bubble not in bubbles_in_judgment_zone_1:
			bubbles_in_judgment_zone_1.append(bubble)
			print("气泡进入第一条判定线区域，颜色: ", bubble.get_bubble_color())

# 气泡的HitArea离开第一条判定线区域
func _on_judgment_line_1_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_1:
			bubbles_in_judgment_zone_1.erase(bubble)
			print("气泡离开第一条判定线区域，颜色: ", bubble.get_bubble_color())

# 气泡的HitArea进入第二条判定线区域
func _on_judgment_line_2_entered(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if bubble.has_method("get_bubble_color"):
		if bubble not in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.append(bubble)
			print("气泡进入第二条判定线区域，颜色: ", bubble.get_bubble_color())

# 气泡的HitArea离开第二条判定线区域
func _on_judgment_line_2_exited(area):
	# 获取气泡节点（HitArea的父节点）
	var bubble = area.get_parent()
	if bubble.has_method("get_bubble_color"):
		if bubble in bubbles_in_judgment_zone_2:
			bubbles_in_judgment_zone_2.erase(bubble)
			print("气泡离开第二条判定线区域，颜色: ", bubble.get_bubble_color())

# 检测按键输入
func check_input():
	for action in input_actions:
		if Input.is_action_just_pressed(action):
			handle_key_press(action)

# 处理按键按下
func handle_key_press(action: String):
	print("按键按下: ", action)
	
	# 找到对应颜色的枚举值
	var target_color = null
	for color in color_to_action:
		if color_to_action[color] == action:
			target_color = color
			break
	
	if target_color == null:
		print("未找到对应的颜色")
		return
	
	# 根据颜色规则确定在哪个判定线查找气泡
	var required_line = color_judgment_rules[target_color]
	var target_bubbles_array = null
	
	if required_line == 1:
		target_bubbles_array = bubbles_in_judgment_zone_1
		print("查找第一条判定线上的", target_color, "气泡")
	elif required_line == 2:
		target_bubbles_array = bubbles_in_judgment_zone_2
		print("查找第二条判定线上的", target_color, "气泡")
	
	# 在指定判定线区域内查找匹配颜色的气泡
	var hit_bubble = null
	for bubble in target_bubbles_array:
		if bubble.get_bubble_color() == target_color:
			hit_bubble = bubble
			break
	
	if hit_bubble:
		# 击破气泡
		print("击破气泡! 颜色: ", target_color, ", 在第", required_line, "条判定线")
		# 从两个列表中移除
		bubbles_in_judgment_zone_1.erase(hit_bubble)
		bubbles_in_judgment_zone_2.erase(hit_bubble)
		bubble_nodes.erase(hit_bubble)
		hit_bubble.queue_free()
	else:
		print("Miss! 没有在第", required_line, "条判定线找到匹配的气泡，颜色: ", target_color)
