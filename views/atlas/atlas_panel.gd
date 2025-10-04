extends Control

## 通过编辑器拖拽添加的 AtlasLine 场景列表
@export var atlas_line_list: Array[AtlasLine] = []

var current_selected_index: int = -1

func _ready():
	for line in atlas_line_list:
		line.init()
	
	# 初始化，选择第一行
	if atlas_line_list.size() > 0:
		select_line(0)

func _input(event):
	if event.is_action_pressed("up"): # W键
		navigate_up()
	elif event.is_action_pressed("down"): # S键
		navigate_down()
	elif event.is_action_pressed("ui_cancel"): # ESC键
		exit_to_index()

# 选择指定的行
func select_line(index: int):
	if index < 0 or index >= atlas_line_list.size():
		return
	
	# 清除所有行的选中状态
	for i in range(atlas_line_list.size()):
		atlas_line_list[i].select_line(i == index)
	
	current_selected_index = index

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

# 退出到主界面
func exit_to_index():
	get_tree().change_scene_to_file("res://scenes/index.tscn")