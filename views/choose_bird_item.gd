extends TextureButton

class_name ChooseBirdItem
@onready var bird_icon: TextureRect = $MarginLine/BirdIcon
@onready var state_label: Label = $StateLabel
@onready var margin_line: ColorRect = $MarginLine
@onready var skill_ball_container: GridContainer = $MarginLine/SkillBallContainer

var bird_data: BirdData
var is_selected: bool = false
var is_navigation_selected: bool = false

#func _ready():
	## 如果在节点准备好之前就设置了数据，现在更新显示
	#if bird_data:
		#if bird_data.get_icon_texture():
			#bird_icon.texture = bird_data.get_icon_texture()
		#state_label.text = bird_data.name
		#update_display()

func setup_bird_slot(slot: BirdSlot):
	bird_data = slot.bird_data
	if not is_node_ready():
		await ready
	if bird_data:
		bird_icon.texture = bird_data.get_icon_texture()
	state_label.text = slot.get_bird_name()
	# 显示技能球
	_clear_bird_colors()
	for skill_ball in slot.skill_balls:
		var color_icon = TextureRect.new()
		color_icon.texture = skill_ball.icon
		# 使用 custom_minimum_size 而不是 size，并考虑缩放
		color_icon.custom_minimum_size = Vector2(32, 32)
		color_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if color_icon.texture:
			skill_ball_container.add_child(color_icon)
			color_icon.scale = Vector2(0.8, 0.8)
	update_display()

func _clear_bird_colors():
	for icon in skill_ball_container.get_children():
		icon.queue_free()

func set_selected(selected: bool):
	is_selected = selected
	update_display()

func set_navigation_selected(nav_selected: bool):
	is_navigation_selected = nav_selected
	update_display()

func update_display():
	# 检查节点是否准备好
	if not is_node_ready() or not bird_data:
		return
	
	# 根据选择状态更新外观
	if is_selected:
		margin_line.color = Color("ec8658") # 选中状态为绿色
		state_label.text = bird_data.name + " ✓"
	else:
		state_label.text = bird_data.name
	
	# 导航高亮
	if is_navigation_selected:
		margin_line.color = Color.YELLOW if not is_selected else Color.LIGHT_PINK
	else:
		margin_line.color = Color("ec8658") if is_selected else Color(1.2, 1.2, 1.2, 0.0)

func clear_bird_data():
	# 清空鸟类数据和显示
	bird_data = null
	is_selected = false
	is_navigation_selected = false
