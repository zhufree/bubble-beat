extends Control

## 鸟类详情面板 - 简化设计
## 始终显示鸟的信息，Enter打开操作菜单

signal bird_released(bird_slot: BirdSlot)
signal nickname_changed(bird_slot: BirdSlot, new_nickname: String)
signal menu_opened
signal menu_closed
signal input_started
signal input_ended
signal dialog_started
signal dialog_ended

enum MenuOption { NICKNAME, RELEASE, CANCEL }

@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var bird_icon: TextureRect = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/IconContainer/BirdIcon
@onready var bird_name: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/BirdName
@onready var bird_type: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/BirdType
@onready var bird_description: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/BirdDescription
@onready var skill_balls_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/SkillBalls
@onready var nickname_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/NicknameEdit
@onready var release_button: Button = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReleaseButton

var current_bird: BirdSlot = null
var nickname_timer: Timer = null
var is_menu_open: bool = false
var current_menu_option: MenuOption = MenuOption.NICKNAME
var active_dialog: Control = null

const CUSTOM_CONFIRM_DIALOG = preload("res://views/bird_house/custom_confirm_dialog.tscn")
const HIGHLIGHT_COLOR = Color(1.5, 1.5, 1.0, 1.0)  # 更明显的高亮
const NORMAL_COLOR = Color(1.0, 1.0, 1.0, 1.0)

func _ready():
	# 创建昵称保存计时器
	nickname_timer = Timer.new()
	nickname_timer.wait_time = 0.5
	nickname_timer.one_shot = true
	nickname_timer.timeout.connect(_save_nickname)
	add_child(nickname_timer)
	
	# 连接信号
	if nickname_edit:
		nickname_edit.text_changed.connect(_on_nickname_text_changed)
		nickname_edit.focus_entered.connect(_on_nickname_focus_entered)
		nickname_edit.focus_exited.connect(_on_nickname_focus_exited)
	
	if release_button:
		release_button.pressed.connect(_on_release_button_pressed)
	
	# 初始隐藏操作控件
	_hide_action_controls()
	visible = false

func _input(event):
	if not visible or not is_menu_open:
		return
	
	# 对话框模式
	if active_dialog:
		return
	
	# 输入模式
	if nickname_edit and nickname_edit.has_focus():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			nickname_edit.release_focus()
			get_viewport().set_input_as_handled()
		return
	
	# 菜单导航
	if event.is_action_pressed("up"):
		_menu_navigate_up()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_menu_navigate_down()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("left") or event.is_action_pressed("right"):
		# WASD左右也关闭菜单（回到网格导航）
		close_action_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):  # Enter确认
		_menu_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):  # ESC关闭菜单
		close_action_menu()
		get_viewport().set_input_as_handled()

func set_bird(bird_slot: BirdSlot):
	"""设置要显示的鸟"""
	current_bird = bird_slot
	_update_display()
	visible = true

func clear_bird():
	"""清空显示"""
	current_bird = null
	visible = false

func open_action_menu():
	"""打开操作菜单"""
	if not current_bird:
		return
	
	is_menu_open = true
	current_menu_option = MenuOption.NICKNAME
	_show_action_controls()
	_update_menu_highlight()
	menu_opened.emit()
	print("操作菜单：↑↓选择 | Enter确认 | ESC返回")

func close_action_menu():
	"""关闭操作菜单"""
	is_menu_open = false
	_hide_action_controls()
	_clear_menu_highlight()
	menu_closed.emit()

func _show_action_controls():
	"""显示操作控件"""
	if nickname_edit:
		nickname_edit.modulate = NORMAL_COLOR
	if release_button:
		release_button.modulate = NORMAL_COLOR

func _hide_action_controls():
	"""隐藏操作控件（不改变可见性，只是取消高亮）"""
	_clear_menu_highlight()

func _menu_navigate_up():
	"""菜单向上导航"""
	match current_menu_option:
		MenuOption.RELEASE:
			current_menu_option = MenuOption.NICKNAME
		MenuOption.CANCEL:
			current_menu_option = MenuOption.RELEASE
		MenuOption.NICKNAME:
			current_menu_option = MenuOption.CANCEL
	_update_menu_highlight()
	_scroll_to_current_option()

func _menu_navigate_down():
	"""菜单向下导航"""
	match current_menu_option:
		MenuOption.NICKNAME:
			current_menu_option = MenuOption.RELEASE
		MenuOption.RELEASE:
			current_menu_option = MenuOption.CANCEL
		MenuOption.CANCEL:
			current_menu_option = MenuOption.NICKNAME
	_update_menu_highlight()
	_scroll_to_current_option()

func _scroll_to_current_option():
	"""滚动到当前选中的选项 - 参考专业背包系统"""
	if not scroll_container:
		return
	
	var target_control: Control = null
	match current_menu_option:
		MenuOption.NICKNAME:
			target_control = nickname_edit
		MenuOption.RELEASE:
			target_control = release_button
		MenuOption.CANCEL:
			# Cancel通常在底部，滚动到末尾
			target_control = release_button
	
	if target_control:
		# 计算目标控件的全局位置
		var target_pos = target_control.global_position.y - scroll_container.global_position.y
		var target_size = target_control.size.y
		var scroll_height = scroll_container.size.y
		
		# 确保目标在可视区域内，留有边距
		var margin = 20.0
		var desired_scroll = target_pos - scroll_height / 2.0 + target_size / 2.0
		
		# 平滑滚动
		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_vertical", int(desired_scroll), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_menu_highlight():
	"""更新菜单高亮 - 超明显"""
	_clear_menu_highlight()
	
	match current_menu_option:
		MenuOption.NICKNAME:
			if nickname_edit:
				nickname_edit.modulate = HIGHLIGHT_COLOR
				# 添加背景高亮
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.3, 0.4, 0.3, 0.5)
				nickname_edit.add_theme_stylebox_override("normal", style)
		MenuOption.RELEASE:
			if release_button:
				release_button.modulate = HIGHLIGHT_COLOR
		MenuOption.CANCEL:
			pass  # 取消选项在标签上高亮

