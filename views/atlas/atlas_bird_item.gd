extends TextureButton

class_name AtlasBirdItem

@onready var margin_line: ColorRect = $MarginLine
@onready var state_label: Label = $StateLabel
@onready var bird_icon: TextureRect = $MarginLine/BirdIcon


var bird_data: BirdData
var is_selected: bool = false
var is_unlocked: bool = false
var atlas_line_script: AtlasLine = null

func _ready():
	# 设置按钮属性
	toggle_mode = false

func setup_bird_data(atlas_line: AtlasLine, data: BirdData):
	bird_data = data
	atlas_line_script = atlas_line
	is_unlocked = BirdManager.get_bird_atlas(data.name)
	set_selected(false)
	update_display()
	

func update_display():
	if bird_icon and bird_data.get_icon_texture():
		bird_icon.texture = bird_data.get_icon_texture()
	if state_label:
		if is_unlocked:
			state_label.text = bird_data.name
		else:
			state_label.text = "Unlock"

func set_selected(selected: bool):
	is_selected = selected
	update_visual_state()

func update_visual_state():
	if is_selected:
		margin_line.color = Color("ec8658") # 选中时的高亮色
	else:
		margin_line.color = Color(1.2, 1.2, 1.2, 0.0)
