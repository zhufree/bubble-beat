extends Control

# 引用卡片节点
@onready var card1: AnimalCard = $CarouselContainer/Control/Card1
@onready var card2: AnimalCard = $CarouselContainer/Control/Card2
@onready var card3: AnimalCard = $CarouselContainer/Control/Card3
@onready var card4: AnimalCard = $CarouselContainer/Control/Card4

# 动物数据路径列表
var animal_data_paths: Array[String] = [
	"res://resources/animal_data/owl.tres",
	"res://resources/animal_data/balloon_bear.tres",
	"res://resources/animal_data/woodpecker.tres",
	# 第四个可以是未来添加的动物
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 加载并设置动物数据
	if card1 and animal_data_paths.size() > 0:
		var data1 = load(animal_data_paths[0]) as AnimalData
		if data1:
			card1.set_animal_data(data1, 1)

	if card2 and animal_data_paths.size() > 1:
		var data2 = load(animal_data_paths[1]) as AnimalData
		if data2:
			card2.set_animal_data(data2, 1)

	if card3 and animal_data_paths.size() > 2:
		var data3 = load(animal_data_paths[2]) as AnimalData
		if data3:
			card3.set_animal_data(data3, 1)

	# 第四张卡片设置为未解锁状态
	if card4:
		card4.set_locked()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("left"):
		$CarouselContainer._left()
	if Input.is_action_just_pressed("right"):
		$CarouselContainer._right()
	if Input.is_action_just_pressed("E"):
		$ColorRect.visible = true
		$ColorRect/Timer.start()

func _on_timer_timeout() -> void:
	$ColorRect.visible = false
