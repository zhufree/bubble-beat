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
var max_shields: float = 10.0  # 最大护盾数量

# 连击和分数系统
var combo: int = 0
var score: int = 0

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
	health -= amount
	if health < 0:
		health = 0
	print("生命值: ", health, "/", max_health)
	if health <= 0:
		game_over()

# 回复生命值
func heal(amount: int):
	var old_health = health
	health += amount
	if health > max_health:
		health = max_health
	var actual_heal = health - old_health
	if actual_heal > 0:
		print("回复生命值: ", actual_heal, ", 当前生命值: ", health, "/", max_health)

# 游戏结束
func game_over():
	game_status = Enums.GameStatus.FINISHED
	final_score = score
	max_combo = combo
	EventBus.game_finished.emit(final_score, max_combo)
	# 停止游戏
	get_tree().paused = true

# 添加护盾
func add_shield(amount: float):
	shields += amount
	if shields > max_shields:
		shields = max_shields
	print("护盾增加: ", amount, ", 当前护盾: ", shields)

# 消耗护盾
func consume_shield() -> bool:
	if shields >= 1.0:
		shields -= 1.0
		print("护盾消耗1个, 剩余护盾: ", shields)
		return true
	return false

# 获取当前护盾数量（整数显示）
func get_shield_count() -> int:
	return int(shields)
