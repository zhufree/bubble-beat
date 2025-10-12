extends PanelContainer

## 鸟槽卡片组件
## 用于在网格中显示单个鸟槽（可能为空或已拥有）

signal slot_selected(slot_index: int, bird_slot: BirdSlot)

@onready var bird_icon: TextureRect = $MarginContainer/VBoxContainer/IconContainer/BirdIconWrapper/BirdIcon
@onready var bird_name_overlay: Label = $MarginContainer/VBoxContainer/IconContainer/BirdIconWrapper/BirdNameOverlay
@onready var nickname_label: Label = $MarginContainer/VBoxContainer/NicknameLabel
@onready var skill_balls_container: HBoxContainer = $MarginContainer/VBoxContainer/SkillBallsContainer
@onready var selection_indicator: ColorRect = $SelectionIndicator

var slot_index: int = -1
var bird_slot: BirdSlot = null
var is_empty: bool = true

# 正常状态样式
var normal_style: StyleBoxFlat
# 选中状态样式
var selected_style: StyleBoxFlat
# 空槽样式
var empty_style: StyleBoxFlat

func _ready():
	# 创建样式
	_create_styles()
	
	# 设置默认样式
	add_theme_stylebox_override("panel", empty_style if is_empty else normal_style)

func _create_styles():
	# 正常样式 - 深蓝色
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.25, 0.3, 1)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.5, 0.6, 1)
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.corner_radius_bottom_left = 10
	
	# 选中样式 - 金色边框
	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.25, 0.3, 0.35, 1)
	selected_style.border_width_left = 3
	selected_style.border_width_top = 3
	selected_style.border_width_right = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color(1, 0.8, 0, 1)
	selected_style.corner_radius_top_left = 10
	selected_style.corner_radius_top_right = 10
	selected_style.corner_radius_bottom_right = 10
	selected_style.corner_radius_bottom_left = 10
	
	# 空槽样式 - 灰色半透明
	empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0.15, 0.15, 0.15, 0.3)
	empty_style.border_width_left = 2
	empty_style.border_width_top = 2
	empty_style.border_width_right = 2
	empty_style.border_width_bottom = 2
	empty_style.border_color = Color(0.3, 0.3, 0.3, 0.3)
	empty_style.corner_radius_top_left = 10
	empty_style.corner_radius_top_right = 10
	empty_style.corner_radius_bottom_right = 10
	empty_style.corner_radius_bottom_left = 10

## 设置槽位数据
func setup_slot(index: int, slot: BirdSlot = null):
	slot_index = index
	bird_slot = slot
	is_empty = (slot == null)
	
	_update_display()

func _update_display():
	if is_empty:
		# 显示空槽状态 - 完全透明，不显示任何内容
		bird_icon.visible = false
		bird_name_overlay.visible = false
		nickname_label.visible = false
		_clear_skill_balls()
		add_theme_stylebox_override("panel", empty_style)
	else:
		# 显示鸟的信息
		if bird_slot and bird_slot.bird_data:
			bird_icon.visible = true
			bird_name_overlay.visible = true
			
			# 设置图标 - 统一大小110x110
			var icon_texture = bird_slot.bird_data.get_icon_texture()
			if icon_texture:
				bird_icon.texture = icon_texture
			
			# 设置名称叠加层（显示在图片底部）
			if bird_name_overlay and bird_slot.bird_data:
				bird_name_overlay.text = bird_slot.bird_data.name
			
		# 设置昵称标签
		if nickname_label:
			if bird_slot.nickname and bird_slot.nickname.strip_edges() != "":
				nickname_label.text = "昵称：" + bird_slot.nickname
				nickname_label.show()  # 使用show()确保可见
				nickname_label.modulate = Color(1, 1, 1, 1)  # 确保不透明
				print("✓ 卡槽 %d 设置昵称: '%s'" % [slot_index, bird_slot.nickname])
			else:
				nickname_label.hide()
		else:
			push_error("❌ nickname_label为空！路径错误！")
		
		# 显示技能球
		_update_skill_balls()
		
		add_theme_stylebox_override("panel", normal_style)

func _update_skill_balls():
	_clear_skill_balls()
	
	if bird_slot and bird_slot.skill_balls:
		for skill_ball in bird_slot.skill_balls:
			var ball_icon = TextureRect.new()
			if skill_ball.icon:
				ball_icon.texture = skill_ball.icon
			ball_icon.custom_minimum_size = Vector2(20, 20)
			ball_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			ball_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			skill_balls_container.add_child(ball_icon)

func _clear_skill_balls():
	for child in skill_balls_container.get_children():
		child.queue_free()

## 设置选中状态
func set_selected(selected: bool):
	if selected:
		add_theme_stylebox_override("panel", selected_style)
		selection_indicator.visible = true
	else:
		add_theme_stylebox_override("panel", empty_style if is_empty else normal_style)
		selection_indicator.visible = false