func _clear_menu_highlight():
	"""清除菜单高亮"""
	if nickname_edit:
		nickname_edit.modulate = NORMAL_COLOR
		nickname_edit.remove_theme_stylebox_override("normal")
	if release_button:
		release_button.modulate = NORMAL_COLOR

func _menu_confirm():
	"""确认当前菜单选项"""
	match current_menu_option:
		MenuOption.NICKNAME:
			_start_nickname_edit()
		MenuOption.RELEASE:
			_on_release_button_pressed()
		MenuOption.CANCEL:
			close_action_menu()

func _start_nickname_edit():
	"""开始编辑昵称"""
	if nickname_edit:
		input_started.emit()
		nickname_edit.grab_focus()

func _update_display():
	"""更新显示内容"""
	if not current_bird or not current_bird.bird_data:
		return
	
	var data = current_bird.bird_data
	
	# 设置图标
	if bird_icon:
		var icon_texture = data.get_icon_texture()
		if icon_texture:
			bird_icon.texture = icon_texture
	
	# 设置名称、类型、描述
	if bird_name:
		bird_name.text = data.name
	if bird_type:
		bird_type.text = _get_bird_type_text(data.bird_type)
	if bird_description:
		if data.description and data.description != "":
			bird_description.text = data.description
		else:
			bird_description.text = "这是一只可爱的小鸟。"
	
	# 设置昵称
	if nickname_edit:
		nickname_edit.text_changed.disconnect(_on_nickname_text_changed)
		nickname_edit.text = current_bird.nickname if current_bird.nickname else ""
		nickname_edit.placeholder_text = "输入昵称..."
		nickname_edit.text_changed.connect(_on_nickname_text_changed)
	
	# 显示技能球
	_update_skill_balls()

func _get_bird_type_text(bird_type: Enums.BirdType) -> String:
	match bird_type:
		Enums.BirdType.CHICK:
			return "🐣 雏鸟 (一级)"
		Enums.BirdType.FLEDGLING:
			return "🐦 幼鸟 (二级)"
		Enums.BirdType.FLYER:
			return "🦅 成鸟 (三级)"
		Enums.BirdType.PHOENIX:
			return "🔥 凤凰 (四级)"
		_:
			return "❓ 未知"

func _update_skill_balls():
	"""更新技能球显示"""
	if not skill_balls_container:
		return
	
	for child in skill_balls_container.get_children():
		child.queue_free()
	
	if current_bird and current_bird.skill_balls:
		for skill_ball in current_bird.skill_balls:
			var ball_icon = TextureRect.new()
			if skill_ball.icon:
				ball_icon.texture = skill_ball.icon
			ball_icon.custom_minimum_size = Vector2(35, 35)
			ball_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			ball_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			skill_balls_container.add_child(ball_icon)

func _on_nickname_text_changed(new_text: String):
	"""昵称文本改变"""
	if not current_bird:
		return
	if nickname_timer.is_stopped() == false:
		nickname_timer.stop()
	nickname_timer.start()

func _save_nickname():
	"""保存昵称"""
	if not current_bird or not nickname_edit:
		return
	
	var new_nickname = nickname_edit.text.strip_edges()
	print("保存昵称: '%s' -> '%s'" % [current_bird.nickname, new_nickname])
	nickname_changed.emit(current_bird, new_nickname)

func _on_nickname_focus_entered():
	"""昵称输入框获得焦点"""
	print("→ 昵称输入激活")

func _on_nickname_focus_exited():
	"""昵称输入框失去焦点"""
	print("← 昵称输入结束")
	input_ended.emit()

func _on_release_button_pressed():
	"""放生按钮按下"""
	if not current_bird:
		return
	
	# 创建自定义确认对话框
	var confirm_dialog = CUSTOM_CONFIRM_DIALOG.instantiate()
	confirm_dialog.set_message("确定要放生 [%s] 吗？\n\n此操作无法撤销！" % current_bird.get_bird_name())
	
	active_dialog = confirm_dialog
	dialog_started.emit()
	
	get_tree().root.add_child(confirm_dialog)
	
	# 连接信号
	confirm_dialog.confirmed.connect(_confirm_release.bind(confirm_dialog))
	confirm_dialog.canceled.connect(_cancel_release.bind(confirm_dialog))

func _confirm_release(dialog: Control):
	"""确认放生"""
	if current_bird:
		bird_released.emit(current_bird)
	_cleanup_dialog(dialog)

func _cancel_release(dialog: Control):
	"""取消放生"""
	print("取消放生")
	_cleanup_dialog(dialog)

func _cleanup_dialog(dialog: Control):
	"""清理对话框"""
	active_dialog = null
	dialog.queue_free()
	dialog_ended.emit()
