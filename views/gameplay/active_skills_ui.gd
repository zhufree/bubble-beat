extends Control

@onready var skills_container: VBoxContainer = %SkillsContainer

# 预加载技能卡片场景
const SkillCardScene = preload("res://views/gameplay/skill_card.tscn")

# 存储当前显示的技能卡片 {skill_type: SkillCard}
var active_skill_cards: Dictionary = {}

func _ready() -> void:
	# 初始时隐藏整个UI
	visible = false

## 添加新技能显示
## @param animal_data: 释放技能的动物数据
## @param skill_data: 技能数据
## @param duration: 技能持续时间
func add_skill(animal_data: AnimalData, skill_data: SkillData, duration: float) -> void:
	if not animal_data or not skill_data:
		return

	# 如果已经存在相同类型的技能卡片，更新它
	if active_skill_cards.has(skill_data.skill_type):
		var existing_card = active_skill_cards[skill_data.skill_type]
		if is_instance_valid(existing_card):
			# 更新已存在的卡片（延长时间）
			existing_card.max_duration = duration
			existing_card.current_time = duration
			existing_card.update_time(duration)

			# 播放延长动画
			_play_extend_animation(existing_card)
			return

	# 创建新的技能卡片
	var skill_card = SkillCardScene.instantiate()
	skills_container.add_child(skill_card)

	# 设置卡片数据
	skill_card.setup(animal_data, skill_data, duration)

	# 记录卡片
	active_skill_cards[skill_data.skill_type] = skill_card

	# 显示UI
	visible = true

## 更新技能剩余时间
## @param skill_type: 技能类型
## @param remaining_time: 剩余时间
func update_skill_time(skill_type: Enums.SkillType, remaining_time: float) -> void:
	if active_skill_cards.has(skill_type):
		var card = active_skill_cards[skill_type]
		if is_instance_valid(card):
			card.update_time(remaining_time)

## 移除技能显示
## @param skill_type: 技能类型
func remove_skill(skill_type: Enums.SkillType) -> void:
	if active_skill_cards.has(skill_type):
		var card = active_skill_cards[skill_type]
		if is_instance_valid(card):
			card.fade_out_and_remove()
		active_skill_cards.erase(skill_type)

	# 如果没有技能了，隐藏整个UI
	if active_skill_cards.is_empty():
		_hide_ui()

## 隐藏UI（带动画）
func _hide_ui() -> void:
	await get_tree().create_timer(0.3).timeout
	if active_skill_cards.is_empty():
		visible = false

## 播放技能时间延长动画
func _play_extend_animation(card: PanelContainer) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)
