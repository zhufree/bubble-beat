extends Button

class_name SongItem

@onready var song_name_label: Label = $VBoxContainer/SongNameLabel
@onready var bpm_label: Label = $VBoxContainer/BPMLabel

var song_data: SongData
var is_selected: bool = false

signal song_selected(song: SongData)

func _ready():
	# 连接按钮信号
	pressed.connect(_on_button_pressed)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	# 设置按钮属性
	toggle_mode = false

func setup_song_data(data: SongData):
	song_data = data
	if song_name_label:
		song_name_label.text = data.name
	if bpm_label:
		bpm_label.text = "BPM: " + str(data.BPM)

func set_selected(selected: bool):
	is_selected = selected
	update_visual_state()

func update_visual_state():
	if is_selected:
		modulate = Color(1.2, 1.2, 1.0)  # 选中时的高亮色
	else:
		modulate = Color.WHITE

func _on_button_pressed():
	song_selected.emit(song_data)

func _on_focus_entered():
	# 获得焦点时的视觉反馈
	if not is_selected:
		modulate = Color(1.1, 1.1, 1.1)

func _on_focus_exited():
	# 失去焦点时恢复状态
	update_visual_state()
