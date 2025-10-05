extends Control

class_name BirdEntity
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
@onready var h_color_container: HBoxContainer = $VboxContainer/Panel/HBoxContainer
@export var key_code: Enums.PressKeyCode

var _hit = 0
var _original_style: StyleBox = null
var bird_data: BirdData
var color_icon_list: Array[TextureRect] = []


func _ready():
	# 连接EventBus的信号
	EventBus.show_character_border.connect(_on_show_border)
	# 如果还没有保存原始样式，先保存
	if _original_style == null:
		_original_style = panel.get_theme_stylebox("panel")
		panel.remove_theme_stylebox_override("panel")

func setup_bird_data(data: BirdData):
	bird_data = data
	avatar.texture = bird_data.get_icon_texture()
	name_label.text = bird_data.name + " (" + Enums.press_key_code_to_string(key_code) + ")"
	_clear_bird_colors()
	for color_id in bird_data.colors:
		var color_icon = TextureRect.new()
		color_icon.texture = Enums.get_bubble_color_icon_sprite(color_id)
		# 使用 custom_minimum_size 而不是 size，并考虑缩放
		color_icon.custom_minimum_size = Vector2(32, 32)
		color_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if color_icon.texture:
			h_color_container.add_child(color_icon)
			color_icon.scale = Vector2(0.8, 0.8)
			color_icon_list.append(color_icon)

func _clear_bird_colors():
	for icon in color_icon_list:
		icon.queue_free()
	color_icon_list.clear()

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
