extends MarginContainer

class_name AtlasSecondPanel

# Common
@onready var level: Label = $Intro/CommonContainer/LevelLabel/Level
@onready var bird_icon: TextureRect = $Intro/CommonContainer/MarginLine/BirdIcon
@onready var bird_name: Label = $Intro/CommonContainer/Name
@onready var h_bird_color_container: HBoxContainer = $Intro/CommonContainer/HBoxContainer

# intro
@onready var intro: Control = $Intro/IntroContainer
@onready var description_intro: Label = $Intro/IntroContainer/DescripItem/VScrollBar/VBoxContainer/DescriptionIntro

# fusionPanel
@onready var fusion_container: Control = $Intro/FusionContainer

@onready var song_hint: Label = $Intro/FusionContainer/SongHint

@onready var fusion_panel: Control = $Intro/FusionContainer/FusionPanel
@onready var fail_intro: Label = $Intro/FusionContainer/FusionPanel/FailIntro
@onready var bird_icon_1: TextureRect = $Intro/FusionContainer/FusionPanel/MarginLine/BirdIcon_1
@onready var name_1: Label = $Intro/FusionContainer/FusionPanel/MarginLine/Name_1
@onready var bird_icon_2: TextureRect = $Intro/FusionContainer/FusionPanel/MarginLine2/BirdIcon_2
@onready var name_2: Label = $Intro/FusionContainer/FusionPanel/MarginLine2/Name_2
@onready var confirm_item: Control = $Intro/FusionContainer/FusionPanel/ComfirmItem


var bird_color_icon_scene = preload("res://views/bird_color_icon.tscn")
var bird_data: BirdData = null
var bird_progress: BirdProgress = null
var bird_color_icons: Array[TextureRect] = []
var is_open: bool = false
var is_ready_to_fusion: bool = false

func _input(event):
	if not is_open:
		return
	if event.is_action_pressed("ok"):
		if is_ready_to_fusion and bird_data:
			BirdManager.unlock_bird(bird_data.name)
			_initIntroPanel()
			# 消费事件，阻止继续传播
			get_viewport().set_input_as_handled()

func open(is_unlocked: bool, data: BirdData) -> void:
	is_ready_to_fusion = false
	is_open = true
	bird_data = data
	bird_progress = BirdManager.get_bird_progress(data.name)
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
	for color_id in bird_data.colors:
		var color_icon = bird_color_icon_scene.instantiate() as TextureRect
		color_icon.texture = Enums.get_bubble_color_icon_sprite(color_id)
		if color_icon.texture:
			bird_color_icons.append(color_icon)
			h_bird_color_container.add_child(color_icon)

func _initIntroPanel() -> void:
	intro.visible = true
	fusion_container.visible = false
	description_intro.text = bird_data.description
	bird_name.text = bird_data.name

func _initFusionPanel() -> void:
	intro.visible = false
	fusion_container.visible = true
	bird_name.text = "???"
	if bird_data.needFusion or bird_data.unlockNeedBirds.size() == 2:
		fusion_panel.visible = true
		var fusion_bird_1 = BirdManager.get_bird_data(bird_data.unlockNeedBirds[0])
		var fusion_bird_2 = BirdManager.get_bird_data(bird_data.unlockNeedBirds[1])
		var fusion_progress_1 = BirdManager.get_bird_progress(bird_data.unlockNeedBirds[0])
		var fusion_progress_2 = BirdManager.get_bird_progress(bird_data.unlockNeedBirds[1])
		# print("Fusion birds: %s (%s), %s (%
		if fusion_bird_1:
			if fusion_bird_1.get_icon_texture():
				bird_icon_1.texture = fusion_bird_1.get_icon_texture()
			name_1.text = fusion_bird_1.name if fusion_progress_1.is_unlocked else "???"
		if fusion_bird_2:
			if fusion_bird_2.get_icon_texture():
				bird_icon_2.texture = fusion_bird_2.get_icon_texture()
			name_2.text = fusion_bird_2.name if fusion_progress_2.is_unlocked else "???"
		is_ready_to_fusion = fusion_progress_1.is_unlocked and fusion_progress_2.is_unlocked
		confirm_item.visible = is_ready_to_fusion
		fail_intro.visible = !is_ready_to_fusion
		song_hint.visible = false
	else:
		song_hint.visible = true
		fusion_panel.visible = false
		song_hint.text = "Play \"%s\" to unlock this bird!" % bird_data.unlockCondition


func close() -> void:
	is_open = false
	_clear_bird_colors()
	bird_data = null
	bird_progress = null

func _clear_bird_colors() -> void:
	for icon in bird_color_icons:
		if icon and icon.is_inside_tree():
			icon.queue_free()
	bird_color_icons.clear()
