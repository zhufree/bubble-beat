extends Control

class_name GameResultModal

@onready var background: ColorRect = $Background
@onready var modal_panel: PanelContainer = $CenterContainer/ModalPanel
@onready var title_label: Label = $CenterContainer/ModalPanel/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $CenterContainer/ModalPanel/VBoxContainer/ComboLabel
@onready var new_bird_label: Label = $CenterContainer/ModalPanel/VBoxContainer/VBoxContainer/NewBirdLabel
@onready var bird_slot_card: Control = $CenterContainer/ModalPanel/VBoxContainer/VBoxContainer/BirdSlotCard
@onready var return_button: Button = $CenterContainer/ModalPanel/VBoxContainer/ReturnButton

func _ready():
	EventBus.game_over_by_health.connect(_on_game_over_by_health)
	EventBus.song_finished.connect(_on_song_finished)
	EventBus.game_finished.connect(_on_game_finished)
	visible = false

func _on_game_over_by_health():
	title_label.text = "游戏失败…"

func _on_song_finished():
	title_label.text = "游戏胜利！"
	show_rating(Global.get_current_rating())

func _on_game_finished():
	show_result(Global.final_score, Global.max_combo)

func show_result(final_score: int, max_combo: int):
	score_label.text = "最终得分: " + str(final_score)
	combo_label.text = "最大连击: " + str(max_combo)

	visible = true

	var tween = create_tween()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)

	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(func(): return_button.grab_focus())

# 显示评级
func show_rating(rating: int):
	var stars_text = ""
	for i in range(rating):
		stars_text += "★"
	for i in range(3 - rating):
		stars_text += "☆"

	# 在标题下方显示星级
	var rating_label = Label.new()
	rating_label.text = stars_text
	rating_label.horizontal_alignment = 1
	rating_label.modulate = Color(1.0, 0.8, 0.0)  # 金色

	# 将星级标签插入到标题和分数之间
	var vbox = $CenterContainer/ModalPanel/VBoxContainer
	vbox.add_child(rating_label)
	vbox.move_child(rating_label, 1)  # 移动到标题后面

	# 根据评级处理小鸟获得
	handle_bird_reward(rating)

# 处理小鸟奖励
func handle_bird_reward(rating: int):
	if rating >= 1:
		new_bird_label.visible = true
		bird_slot_card.visible = true
		# 生成新的小鸟并显示在UI中
		var new_bird = generate_new_bird(rating)
		if new_bird and bird_slot_card.has_method("setup_slot"):
			bird_slot_card.setup_slot(0,new_bird)
	else:
		new_bird_label.visible = false
		bird_slot_card.visible = false

# 生成新的小鸟
func generate_new_bird(rating: int):
	# 检查是否有足够的父母小鸟
	if Global.selected_birds.size() < 2:
		print("父母小鸟数量不足，无法生成新小鸟")
		return null

	# 随机选择两只不同的父母小鸟
	var parent_indices = []
	while parent_indices.size() < 2:
		var random_index = randi() % Global.selected_birds.size()
		if not parent_indices.has(random_index):
			parent_indices.append(random_index)

	var parent1 = Global.selected_birds[parent_indices[0]]
	var parent2 = Global.selected_birds[parent_indices[1]]

	print("选择父母:", parent1.get_bird_name(), "和", parent2.get_bird_name())

	# 合并父母的技能球
	var offspring_skill_balls = inherit_skill_balls(parent1.skill_balls, parent2.skill_balls, rating)

	if offspring_skill_balls.size() == 0:
		print("未能生成有效的技能球组合")
		return null

	# 通过BirdManager生成新小鸟
	var new_bird_slot = BirdManager.add_bird(offspring_skill_balls)

	print("生成新小鸟成功:", new_bird_slot.get_bird_name(), "技能球数量:", offspring_skill_balls.size())

	return new_bird_slot

# 技能球遗传逻辑
func inherit_skill_balls(parent1_balls: Array[SkillBall], parent2_balls: Array[SkillBall], rating: int) -> Array[SkillBall]:
	var combined_balls = parent1_balls + parent2_balls
	var color_count = {}
	var offspring_balls:Array[SkillBall] = []

	# 统计每种颜色的技能球数量
	for ball in combined_balls:
		var color = ball.skill_color
		if not color_count.has(color):
			color_count[color] = []
		color_count[color].append(ball)

	# 对每种颜色进行遗传处理
	for color in color_count.keys():
		var balls_of_color = color_count[color]
		var ball_count = balls_of_color.size()

		if ball_count == 0:
			continue

		# 必定保留第一个
		offspring_balls.append(balls_of_color[0])

		# 如果有多个，根据评级决定是否保留第二个
		if ball_count >= 2:
			var retention_chance = get_retention_chance(rating)
			if randf() < retention_chance:
				offspring_balls.append(balls_of_color[1])

		# 最多保留2个同色技能球
		if offspring_balls.size() >= 6:  # 最多6个技能球（2个颜色 × 3个，但实际最多2×2=4个）
			break

	print("技能球遗传完成，获得", offspring_balls.size(), "个技能球")
	for ball in offspring_balls:
		print(" -", ball.skill_color)

	return offspring_balls

# 获取技能球保留概率
func get_retention_chance(rating: int) -> float:
	match rating:
		1: return 0.25  # 一星25%
		2: return 0.50  # 二星50%
		3: return 1.00  # 三星100%
		_: return 0.25  # 默认25%

func _on_return_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/song_list.tscn")


func _input(event):
	if visible and event.is_action_pressed("ok"):
		_on_return_button_pressed()
