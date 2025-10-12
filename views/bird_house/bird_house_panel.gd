extends Control

## 鸟屋主面板 - 简化的单焦点设计
## 参考《巫师3》、《上古卷轴》等游戏的背包系统
##
## 控制逻辑：
## - 焦点始终在卡槽网格上
## - WASD导航，右侧自动显示详情
## - Enter弹出操作菜单（修改昵称、放生、返回）
## - ESC退出菜单或退出鸟屋

enum UIMode {
	GRID_NAV,      # 网格导航模式（默认）
	ACTION_MENU,   # 操作菜单模式
	INPUT_EDIT,    # 输入编辑模式
	DIALOG         # 确认对话框模式
}

const TOTAL_SLOTS = 15
const GRID_COLUMNS = 5
const GRID_ROWS = 3
const BIRD_SLOT_CARD = preload("res://views/bird_house/BirdSlotCard.tscn")

@onready var grid_container: GridContainer = $MainContainer/VBoxContainer/ContentContainer/LeftPanel/GridScrollContainer/GridContainer
@onready var bird_count_label: Label = $MainContainer/VBoxContainer/ContentContainer/LeftPanel/StatusBar
@onready var detail_panel: Control = $MainContainer/VBoxContainer/ContentContainer/RightPanel/DetailPanel

var slot_cards: Array[PanelContainer] = []
var current_selected_index: int = -1
var current_ui_mode: UIMode = UIMode.GRID_NAV

func _ready():
	print("=== 鸟屋面板初始化（简化设计）===")
	
	# 连接详情面板信号
	detail_panel.bird_released.connect(_on_bird_released)
	detail_panel.nickname_changed.connect(_on_nickname_changed)
	detail_panel.menu_opened.connect(_on_menu_opened)
	detail_panel.menu_closed.connect(_on_menu_closed)
	detail_panel.input_started.connect(_on_input_started)
	detail_panel.input_ended.connect(_on_input_ended)
	detail_panel.dialog_started.connect(_on_dialog_started)
	detail_panel.dialog_ended.connect(_on_dialog_ended)
	
	_create_all_slots()
	_load_birds()
	_select_first_bird()
	
	print("控制：WASD导航 | Enter操作 | ESC返回")

func _input(event):
	# 根据当前模式分发输入
	match current_ui_mode:
		UIMode.GRID_NAV:
			_handle_grid_input(event)
		UIMode.ACTION_MENU:
			pass  # 由详情面板处理
		UIMode.INPUT_EDIT:
			pass  # 由LineEdit处理
		UIMode.DIALOG:
			pass  # 由对话框处理

func _handle_grid_input(event):
	"""处理网格导航模式的输入"""
	if event.is_action_pressed("up"):
		_navigate_up()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_navigate_down()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("left"):
		_navigate_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("right"):
		_navigate_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):  # Enter打开操作菜单
		_open_action_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):  # ESC退出鸟屋
		get_viewport().set_input_as_handled()
		_exit_bird_house()

func _create_all_slots():
	for child in grid_container.get_children():
		child.queue_free()
	slot_cards.clear()
	
	for i in range(TOTAL_SLOTS):
		var card = BIRD_SLOT_CARD.instantiate()
		grid_container.add_child(card)
		slot_cards.append(card)
		card.setup_slot(i, null)

func _load_birds():
	var birds: Array = BirdManager.game_save.birds
	
	print("=== 加载鸟数据 ===")
	for i in range(TOTAL_SLOTS):
		if i < birds.size():
			slot_cards[i].setup_slot(i, birds[i])
			var nickname = birds[i].nickname if birds[i].nickname else "(无昵称)"
			print("卡槽 %d: %s, 昵称: %s" % [i, birds[i].bird_data.name if birds[i].bird_data else "未知", nickname])
		else:
			slot_cards[i].setup_slot(i, null)
	
	_update_bird_count()

func _update_bird_count():
	var bird_count = BirdManager.game_save.birds.size()
	bird_count_label.text = "已拥有：%d/%d" % [bird_count, TOTAL_SLOTS]

func _select_first_bird():
	var birds = BirdManager.game_save.birds
	if birds.size() > 0:
		_select_slot(0)
	else:
		detail_panel.visible = false

