extends ColorRect

class_name AtlasLine

@onready var title: Label = $Title
@onready var bird_container: HBoxContainer = $HBoxContainer

## 设置该行显示的鸟类类型
@export_group("Bird Settings")
@export var bird_type: Enums.BirdType = Enums.BirdType.CHICK

var bird_button_scene = preload("res://views/atlas/atlas_bird_item.tscn")
var bird_items: Array[AtlasBirdItem] = []
var bird_data_list: Array[BirdData] = []
var current_selected_index: int = -1
var is_selected: bool = false
var atlas_panel_script = null


func _input(event):
	if not is_selected:
		return ;
	if atlas_panel_script.is_in_second_panel:
		return ;
	if event.is_action_pressed("left"):
		navigate_left()
	elif event.is_action_pressed("right"):
		navigate_right()
	elif event.is_action_pressed("ok"):
		if current_selected_index >= 0 and current_selected_index < bird_items.size():
			# 触发选中事件
			_on_bird_selected(bird_items[current_selected_index].bird_data)
		# 消费事件，阻止继续传播
		get_viewport().set_input_as_handled()
			
func init(atlas_panel: AtlasPanel) -> void:
	atlas_panel_script = atlas_panel
	current_selected_index = -1
	load_bird_data()
	display_birds()

func select_line(selected: bool):
	is_selected = selected
	if is_selected:
		color = Color(0.0, 0.58, 0.949) # 选中时的高亮色
	else:
		color = Color("ec8658")
		clear_selection()
	select_bird_item(-1)


func load_bird_data():
	# 加载所有小鸟数据
	var bird_data_path = "res://resources/bird_data/"
	var dir = DirAccess.open(bird_data_path)
	
	# 根据 bird_type 设置标题
	var string_name = Enums.BirdType.keys()[bird_type].to_lower()
	print("=== 开始加载鸟类数据 ===")
	print("目标鸟类类型: %s" % string_name)
	print("数据路径: %s" % bird_data_path)
	
	if not dir:
		print("错误：无法打开目录 %s" % bird_data_path)
		return
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var file_count = 0
		var matched_files = 0
		
		while file_name != "":
			file_count += 1
			# print("发现文件: %s" % file_name)
			
			# 根据 bird_type 过滤小鸟
			if file_name.ends_with(".tres"):
				# print("  -> 是.tres文件")
				# print("  -> 检查是否包含 '%s': %s" % [string_name, file_name.contains(string_name)])
				if file_name.contains(string_name):
					matched_files += 1
					# 使用path_join确保路径正确拼接
					var full_path = bird_data_path.path_join(file_name)
					# print("  -> 匹配！完整路径: %s" % full_path)
					
					# 加载为BirdData资源
					var bird_resource = load(full_path) as BirdData
					
					if bird_resource:
						bird_data_list.append(bird_resource)
						print("  -> 成功加载: %s" % bird_resource.name)
					else:
						print("  -> 加载失败！无法转换为BirdData类型")
				else:
					print("  -> 不匹配，跳过")
			else:
				print("  -> 不是.tres文件，跳过")
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("=== 扫描完成 ===")
		print("总文件数: %d" % file_count)
		print("匹配文件数: %d" % matched_files)
		print("成功加载: %d" % bird_data_list.size())
	
	title.text = string_name.capitalize()
	# 按鸟名排序
	bird_data_list.sort_custom(func(a, b): return a.name < b.name)

func display_birds():
	# 清除现有的小鸟项
	for child in bird_container.get_children():
		child.queue_free()
	
	bird_items.clear()

	# 创建小鸟项
	for bird in bird_data_list:
		var bird_item = bird_button_scene.instantiate()
		bird_container.add_child(bird_item)
		bird_item.setup_bird_data(self as AtlasLine, bird)
		bird_items.append(bird_item)

func select_bird_item(index: int):
	if index < 0 or index >= bird_items.size():
		return
	
	# 清除所有选中状态
	for i in range(bird_items.size()):
		bird_items[i].set_selected(i == index)
	
	current_selected_index = index


func navigate_left():
	if current_selected_index > 0:
		select_bird_item(current_selected_index - 1)

func navigate_right():
	if current_selected_index < bird_items.size() - 1:
		select_bird_item(current_selected_index + 1)

func _on_bird_selected(bird: BirdData):
	print("Selected bird: %s" % bird.name)
	atlas_panel_script._on_bird_selected(self, bird)

func update_and_clear_cur_selection():
	if current_selected_index < 0 or current_selected_index >= bird_items.size():
		return
	for i in range(bird_items.size()):
		bird_items[i].update_display()
	clear_selection()

func clear_selection():
	# 清除所有选中状态
	for i in range(bird_items.size()):
		bird_items[i].set_selected(false)
	current_selected_index = -1
