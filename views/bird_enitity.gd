extends Control

class_name BirdEntity
@export var character_avatar: Texture
@export var character: BirdSlot


const CHARACTER_KEY = {
	"Chick": "E",
	"Duck": "D",
	"Hippo": "K",
	"Parrot": "O"
}
@onready var avatar: Sprite2D = $VboxContainer/Panel/CenterContainer/Avatar/Avatar
@onready var panel: Panel = $VboxContainer/Panel
@onready var name_label: Label = $VboxContainer/NameLabel
@onready var hit_label: Label = $VboxContainer/HitLabel
@onready var skill_ball_container: GridContainer = $VboxContainer/Panel/SkillBallContainer
@export var key_code: Enums.PressKeyCode

var _hit = 0
var _original_style: StyleBox = null
var bird_data: BirdData


func _ready():
	# 连接EventBus的信号
	EventBus.show_character_border.connect(_on_show_border)
	EventBus.pat.connect(_on_pat)
	# 如果还没有保存原始样式，先保存
	if _original_style == null:
		_original_style = panel.get_theme_stylebox("panel")
		panel.remove_theme_stylebox_override("panel")

func setup_bird_slot(slot: BirdSlot):
	bird_data = slot.bird_data
	avatar.texture = bird_data.get_icon_texture()
	name_label.text = slot.get_bird_name()
	# 显示技能球
	_clear_bird_colors()
	for skill_ball in slot.skill_balls:
		var color_icon = TextureRect.new()
		color_icon.texture = skill_ball.icon
		# 使用 custom_minimum_size 而不是 size，并考虑缩放
		color_icon.custom_minimum_size = Vector2(32, 32)
		color_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if color_icon.texture:
			skill_ball_container.add_child(color_icon)
			color_icon.scale = Vector2(0.8, 0.8)

func _clear_bird_colors():
	for icon in skill_ball_container.get_children():
		icon.queue_free()

func update_hit(hit_amount: int):
	_hit = _hit + hit_amount
	hit_label.text = "Hit:" + str(_hit)

func _on_show_border(target_character: BirdSlot):
	if target_character == self.character:
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

# duang一下
func _on_pat(_pos):
	avatar.scale.y = 1.1
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(avatar, "scale", Vector2(1,1), 0.2)
