extends Node
var difficulty:int = 2
var selected_song: SongData
var max_combo: int = 0
var final_score: int = 0
var game_status = Enums.GameStatus.NOTSTARTED
var selected_birds: Array[BirdSlot] = []

# 生命值系统
var health: int = 1000
var max_health: int = 1000

# 护盾系统
var shields: float = 0.0  # 护盾数量（可以是小数）
var max_shields: float = 5.0  # 最大护盾数量

# 连击和分数系统
var combo: int = 0
var score: int = 0

# 评级系统
var song_rating: int = 0  # 1-3星评级
var bubble_count: int = 0  # 实际发射的气泡数量

# 获取当前连击数
func get_current_combo() -> int:
	return combo

# 获取当前分数
func get_current_score() -> int:
	return score

# 更新分数和连击
func update_score(amount: int):
	var old_score = score
	var old_combo = combo

	score += amount
	if amount > 0:
		combo += 1
		# 更新最大连击数
		if combo > max_combo:
			max_combo = combo
	elif amount <= 0:  # 0分或负分才清零连击
		combo = 0

	# 发射信号更新UI（只在值变化时发射）
	if score != old_score:
		EventBus.score_updated.emit(score)
	if combo != old_combo:
		EventBus.combo_updated.emit(combo)

# 处理生命值变化
func take_damage(amount: int):
	var old_health = health
	health -= amount
	if health < 0:
		health = 0
	print("生命值: ", health, "/", max_health)
	# 发射生命值更新信号
	if health != old_health:
		EventBus.health_updated.emit(health, max_health)
	if health <= 0:
		game_over("health")

# 回复生命值
func heal(amount: int):
	var old_health = health
	health += amount
	if health > max_health:
		health = max_health
	var actual_heal = health - old_health
	if actual_heal > 0:
		print("回复生命值: ", actual_heal, ", 当前生命值: ", health, "/", max_health)
	# 发射生命值更新信号
	EventBus.health_updated.emit(health, max_health)

# 游戏结束
func game_over(reason: String = "health"):
	game_status = Enums.GameStatus.FINISHED
	final_score = score
	max_combo = combo

	if reason == "health":
		EventBus.game_over_by_health.emit()
		EventBus.game_finished.emit()
	elif reason == "song":
		# 计算歌曲评级
		song_rating = calculate_song_rating()
		EventBus.song_finished.emit()
		EventBus.game_finished.emit()


# 添加护盾
func add_shield(amount: float):
	var old_shields = shields
	shields += amount
	if shields > max_shields:
		shields = max_shields
	print("护盾增加: ", amount, ", 当前护盾: ", shields)
	# 发射护盾更新信号
	if int(shields) != int(old_shields):
		EventBus.shield_updated.emit(int(shields), int(max_shields))

# 消耗护盾
func consume_shield() -> bool:
	if shields >= 1.0:
		shields -= 1.0
		print("护盾消耗1个, 剩余护盾: ", shields)
		# 发射护盾更新信号
		EventBus.shield_updated.emit(int(shields), int(max_shields))
		return true
	return false

# 获取当前护盾数量（整数显示）
func get_shield_count() -> int:
	return int(shields)

# 增加气泡计数
func increment_bubble_count():
	bubble_count += 1

# 重置气泡计数
func reset_bubble_count():
	bubble_count = 0

# 计算歌曲评级
func calculate_song_rating() -> int:
	if bubble_count == 0:
		return 1

	# 基础分*（2*气泡数-24.5）= 三星分数线
	var base_score = 100  # 基础分
	var three_star_threshold = base_score * (2 * bubble_count - 24.5)
	var two_star_threshold = three_star_threshold * 0.6

	if score >= three_star_threshold:
		return 3
	elif score >= two_star_threshold:
		return 2
	else:
		return 1

# 获取当前评级
func get_current_rating() -> int:
	return song_rating

# 游戏初始化 - 当歌曲开始时调用
func initialize_game():
	# 重置护盾
	shields = 0.0
	# 重置分数和连击
	score = 0
	combo = 0
	# 恢复生命值到满血
	health = max_health
	# 重置气泡计数
	bubble_count = 0
	# 重置评级
	song_rating = 0

	print("游戏状态已初始化")
	print("生命值:", health, "/", max_health)
	print("护盾:", shields)
	print("分数:", score)
	print("连击:", combo)

	# 发射信号更新UI
	EventBus.health_updated.emit(health, max_health)
	EventBus.shield_updated.emit(int(shields), int(max_shields))
	EventBus.score_updated.emit(score)
	EventBus.combo_updated.emit(combo)
