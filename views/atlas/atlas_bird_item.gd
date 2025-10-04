extends TextureButton

class_name AtlasBirdItem

# Reference to BirdManager (assuming it's an autoload)
# If BirdManager is not an autoload, you'll need to pass it as a dependency

@onready var margin_line: ColorRect = $MarginLine
@onready var state_label: Label = $StateLabel
@onready var bird_icon: TextureRect = $MarginLine/BirdIcon


var bird_data: BirdData
var is_selected: bool = false

signal bird_selected(bird: BirdData)

func _ready():
	# 连接按钮信号
	pressed.connect(_on_button_pressed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	# 设置按钮属性
	toggle_mode = false

func setup_bird_data(data: BirdData):
	bird_data = data
	# Check if BirdManager exists as autoload, otherwise use default values
	var bird_progress
	if has_node("/root/BirdManager"):
		bird_progress = get_node("/root/BirdManager").get_bird_progress(data.name)
	else:
		# Default progress when BirdManager is not available
		bird_progress = {"is_unlocked": true}
	
	if bird_icon and data.get_icon_texture():
		bird_icon.texture = data.get_icon_texture()
	if state_label:
		if (bird_progress.is_unlocked):
			state_label.text = bird_data.resource_name
		else:
			state_label.text = "Unlock"

func set_selected(selected: bool):
	is_selected = selected
	update_visual_state()

func update_visual_state():
	if is_selected:
		margin_line.color = Color(0.0, 0.58, 0.949, 1.0) # 选中时的高亮色
	else:
		margin_line.color = Color(1.2, 1.2, 1.2, 0.0)

func _on_button_pressed():
	bird_selected.emit(bird_data)

func _on_focus_entered():
	# 获得焦点时的视觉反馈
	if not is_selected:
		margin_line.color = Color(1.2, 1.2, 1.2, 0.0)

func _on_focus_exited():
	# 失去焦点时恢复状态
	update_visual_state()
