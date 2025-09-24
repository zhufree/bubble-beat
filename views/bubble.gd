extends Node2D

@onready var blue: Sprite2D = $Blue
@onready var green: Sprite2D = $Green
@onready var red: Sprite2D = $Red
@onready var yellow: Sprite2D = $Yellow
@onready var collision_shape_2d: CollisionShape2D = $HitArea/CollisionShape2D

var lane_index: int = 0 # 轨道索引（0-3）
var speed: float = 275.0 # 像素/秒，将由tracks.gd设置
var beat_interval: float = 0.5 # 拍间隔
var birth_time: float = 0.0 # 气泡生成时间
var has_passed_line1: bool = false
var has_passed_line2: bool = false
var bubble_color: Enums.BubbleColor # 气泡颜色

func _ready():
	birth_time = Time.get_unix_time_from_system()

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
	match color:
		Enums.BubbleColor.YELLOW: 
			$Yellow.visible = true
			lane_index = 1
		Enums.BubbleColor.GREEN: 
			$Green.visible = true
			lane_index = 2
		Enums.BubbleColor.BLUE: 
			$Blue.visible = true
			lane_index = 3
		Enums.BubbleColor.RED: 
			$Red.visible = true
			lane_index = 4

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
		EventBus.emit_signal("update_score", -(5 - Global.difficulty) * 5)
