extends Button

## 测试按钮 - 循环添加不同类型的鸟

# 定义所有技能球组合（15种鸟）
var all_combinations: Array[Array] = []

var current_index = 0  # 当前添加到第几种鸟

func _ready():
	_init_combinations()
	text = "测试：添加鸟 (0/15)"

func _init_combinations() -> void:
	"""初始化所有技能球组合"""
	all_combinations = [
		# 1级鸟（单色） - 4种
		_make_ball_array([BirdManager.BLUE_SKILL_BALL]),
		_make_ball_array([BirdManager.GREEN_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL]),
		_make_ball_array([BirdManager.YELLOW_SKILL_BALL]),
		
		# 2级鸟（双色） - 6种
		_make_ball_array([BirdManager.BLUE_SKILL_BALL, BirdManager.GREEN_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.GREEN_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.YELLOW_SKILL_BALL]),
		_make_ball_array([BirdManager.YELLOW_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
		_make_ball_array([BirdManager.YELLOW_SKILL_BALL, BirdManager.GREEN_SKILL_BALL]),
		
		# 3级鸟（三色） - 4种
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.GREEN_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.YELLOW_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.YELLOW_SKILL_BALL, BirdManager.GREEN_SKILL_BALL]),
		_make_ball_array([BirdManager.YELLOW_SKILL_BALL, BirdManager.GREEN_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
		
		# 4级鸟（四色） - 1种
		_make_ball_array([BirdManager.RED_SKILL_BALL, BirdManager.YELLOW_SKILL_BALL, BirdManager.GREEN_SKILL_BALL, BirdManager.BLUE_SKILL_BALL]),
	]

func _make_ball_array(balls: Array) -> Array[SkillBall]:
	"""将普通数组转换为类型化的SkillBall数组"""
	var result: Array[SkillBall] = []
	for ball in balls:
		result.append(ball)
	return result

func _on_pressed() -> void:
	if current_index >= all_combinations.size():
		# 添加完所有种类，重置
		current_index = 0
		BirdManager.game_save.birds.clear()
		print("\n=== 已添加完所有15种鸟，重置 ===\n")
	
	# 添加当前种类的鸟
	var combo = all_combinations[current_index]
	BirdManager.add_bird(combo)
	current_index += 1
	
	# 更新按钮文字
	text = "测试：添加鸟 (%d/15)" % current_index
	
	print("✓ 添加了第 %d 种鸟，当前共有 %d 只" % [current_index, BirdManager.game_save.birds.size()])
