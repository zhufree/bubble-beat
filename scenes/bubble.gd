extends Node2D

@onready var blue: Sprite2D = $Blue
@onready var green: Sprite2D = $Green
@onready var red: Sprite2D = $Red
@onready var yellow: Sprite2D = $Yellow
@onready var collision_shape_2d: CollisionShape2D = $HitArea/CollisionShape2D

var lane: int = 0 # 轨道索引（0-3）
var speed: float = 275.0 # 像素/秒（2秒到判定线）

func _ready():
	position.x = lane * 200 + 100 # 轨道中心
	position.y = 600 # 底部

func set_color(color: Enums.BubbleColor):
	match color:
		Enums.BubbleColor.BLUE: $Blue.visible = true
		Enums.BubbleColor.GREEN: $Green.visible = true
		Enums.BubbleColor.RED: $Red.visible = true
		Enums.BubbleColor.YELLOW: $Yellow.visible = true

func _process(delta):
	position.y -= speed * delta # 向上移动
	if position.y < 0: # 越过顶部
		queue_free() # 销毁
