extends Control

class_name AtlasPanel

## 通过编辑器拖拽添加的 AtlasLine 场景列表
@export var atlas_line_list: Array[AtlasLine] = []
@onready var second_panel: AtlasSecondPanel = $SecondPanel
@onready var guide_intro: Label = $ColorRect/GuideIntro

var current_selected_index: int = -1
var is_in_second_panel: bool = false
var cur_selected_item_line: AtlasLine = null

func _ready():
	guide_intro.text = _get_guide_intro(0)
	for line in atlas_line_list:
		line.init(self)
	EventBus.connect("update_guide_text", update_guide_text)
	# 初始化，选择第一行
	if atlas_line_list.size() > 0:
		select_line(0)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC键
		exit_to_index()
		return
	if event.is_action_pressed("up"): # W键
		navigate_up()
	elif event.is_action_pressed("down"): # S键
		navigate_down()

# 选择指定的行
func select_line(index: int):
	if index < 0 or index >= atlas_line_list.size():
		return
	
	# 清除所有行的选中状态
	for i in range(atlas_line_list.size()):
		atlas_line_list[i].select_line(i == index)
	
	current_selected_index = index
	atlas_line_list[index].select_line(true)

# 向上导航
func navigate_up():
	if current_selected_index > 0:
		select_line(current_selected_index - 1)
	else:
		# 循环到最后一行
		select_line(atlas_line_list.size() - 1)

# 向下导航
func navigate_down():
	if current_selected_index < atlas_line_list.size() - 1:
		select_line(current_selected_index + 1)
	else:
		# 循环到第一行
		select_line(0)

func _on_bird_selected(atlas_line: AtlasLine, bird: BirdData):
	if not bird:
		return
	cur_selected_item_line = atlas_line
	var is_unlocked = BirdManager.get_bird_atlas(bird.name)

	is_in_second_panel = true
	second_panel.visible = true
	if is_unlocked:
		guide_intro.text = _get_guide_intro(2)
	else:
		guide_intro.text = _get_guide_intro(1)
	second_panel.open(is_unlocked, bird)

# 退出到主界面
func exit_to_index():
	if (is_in_second_panel):
		# 如果在二级面板，返回一级面板
		is_in_second_panel = false
		second_panel.visible = false
		second_panel.close()
		guide_intro.text = _get_guide_intro(0)
		cur_selected_item_line.update_and_clear_cur_selection()
	else:
		# 否则退出到主界面
		get_tree().change_scene_to_file("res://scenes/index.tscn")

func update_guide_text(type: int):
	guide_intro.text = _get_guide_intro(type)

func _get_guide_intro(type: int) -> String:
	var text = "W/S : Navigate categories          A/D: Navigate birds        Esc: back to menu"
	match type:
		0:
			text = "W/S : Navigate categories          A/D: Navigate birds        Esc: back to menu"
		1:
			text = "Enter: Fusion Comfirm (IRREVERSIBLE OPERATION)     Esc: Back to atlas"
		2:
			text = "Esc: Back to atlas"
	return text
