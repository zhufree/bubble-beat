extends PanelContainer

@onready var animal_icon: TextureRect = $MarginContainer/VBoxContainer/TopRow/AnimalIcon
@onready var skill_name_label: Label = $MarginContainer/VBoxContainer/TopRow/InfoContainer/SkillName
@onready var description_label: Label = $MarginContainer/VBoxContainer/TopRow/InfoContainer/Description
@onready var time_progress: ProgressBar = $MarginContainer/VBoxContainer/TimeProgress

var skill_type: Enums.SkillType
var max_duration: float = 5.0
var current_time: float = 5.0

func _ready() -> void:
	# 淡入动画
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

## 初始化技能卡片
func setup(animal_data: AnimalData, skill_data: SkillData, duration: float) -> void:
	if not animal_data or not skill_data:
		return

	skill_type = skill_data.skill_type
	max_duration = duration
	current_time = duration

	# 设置UI内容
	animal_icon.texture = animal_data.icon
	skill_name_label.text = skill_data.skill_name
	description_label.text = skill_data.description

	# 设置进度条颜色
	time_progress.modulate = skill_data.effect_color
	time_progress.value = 1.0

	# 技能背景色（使用动物颜色）
	var style_box = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style_box:
		style_box.bg_color = Color(animal_data.energy_color.r, animal_data.energy_color.g, animal_data.energy_color.b, 0.2)
		add_theme_stylebox_override("panel", style_box)

## 更新剩余时间
func update_time(remaining_time: float) -> void:
	current_time = remaining_time

	# 更新进度条
	if max_duration > 0:
		time_progress.value = current_time / max_duration

	# 时间即将耗尽时的闪烁效果
	if current_time <= 1.0 and current_time > 0:
		_start_warning_animation()

## 淡出并移除
func fade_out_and_remove() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

## 警告动画（时间即将耗尽）
func _start_warning_animation() -> void:
	if not has_node("WarningTween"):
		var tween = create_tween()
		tween.set_loops()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(time_progress, "modulate:a", 0.3, 0.3)
		tween.tween_property(time_progress, "modulate:a", 1.0, 0.3)
