extends TextureButton

class_name ChooseBirdItem
@onready var bird_icon: TextureRect = $MarginLine/BirdIcon
@onready var state_label: Label = $StateLabel
@onready var margin_line: ColorRect = $MarginLine

var bird_data: BirdData
var is_selected: bool = false
var is_navigation_selected: bool = false

func _ready():
	# 如果在节点准备好之前就设置了数据，现在更新显示
	if bird_data:
		if bird_data.get_icon_texture():
			bird_icon.texture = bird_data.get_icon_texture()
		state_label.text = bird_data.name
		update_display()

func setup_bird_data(data: BirdData):
	bird_data = data
	
	# 如果节点还没有准备好，等待 _ready 调用
	if not is_node_ready():
		await ready
	
	if bird_data:
		if bird_data.get_icon_texture():
			bird_icon.texture = bird_data.get_icon_texture()
		state_label.text = bird_data.name
	update_display()

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
