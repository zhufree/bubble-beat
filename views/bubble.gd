extends Node2D

@onready var bubble_sprite: Sprite2D = $BubbleSprite
@onready var collision_shape_2d: CollisionShape2D = $HitArea/CollisionShape2D

var lane_index: int = 0 # 轨道索引（0-3）
var speed: float = 275.0 # 像素/秒，将由tracks.gd设置
var beat_interval: float = 0.5 # 拍间隔
var birth_time: float = 0.0 # 气泡生成时间
var has_passed_line1: bool = false
var has_passed_line2: bool = false
var bubble_color: Enums.BubbleColor # 气泡颜色
var pending_texture_path: String = "" # 待设置的贴图路径

func _ready():
	birth_time = Time.get_unix_time_from_system()
	# 如果有待设置的贴图路径，现在设置它
	if pending_texture_path != "":
		#print("Ready: Setting pending texture: ", pending_texture_path)
		var texture = load(pending_texture_path)
		if texture:
			bubble_sprite.texture = texture
		pending_texture_path = "" # 清空路径

func set_beat_interval(interval: float):
	beat_interval = interval

func set_speed(new_speed: float):
	speed = new_speed

func set_bubble_position(container_width: float, start_y: float):
	var track_width = container_width / 4
	position.x = (lane_index-1) * track_width + track_width / 2 # 轨道中心
	position.y = start_y


func set_color(color: Enums.BubbleColor):
	bubble_color = color # 保存颜色信息

func setup_for_lane(lane: int):
	# 设置轨道索引，位置由set_bubble_position函数处理
	lane_index = lane

func set_display_color(color: Enums.BubbleColor):
	# 根据颜色设置气泡精灵的贴图
	var texture_path = Enums.bubble_color_icon_sprite(color)

	if bubble_sprite:
		var texture = load(texture_path)
		if texture:
			bubble_sprite.texture = texture
	else:
		pending_texture_path = texture_path

# 获取气泡颜色（供判定系统使用）
func get_bubble_color() -> Enums.BubbleColor:
	return bubble_color
		

func _physics_process(delta: float) -> void:
	position.y -= speed * delta # 向上移动
	
	var parent_tracks = get_parent()
	if parent_tracks and parent_tracks.has_method("get_judgment_line_positions"):
		var line_positions = parent_tracks.get_judgment_line_positions()
		var line1_y = line_positions[0]
		var line2_y = line_positions[1]
		
		if not has_passed_line1 and position.y <= line1_y:
			has_passed_line1 = true
		
		if not has_passed_line2 and position.y <= line2_y:
			has_passed_line2 = true

	
	if position.y < -100: # 越过顶部
		queue_free() # 销毁
		# 优先消耗护盾，如果没有护盾再扣生命值
		if Global.consume_shield():
			# 护盾消耗成功，不扣除生命值，不清零连击
			print("护盾抵消了伤害")
		else:
			# 没有护盾，扣除生命值
			Global.take_damage(100) # 每错过一个气泡扣100点生命值
			# 清零连击数（通过调用Global函数）
			Global.update_score(0) # 发送0分来触发连击清零
