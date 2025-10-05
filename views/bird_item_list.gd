extends Control

@onready var choose_container: GridContainer = $ScrollContainer/ChooseContainer
@onready var birds_container: GridContainer = $BirdsContainer
@onready var begin_lable: Label = $beginLable
@onready var guide_intro: Label = $GuideIntro
@onready var scroll_container: ScrollContainer = $ScrollContainer
@export var ready_bird_item_list: Array[ChooseBirdItem] = []

var bird_item_scene = preload("res://views/choose_bird_item.tscn")
var choose_bird_item_list: Array[ChooseBirdItem] = []
var bird_data_list: Array[BirdData] = []
var selected_indexs: Array[int] = []
var current_selected_index: int = 0
var grid_columns: int = 5 # 根据场景文件中的配置

func _ready():
	_init_birds_container() # 初始化右侧容器，默认隐藏所有item
	load_bird_data()
	display_birds()
	_setup_default_selection()
	_update_labels()
	
	# 设置初始选中项（导航焦点）
	if choose_bird_item_list.size() > 0:
		select_bird_item(0)

func _input(event):
	# 如果只有更少鸟类，禁用移动和选择操作
	if choose_bird_item_list.size() < 4:
		if event.is_action_pressed("ui_cancel"):
			_on_cancel_pressed()
		return
	
	# 正常的导航和选择逻辑
	if event.is_action_pressed("up"):
		navigate_up()
	elif event.is_action_pressed("down"):
		navigate_down()
	elif event.is_action_pressed("left"):
		navigate_left()
	elif event.is_action_pressed("right"):
		navigate_right()
	elif event.is_action_pressed("ok"):
		var selected_count = selected_indexs.size()
		print("当前已选择鸟类数量: %d" % selected_count)
		if selected_count == 4:
			_on_game_begin()
		else:
			toggle_bird_selection()
			# 安全地处理输入事件
			var viewport = get_viewport()
			if viewport:
				viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()

func load_bird_data():
	# 使用 BirdManager 加载所有鸟类数据
	var all_birds = BirdManager.get_unlocked_bird_datas()
	bird_data_list = all_birds

func display_birds():
	# 清除现有的鸟类项
	for child in choose_container.get_children():
		child.queue_free()
	
	choose_bird_item_list.clear()
	
	# 在待选容器中创建鸟类项
	for bird in bird_data_list:
		var bird_item = create_bird_item(bird)
		choose_container.add_child(bird_item)
		choose_bird_item_list.append(bird_item)

func create_bird_item(bird_data: BirdData) -> ChooseBirdItem:
	var bird_item = bird_item_scene.instantiate() as ChooseBirdItem
	bird_item.setup_bird_data(bird_data)
	return bird_item

func _init_birds_container():
	# 初始化右侧容器的4个预设item，默认全部隐藏
	for i in range(ready_bird_item_list.size()):
		if ready_bird_item_list[i]:
			ready_bird_item_list[i].visible = false
			ready_bird_item_list[i].clear_bird_data()

func _setup_default_selection():
	# 默认选中前四个鸟类
	var max_default_selection = min(4, choose_bird_item_list.size())
	
	for i in range(max_default_selection):
		selected_indexs.append(i)
		var bird_item = choose_bird_item_list[i]
		bird_item.set_selected(true)
	
	# 更新右侧容器显示
	_update_selected_birds_display()
	_update_display_containers()

func select_bird_item(index: int):
	if index < 0 or index >= choose_bird_item_list.size():
		return
	
	# 如果只有4个或更少鸟类，不显示导航高亮
	if choose_bird_item_list.size() <= 4:
		return
	
	# 清除所有选中状态（导航高亮）
	for i in range(choose_bird_item_list.size()):
		choose_bird_item_list[i].set_navigation_selected(i == index)
	
	current_selected_index = index
	
	# 确保选中项在视图中可见
	ensure_item_visible(index)


func ensure_item_visible(index: int):
	if index >= choose_bird_item_list.size():
		return
	
	var item = choose_bird_item_list[index]
	var item_rect = item.get_rect()
	var container_rect = scroll_container.get_rect()
	var scroll_pos = scroll_container.scroll_vertical
	
	# 计算项目在容器中的位置
	var item_top = item_rect.position.y
	var item_bottom = item_rect.position.y + item_rect.size.y
	
	# 如果项目在视图上方，向上滚动
	if item_top < scroll_pos:
		scroll_container.scroll_vertical = item_top
	# 如果项目在视图下方，向下滚动
	elif item_bottom > scroll_pos + container_rect.size.y:
		scroll_container.scroll_vertical = item_bottom - container_rect.size.y

func navigate_up():
	var new_index = current_selected_index - grid_columns
	if new_index >= 0:
		select_bird_item(new_index)

func navigate_down():
	var new_index = current_selected_index + grid_columns
	if new_index < choose_bird_item_list.size():
		select_bird_item(new_index)

func navigate_left():
	if current_selected_index % grid_columns > 0:
		select_bird_item(current_selected_index - 1)

func navigate_right():
	if current_selected_index % grid_columns < grid_columns - 1 and current_selected_index + 1 < choose_bird_item_list.size():
		select_bird_item(current_selected_index + 1)

func toggle_bird_selection():
	if current_selected_index < 0 or current_selected_index >= choose_bird_item_list.size():
		return
	
	var bird_item = choose_bird_item_list[current_selected_index]
	var bird_index = current_selected_index
	
	# 检查是否已经选中
	if bird_index in selected_indexs:
		# 取消选择
		selected_indexs.erase(bird_index)
		bird_item.set_selected(false)
		print("取消选择鸟类: %s" % bird_data_list[bird_index].name)
	else:
		# 检查是否还有空位（最多4个）
		if selected_indexs.size() >= 4:
			print("已选择4只鸟类，无法再选择更多")
			return
			
		# 选择鸟类
		selected_indexs.append(bird_index)
		bird_item.set_selected(true)
		print("选择鸟类: %s" % bird_data_list[bird_index].name)
	
	# 重新组织右侧容器的显示
	_update_selected_birds_display()
	_update_display_containers()
	_update_labels()

func _update_selected_birds_display():
	# 先隐藏所有预设的item
	for i in range(ready_bird_item_list.size()):
		if ready_bird_item_list[i]:
			ready_bird_item_list[i].visible = false
			ready_bird_item_list[i].clear_bird_data()
	
	# 按选择顺序显示选中的鸟类
	for i in range(selected_indexs.size()):
		if i < ready_bird_item_list.size():
			var bird_index = selected_indexs[i]
			ready_bird_item_list[i].setup_bird_data(bird_data_list[bird_index])
			ready_bird_item_list[i].visible = true

func _update_display_containers():
	# choose_container 始终显示所有可选鸟类
	choose_container.visible = true
	# birds_container 显示已选择的鸟类（使用预设的4个位置）
	birds_container.visible = true

func _update_labels():
	var selected_count = selected_indexs.size()
	guide_intro.visible = selected_count < 4
	begin_lable.visible = selected_count == 4
	
func _on_game_begin():
	print("开始游戏，选择的鸟类索引: %s" % str(selected_indexs))
	# 加载所选鸟类到全局变量
	Global.selected_birds = get_selected_birds()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_cancel_pressed():
	# 返回主菜单或上一个场景
	get_tree().change_scene_to_file("res://scenes/song_list.tscn") # 调整路径

func get_selected_birds() -> Array[BirdData]:
	var selected_birds: Array[BirdData] = []
	for index in selected_indexs:
		if index < bird_data_list.size():
			selected_birds.append(bird_data_list[index])
	return selected_birds