func _select_slot(slot_index: int):
	"""选中指定槽位"""
	if slot_index < 0 or slot_index >= TOTAL_SLOTS:
		return
	
	# 取消之前的选中
	if current_selected_index != -1 and current_selected_index < slot_cards.size():
		slot_cards[current_selected_index].set_selected(false)
	
	# 设置新选中
	current_selected_index = slot_index
	if current_selected_index < slot_cards.size():
		slot_cards[current_selected_index].set_selected(true)
		
		# 显示详情
		var bird_slot = slot_cards[current_selected_index].bird_slot
		if bird_slot:
			detail_panel.set_bird(bird_slot)
			detail_panel.visible = true
		else:
			detail_panel.clear_bird()
			detail_panel.visible = false

func _navigate_up():
	if current_selected_index < 0:
		_select_first_bird()
		return
	var new_index = current_selected_index - GRID_COLUMNS
	if new_index >= 0:
		_select_slot(new_index)

func _navigate_down():
	if current_selected_index < 0:
		_select_first_bird()
		return
	var new_index = current_selected_index + GRID_COLUMNS
	if new_index < TOTAL_SLOTS:
		_select_slot(new_index)

func _navigate_left():
	if current_selected_index < 0:
		_select_first_bird()
		return
	var current_row = current_selected_index / GRID_COLUMNS
	var new_index = current_selected_index - 1
	if new_index >= 0 and (new_index / GRID_COLUMNS) == current_row:
		_select_slot(new_index)

func _navigate_right():
	if current_selected_index < 0:
		_select_first_bird()
		return
	var current_row = current_selected_index / GRID_COLUMNS
	var new_index = current_selected_index + 1
	if new_index < TOTAL_SLOTS and (new_index / GRID_COLUMNS) == current_row:
		_select_slot(new_index)

func _open_action_menu():
	"""打开操作菜单"""
	if current_selected_index < 0 or current_selected_index >= slot_cards.size():
		return
	
	var bird_slot = slot_cards[current_selected_index].bird_slot
	if bird_slot:
		detail_panel.open_action_menu()

func _on_menu_opened():
	current_ui_mode = UIMode.ACTION_MENU
	print("→ 操作菜单模式")

func _on_menu_closed():
	current_ui_mode = UIMode.GRID_NAV
	print("← 网格导航模式")

func _on_input_started():
	current_ui_mode = UIMode.INPUT_EDIT
	print("→ 输入编辑模式")

func _on_input_ended():
	current_ui_mode = UIMode.ACTION_MENU
	print("← 操作菜单模式")

func _on_dialog_started():
	current_ui_mode = UIMode.DIALOG
	print("→ 对话框模式")

func _on_dialog_ended():
	current_ui_mode = UIMode.ACTION_MENU
	print("← 操作菜单模式")

func _on_bird_released(bird_slot: BirdSlot):
	print("放生小鸟: ", bird_slot.bird_data.name if bird_slot.bird_data else "未知")
	
	var birds = BirdManager.game_save.birds
	var index = birds.find(bird_slot)
	
	if index != -1:
		birds.remove_at(index)
		BirdManager.save_game()
		_load_birds()
		_select_first_bird()
		current_ui_mode = UIMode.GRID_NAV

func _on_nickname_changed(bird_slot: BirdSlot, new_nickname: String):
	print("昵称修改: '%s' → 卡槽 %d" % [new_nickname, current_selected_index])
	
	# 修改数据并保存
	bird_slot.nickname = new_nickname
	BirdManager.save_game()
	
	# 刷新卡槽显示
	if current_selected_index >= 0 and current_selected_index < slot_cards.size():
		await get_tree().process_frame
		slot_cards[current_selected_index].setup_slot(current_selected_index, bird_slot)
		slot_cards[current_selected_index].set_selected(true)
		detail_panel.set_bird(bird_slot)

func _exit_bird_house():
	print("退出鸟屋")
	get_tree().change_scene_to_file("res://scenes/index.tscn")

## 调试：Ctrl+R重置
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and event.ctrl_pressed:
			print("=== 重置存档 ===")
			BirdManager.delete_save_file()
			_load_birds()
			_select_first_bird()
			current_ui_mode = UIMode.GRID_NAV
