extends Control

## 自定义确认对话框 - 美化版
## 键盘控制：A/D或左/右箭头切换按钮，Enter确认，ESC取消

signal confirmed
signal canceled

@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var confirm_button: Button = $DialogPanel/MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton
@onready var cancel_button: Button = $DialogPanel/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton

var current_focus_index: int = 1  # 0=确定, 1=取消（默认取消，防止误操作）

func _ready():
	# 连接按钮信号
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# 设置初始焦点
	_update_button_focus()

func set_message(text: String):
	"""设置对话框消息"""
	if message_label:
		message_label.text = text

func _input(event):
	if not visible:
		return
	
	# A/D或左/右箭头切换按钮
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		current_focus_index = 0  # 确定
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		current_focus_index = 1  # 取消
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_prev"):  # Shift+Tab
		current_focus_index = (current_focus_index - 1 + 2) % 2
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_next"):  # Tab
		current_focus_index = (current_focus_index + 1) % 2
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):  # Enter确认当前按钮
		if current_focus_index == 0:
			_on_confirm_pressed()
		else:
			_on_cancel_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):  # ESC取消
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()

func _update_button_focus():
	"""更新按钮高亮 - 优雅设计"""
	# 创建高亮样式
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.5, 0.65, 0.5, 1.0)  # 绿色高亮
	highlight_style.border_width_left = 2
	highlight_style.border_width_top = 2
	highlight_style.border_width_right = 2
	highlight_style.border_width_bottom = 2
	highlight_style.border_color = Color(0.7, 0.9, 0.7, 1.0)  # 亮绿边框
	highlight_style.corner_radius_top_left = 8
	highlight_style.corner_radius_top_right = 8
	highlight_style.corner_radius_bottom_left = 8
	highlight_style.corner_radius_bottom_right = 8
	
	# 创建正常样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.3, 0.4, 0.3, 0.8)  # 深绿色
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.5, 0.4, 1.0)  # 中绿边框
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	if current_focus_index == 0:
		# 确定按钮高亮
		confirm_button.add_theme_stylebox_override("normal", highlight_style)
		confirm_button.add_theme_stylebox_override("hover", highlight_style)
		confirm_button.add_theme_stylebox_override("pressed", highlight_style)
		cancel_button.add_theme_stylebox_override("normal", normal_style)
		cancel_button.add_theme_stylebox_override("hover", normal_style)
		cancel_button.add_theme_stylebox_override("pressed", normal_style)
	else:
		# 取消按钮高亮
		confirm_button.add_theme_stylebox_override("normal", normal_style)
		confirm_button.add_theme_stylebox_override("hover", normal_style)
		confirm_button.add_theme_stylebox_override("pressed", normal_style)
		cancel_button.add_theme_stylebox_override("normal", highlight_style)
		cancel_button.add_theme_stylebox_override("hover", highlight_style)
		cancel_button.add_theme_stylebox_override("pressed", highlight_style)

func _on_confirm_pressed():
	confirmed.emit()

func _on_cancel_pressed():
	canceled.emit()
