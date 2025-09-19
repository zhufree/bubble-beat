extends Node2D

var area_width: float = 400.0 # 默认，稍后更新
var track_width: float = 100.0 # 默认
var lanes: int = 4
var song = preload("res://resources/song_data/waiting_for_love.tres")
var beat_interval: float = song.BPM / 60.0 # 0.5秒/拍
var time_since_last_spawn: float = 0.0
var bubbles = []
var bubble_scene = preload("res://scenes/bubble.tscn")
var colors = [Enums.BubbleColor.RED, Enums.BubbleColor.BLUE, Enums.BubbleColor.GREEN, Enums.BubbleColor.YELLOW]
var track_colors = [
	Color(1, 0, 0, 0.2), # 红，半透明
	Color(0, 0, 1, 0.2), # 蓝
	Color(0, 1, 0, 0.2), # 绿
	Color(1, 1, 0, 0.2)  # 黄
]

func _ready():
	update_area_size(area_width) # 初始设置

func _draw():
	# 绘制判定线（宽area_width，高10，Y=50）
	draw_rect(Rect2(0, 50, area_width, 10), Color.WHITE)
	# 绘制轨道（每轨道宽track_width，高600）
	for i in range(4):
		if i < lanes: # 只绘制开放轨道
			draw_rect(Rect2(i * track_width, 0, track_width, 600), track_colors[i])
			
func update_area_size(width: float):
	print(width)
	area_width = width
	track_width = area_width / 4.0 # 等分4轨道
	#$JudgmentLine.scale.x = area_width / 400.0 # 假设原始纹理宽400
	#$JudgmentLine.position.x = area_width / 2.0
	for i in range(1, 5):
		var track = get_node("Track-" + str(i))
		track.position.x = (i - 0.5) * track_width # 轨道中心
		track.visible = i <= lanes

func _process(delta):
	# 节奏生成泡泡
	time_since_last_spawn += delta
	if time_since_last_spawn >= beat_interval:
		spawn_bubble()
		time_since_last_spawn = 0.0
	# 更新泡泡
	for bubble in bubbles:
		if bubble != null:
			bubble._process(delta)
		else:
			bubbles.erase(bubble)

func spawn_bubble():
	var bubble = bubble_scene.instantiate()
	bubble.lane = randi() % lanes # 随机轨道（0到lanes-1）
	bubble.set_color(randi() % colors.size())
	add_child(bubble)
	bubbles.append(bubble)
