extends HBoxContainer
@onready var right_arrow: TextureRect = $RightArrow
@onready var button: Button = $Button
@onready var left_arrow: TextureRect = $LeftArrow

@export var button_text: String = "Play!"
@export var selected: bool = false

func _ready():
	button.text = button_text
	set_selected(selected)

func _process(_delta):
	if selected:
		# 两个arrow呼吸式渐隐渐显
		right_arrow.modulate.a = sin((Time.get_ticks_msec() / 300.0) * PI) * 0.5 + 0.5
		left_arrow.modulate.a = sin((Time.get_ticks_msec() / 300.0) * PI) * 0.5 + 0.5
	else:
		right_arrow.modulate.a = 0.0
		left_arrow.modulate.a = 0.0
	
func set_selected(state: bool):
	selected = state
	if selected:
		button.grab_focus()
		right_arrow.visible = true
		left_arrow.visible = true
	else:
		right_arrow.visible = false
		left_arrow.visible = false
	
