extends Control

@export var character_avatar: Texture
@export var character_name: String

const CHARACTER_KEY = {
	"Chick": "E",
	"Duck": "D",
	"Hippo": "K",
	"Parrot": "O"
}

@onready var avatar: TextureRect = $VboxContainer/Panel/CenterContainer/Avatar
@onready var panel: Panel = $VboxContainer/Panel
@onready var name_label: Label = $VboxContainer/NameLabel
@onready var hit_label: Label = $VboxContainer/HitLabel

var _hit = 0
var _original_style: StyleBox = null


func _ready():
	avatar.texture = character_avatar
	name_label.text = character_name + " (" + CHARACTER_KEY[character_name] + ")"
	
	# 连接EventBus的信号
	EventBus.show_character_border.connect(_on_show_border)
	# 如果还没有保存原始样式，先保存
	if _original_style == null:
		_original_style = panel.get_theme_stylebox("panel")
		panel.remove_theme_stylebox_override("panel")


func update_hit(hit_amount: int):
	_hit = _hit + hit_amount
	hit_label.text = "Hit:" + str(_hit)

func _on_show_border(target_character_name: String):
	if target_character_name == self.character_name:
		show_border()

func show_border():
	panel.add_theme_stylebox_override("panel", _original_style)
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(_on_hide_border_timeout.bind(timer))
	timer.start()

# 隐藏边框
func _on_hide_border_timeout(timer: Timer):
	panel.remove_theme_stylebox_override("panel")
	timer.queue_free()
