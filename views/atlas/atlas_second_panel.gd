extends MarginContainer

class_name AtlasSecondPanel

# Common
@onready var level: Label = $Intro/CommonContainer/LevelLabel/Level
@onready var bird_icon: TextureRect = $Intro/CommonContainer/MarginLine/BirdIcon
@onready var bird_name: Label = $Intro/CommonContainer/Name
@onready var h_bird_color_container: HBoxContainer = $Intro/CommonContainer/HBoxContainer

# intro
@onready var intro: Control = $Intro/IntroContainer
@onready var description_intro: Label = $Intro/IntroContainer/ScrollContainer/DescriptionIntro



var bird_color_icon_scene = preload("res://views/bird_color_icon.tscn")
var bird_data: BirdData = null
var bird_color_icons: Array[TextureRect] = []
var is_open: bool = false
var is_ready_to_fusion: bool = false


func open(is_unlocked: bool, data: BirdData) -> void:
	is_ready_to_fusion = false
	is_open = true
	bird_data = data
	_initCommonPanel()
	print("Bird %s is unlocked: %s" % [data.name, str(is_unlocked)])
	if is_unlocked:
		_initIntroPanel()
	else:
		_initFusionPanel()
		pass

func _initCommonPanel() -> void:
	level.text = Enums.BirdType.keys()[bird_data.bird_type].capitalize()
	if bird_data.get_icon_texture():
		bird_icon.texture = bird_data.get_icon_texture()
	_clear_bird_colors()
	for color_id in bird_data.skill_color:
		var color_icon = bird_color_icon_scene.instantiate() as TextureRect
		color_icon.texture = Enums.get_bubble_color_icon_sprite(color_id as int)
		if color_icon.texture:
			bird_color_icons.append(color_icon)
			h_bird_color_container.add_child(color_icon)

func _initIntroPanel() -> void:
	intro.visible = true
	description_intro.text = bird_data.description
	bird_name.text = bird_data.name

func _initFusionPanel() -> void:
	intro.visible = true
	description_intro.text = "获得拥有对应颜色的技能球的小鸟以开启图鉴！"
	bird_name.text = "？？？"

func close() -> void:
	is_open = false
	_clear_bird_colors()
	bird_data = null

func _clear_bird_colors() -> void:
	for icon in bird_color_icons:
		if icon and icon.is_inside_tree():
			icon.queue_free()
	bird_color_icons.clear()
