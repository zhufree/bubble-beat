extends Node2D

const COMBO_INPUT_BUFFER := 0.12
const SKILL_TRIGGER_KEY := KEY_J
const COMBO_KEYS := ["S", "D", "F"]

@onready var animalList: HBoxContainer = $Hinterland/Animals
@onready var enemy_area = $EnemyArea
@onready var attack_zone = $Hinterland/AttackZone
@onready var heavy_attack_zone = $Hinterland/HeavyAttackZone
@onready var hinterland = $Hinterland
@onready var shield_overlay = $Hinterland/ShieldOverlay
@onready var score_ui: Control = $ScoreUI
@onready var boss: Node2D = $Boss
@onready var song_player: AudioStreamPlayer2D = $SongPlayer

# 敌人数据
var enemy_types: Array[EnemyData] = []
var enemies_in_attack_zone: Array[Enemy] = []
var enemies_in_heavy_zone: Array[Enemy] = []

# 歌曲
var song_data: SongData = preload("res://resources/song_data/waiting_for_love.tres") :
	set(value):
		song_data = value
		if song_player:
			song_player.stream = song_data.stream
			song_player.bpm = song_data.BPM
			song_player.play_with_beat_offset(8)
		# 根据 BPM 计算生成间隔
		_calculate_spawn_interval_from_bpm()

# 生成设置
@export var beats_per_spawn: float = 4.0  # 每几拍生成一次敌人
@export var difficulty_multiplier: float = 1.0  # 难度倍数，越小生成越快
var spawn_interval: float = 1.5  # 根据 BPM 动态计算
var spawn_timer: float = 12.0
var current_wave: int = 0

# 计分系统
var total_score: int = 0
var current_combo: int = 0
var combo_multiplier: float = 1.0

# 技能状态
var can_attack_boss: bool = false
var can_free_attack: bool = false
var can_shield: bool = false
var skill_score_multiplier: float = 1.0

# 技能系统
var active_skills: Array = []  # 当前激活的技能列表 [{animal, skill, timer}]

# 组合键输入管理
var key_bindings: Dictionary = {}  # key_binding -> KEY_CODE
var combo_key_state: Dictionary = {}  # KEY_CODE -> press_time

# 作弊
var cheat_mode: bool = false

func _ready() -> void:
	# 加载所有敌人类型
	_load_enemy_types()
	_bind_keys()

	# 添加测试说明
	var label = Label.new()
	label.text = """测试说明:
	S - 猫头鹰攻击
	D - 啄木鸟攻击
	F - 气球熊攻击
	J - 技能触发键（需与位键组合）
	O - 作弊模式（无伤）
	S+J - 释放猫头鹰技能
	D+J - 释放啄木鸟技能
	F+J - 释放气球熊技能
	S+D+J - 同时释放猫头鹰与啄木鸟技能
	黄色是猫头鹰、啄木鸟的判定区域
	紫色是气球熊的判定区域
	"""
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)

	# 连接攻击区域信号
	if attack_zone:
		attack_zone.area_entered.connect(_on_attack_zone_area_entered)
		attack_zone.area_exited.connect(_on_attack_zone_area_exited)
	
	# 连接重型攻击区域信号
	if heavy_attack_zone:
		heavy_attack_zone.area_entered.connect(_on_heavy_zone_area_entered)
		heavy_attack_zone.area_exited.connect(_on_heavy_zone_area_exited)

	# 连接歌曲结束信号
	if song_player:
		song_player.finished.connect(_on_song_player_finished)
	
	# 初始化生成间隔
	_calculate_spawn_interval_from_bpm()

# 加载敌人类型
func _load_enemy_types() -> void:
	enemy_types.append(load("res://resources/enemy_data/single_tap.tres"))
	enemy_types.append(load("res://resources/enemy_data/multi_tap.tres"))
	enemy_types.append(load("res://resources/enemy_data/giant.tres"))

	# 预加载场景到缓存
	EnemySpawner.preload_from_enemy_datas(enemy_types)

func _process(delta: float) -> void:
	_update_skill_effects(delta)

	# 敌人生成逻辑
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			match event.keycode:
				KEY_J:
					_execute_pending_skills()
				KEY_O:
					cheat_mode = not cheat_mode
					can_shield = cheat_mode
					if cheat_mode and shield_overlay and shield_overlay.has_method("show_shield"):
						shield_overlay.show_shield()
					if not cheat_mode and shield_overlay and shield_overlay.has_method("hide_shield"):
						shield_overlay.hide_shield()
					print("[Cheat] 作弊模式: ", cheat_mode)
				_:
					if key_bindings.has(event.keycode):
						combo_key_state[event.keycode] = 0.0
						_try_attack(key_bindings[event.keycode])
		elif event.is_released():
			match event.keycode:
				KEY_S:
					combo_key_state.erase(KEY_S)
				KEY_D:
					combo_key_state.erase(KEY_D)
				KEY_F:
					combo_key_state.erase(KEY_F)

# 根据 BPM 计算生成间隔
func _calculate_spawn_interval_from_bpm() -> void:
	if not song_data or song_data.BPM <= 0:
		spawn_interval = 1.5  # 默认值
		return
	
	# 计算每拍的时间（秒）
	var beat_duration = 60.0 / float(song_data.BPM)
	
	# 根据难度和节拍数计算生成间隔
	spawn_interval = beat_duration * beats_per_spawn * difficulty_multiplier
	
	# 确保生成间隔在合理范围内
	spawn_interval = clamp(spawn_interval, 0.5, 4.0)
	
	print("[Gameplay] BPM: %d, 每拍时间: %.2fs, 生成间隔: %.2fs (每 %.1f 拍)" % [
		song_data.BPM, beat_duration, spawn_interval, beats_per_spawn
	])

# 生成敌人组
func _spawn_enemy() -> void:
	if enemy_types.is_empty():
		return

	# 生成随机敌人组
	var enemy_group = _generate_random_enemy_group()

	# 计算组内间距
	var group_spacing = 100.0
	var total_width = (enemy_group.size() - 1) * group_spacing
	var start_x = -total_width / 2.0

	# 生成组内每个敌人
	for i in range(enemy_group.size()):
		var enemy_data = enemy_group[i]
		var offset_x = start_x + i * group_spacing

		# 使用 EnemySpawner 工厂生成敌人
		var enemy_instance = EnemySpawner.spawn(
			enemy_data,
			enemy_area,
			hinterland.position.y - 100.0,
			200.0  # move_speed
		)

		if not enemy_instance or enemy_instance.is_empty():
			push_error("Failed to spawn enemy!")
			continue

		# 设置X轴偏移（组内间距）
		for enemy in enemy_instance:
			enemy.position.x += offset_x

		# 连接信号
		_connect_enemy_signals(enemy_instance)

## 生成随机敌人组
## 规则：
## 1. 数组长度不超过动物数量（3个）
## 2. 除了单点以外的敌人，不能在数组内出现两次及以上
## @return: 敌人数据数组
func _generate_random_enemy_group() -> Array[EnemyData]:
	var group: Array[EnemyData] = []
	var max_animals = 3  # 动物数量

	# 加权随机选择组的大小 (1-3)
	var group_size = floor(sqrt(randi_range(1, max_animals * max_animals)))

	# 跟踪已使用的非单点敌人
	var used_non_single: Dictionary = {}  # enemy_type -> bool

	for i in range(group_size):
		var available_types: Array[EnemyData] = []

		# 筛选可用的敌人类型
		for enemy_data in enemy_types:
			# 单点敌人总是可用
			if enemy_data.name == "单点" or not enemy_data.name:
				available_types.append(enemy_data)
			# 非单点敌人检查是否已使用
			elif not used_non_single.has(enemy_data.name):
				available_types.append(enemy_data)

		if available_types.is_empty():
			# 如果没有可用类型，使用单点敌人
			available_types.append(enemy_types[0])  # 单点敌人

		# 加权随机选择一个敌人类型
		var selected_enemy = EnemySpawner.select_weighted(available_types, [0.8, 0.1, 0.1])
		group.append(selected_enemy)
		
		# 标记非单点敌人为已使用
		if selected_enemy.name != "单点" and selected_enemy.name:
			used_non_single[selected_enemy.name] = true

	# 排序 单点->连按->巨大化
	group.sort_custom(func(a, b):
		if a.name == "单点":
			return true
		elif b.name == "单点":
			return false
		elif a.name == "连按":
			return true
		elif b.name == "巨大化":
			return true
		else:
			return false
	)

	return group

## 连接敌人信号
func _connect_enemy_signals(enemy_instance: Array[Enemy]) -> void:
	for enemy in enemy_instance:
		if enemy is Enemy:
			enemy.defeated.connect(_on_enemy_defeated)
			enemy.reached_hinterland.connect(_on_enemy_reached_hinterland)

# 尝试攻击
func _try_attack(animal) -> void:
	if not animal.can_attack():
		return

	# 检查是否为重型动物，使用特殊攻击逻辑
	if animal.animal_data.animal_type == AnimalData.AnimalType.HEAVY:
		_try_heavy_attack(animal)
		return

	# 对于普通动物，先尝试并行攻击组内敌人
	if _try_parallel_attack(animal):
		return

	# 如果没有组内攻击，执行常规单个攻击
	_try_single_attack(animal)

## 尝试并行攻击（处理同组敌人）
## @param animal: 攻击的动物
## @return: 是否成功执行了并行攻击
func _try_parallel_attack(_animal) -> bool:
	# 查找攻击区域内的敌人
	var hit_enemy: Enemy = null
	for enemy in enemies_in_attack_zone:
		if enemy and not enemy.is_defeated:
			hit_enemy = enemy
			break

	if not hit_enemy:
		return false

	# 检查是否有同组的其他敌人在攻击区域内
	var group_enemies: Array[Enemy] = _find_enemy_group(hit_enemy)

	if group_enemies.size() <= 1:
		# 只有单个敌人，不是并行攻击
		return false

	# 并行攻击：检查每个组内敌人对应的动物是否按下了按键
	var all_keys_pressed = true
	var animals_to_attack: Array = []

	for group_enemy in group_enemies:
		var target_animal = _find_animal_for_enemy(group_enemy)
		if target_animal and _is_animal_key_pressed(target_animal):
			animals_to_attack.append({"animal": target_animal, "enemy": group_enemy})
		else:
			all_keys_pressed = false
			break

	# 如果所有对应的按键都被按下，执行并行攻击
	if all_keys_pressed and animals_to_attack.size() == group_enemies.size():
		for attack_data in animals_to_attack:
			var atk_animal = attack_data["animal"]
			var atk_enemy = attack_data["enemy"]

			if atk_animal.can_attack():
				var damage = atk_animal.free_attack() if can_free_attack else atk_animal.attack()
				atk_enemy.take_damage(damage, EnemyData.DamageType.TAP)

		print("[Parallel Attack] 同时攻击 ", group_enemies.size(), " 个组内敌人")
		return true

	return false

## 尝试单个攻击
func _try_single_attack(animal) -> void:
	# 查找攻击区域内的敌人
	var hit_enemy: Enemy = null
	for enemy in enemies_in_attack_zone:
		if enemy and not enemy.is_defeated:
			hit_enemy = enemy
			break

	if hit_enemy:
		var damage = animal.free_attack() if can_free_attack else animal.attack()
		hit_enemy.take_damage(damage, EnemyData.DamageType.TAP)
	else:
		print("[Attack] 攻击区域内没有可攻击的敌人")

## 查找敌人所在的组（基于X轴位置接近的敌人）
func _find_enemy_group(enemy: Enemy) -> Array[Enemy]:
	var group: Array[Enemy] = [enemy]
	var group_threshold = 150.0  # 组内敌人的最大间距

	for other_enemy in enemies_in_attack_zone:
		if other_enemy != enemy and not other_enemy.is_defeated:
			var distance = abs(other_enemy.global_position.x - enemy.global_position.x)
			if distance <= group_threshold:
				group.append(other_enemy)

	return group

## 根据敌人位置找到对应的动物（基于X轴位置）
func _find_animal_for_enemy(enemy: Enemy) -> Control:
	var animals = animalList.get_children()
	if animals.is_empty():
		return null

	# 简化逻辑：根据敌人的X位置找到最接近的动物
	var enemy_x = enemy.global_position.x
	var screen_center_x = get_viewport_rect().size.x / 2.0
	var relative_x = enemy_x - screen_center_x

	# 将屏幕分成3个区域（对应3个动物）
	var zone_width = 200.0
	var zone_index = 0

	if relative_x < -zone_width / 2:
		zone_index = 0  # 左侧
	elif relative_x > zone_width / 2:
		zone_index = 2  # 右侧
	else:
		zone_index = 1  # 中间

	zone_index = clamp(zone_index, 0, animals.size() - 1)
	return animals[zone_index]

## 检查动物对应的按键是否被按下
func _is_animal_key_pressed(animal) -> bool:
	if not animal or not animal.has_method("key_binding"):
		return false

	var key_code = _get_key_by_string(animal.key_binding)
	return combo_key_state.has(key_code)

# 重型动物范围攻击
func _try_heavy_attack(animal) -> void:
	if not animal.can_attack():
		return

	var remaining_damage = animal.animal_data.single_attack_damage
	var damage_enemies: Array[Dictionary] = [] # {enemy: Enemy, damage: float}

	# 优先攻击巨大化敌人
	var giant_enemies: Array[Enemy] = []
	var normal_enemies: Array[Enemy] = []

	for enemy in enemies_in_heavy_zone:
		if enemy and not enemy.is_defeated:
			if enemy.enemy_data.name == "巨大化":
				giant_enemies.append(enemy)
			else:
				normal_enemies.append(enemy)

	# 先处理巨大化敌人，再处理普通敌人
	var sorted_enemies = giant_enemies + normal_enemies

	# 按顺序攻击圆形范围内的敌人
	for enemy in sorted_enemies:
		if remaining_damage > 0:
			# 计算实际造成的伤害（不超过敌人当前生命值）
			var damage_dealt = min(remaining_damage, enemy.current_health)
			damage_enemies.append({"enemy": enemy, "damage": damage_dealt})
			remaining_damage -= damage_dealt

			print("[Heavy Attack] 对 ", enemy.enemy_data.name, " 造成 ", damage_dealt, " 伤害，剩余攻击值: ", remaining_damage)

	for damage_enemy in damage_enemies:
		damage_enemy["enemy"].take_damage(damage_enemy["damage"], EnemyData.DamageType.TAP)

	# 消耗攻击次数（无论是否击中敌人）
	if can_free_attack:
		animal.free_attack()
	else:
		animal.attack()

	if enemies_in_heavy_zone.is_empty():
		print("[Heavy Attack] 范围内没有敌人")

# 辅助函数：从 Area2D 获取敌人实例
func _get_enemy_from_area(area: Area2D) -> Enemy:
	if area.has_meta("enemy_instance"):
		return area.get_meta("enemy_instance")
	else:
		return area.get_parent() as Enemy

# 重型攻击区域检测
func _on_heavy_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var enemy = _get_enemy_from_area(area)
		if enemy and not enemy.is_defeated:
			enemies_in_heavy_zone.append(enemy)

func _on_heavy_zone_area_exited(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var enemy = _get_enemy_from_area(area)
		if enemy:
			enemies_in_heavy_zone.erase(enemy)

# 敌人被击败
func _on_enemy_defeated(enemy: Enemy, score: int) -> void:
	# 增加 combo
	current_combo += 1
	combo_multiplier = _get_combo_multiplier(current_combo)

	# 增加分数
	var multiplier = combo_multiplier * max(skill_score_multiplier, 1.0)
	var earned_score = int(score * multiplier)
	total_score += earned_score

	# 更新 UI
	_update_score_ui()

	# 显示飘字效果
	_show_score_popup(enemy.global_position, earned_score)

	# 技能效果：积分转化为BOSS伤害
	if can_attack_boss and boss and not boss.is_defeated:
		boss.take_damage(earned_score)

	# 从列表中移除
	_remove_enemy_from_attack_zone(enemy)

# 敌人到达 Hinterland
func _on_enemy_reached_hinterland(enemy: Enemy) -> void:
	if can_shield:
		return

	# 对所有动物造成伤害
	var animals = animalList.get_children()
	for animal in animals:
		if animal as Control and animal.has_method("consume_energy"):
			animal.consume_energy(enemy.enemy_data.energy_damage)

	# 重置 combo
	_reset_combo()

	# 从列表中移除
	_remove_enemy_from_attack_zone(enemy)

# 进入攻击区域
func _on_attack_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		# 使用元数据获取正确的敌人实例（支持组合敌人的子敌人）
		var enemy: Enemy = null
		if area.has_meta("enemy_instance"):
			enemy = area.get_meta("enemy_instance")
		else:
			enemy = area.get_parent() as Enemy

		if enemy and not enemy.is_defeated:
			enemy.enter_attack_zone()
			enemies_in_attack_zone.append(enemy)
		else:
			print("[AttackZone] Enemy invalid or already defeated")
	else:
		print("[AttackZone] Area is not in 'enemies' group")

# 离开攻击区域
func _on_attack_zone_area_exited(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		# 使用元数据获取正确的敌人实例（支持组合敌人的子敌人）
		var enemy: Enemy = null
		if area.has_meta("enemy_instance"):
			enemy = area.get_meta("enemy_instance")
		else:
			enemy = area.get_parent() as Enemy

		if enemy:
			enemy.exit_attack_zone()
			_remove_enemy_from_attack_zone(enemy)

# 移除攻击区域的敌人
func _remove_enemy_from_attack_zone(enemy: Enemy) -> void:
	if enemy in enemies_in_attack_zone:
		enemies_in_attack_zone.erase(enemy)
	if enemy in enemies_in_heavy_zone:
		enemies_in_heavy_zone.erase(enemy)


# 获取 combo 倍率
func _get_combo_multiplier(combo: int) -> float:
	if combo <= 5:
		return 1.0
	elif combo <= 10:
		return 1.5
	elif combo <= 20:
		return 2.0
	elif combo <= 30:
		return 3.0
	elif combo <= 50:
		return 5.0
	else:
		return 10.0

# 重置 combo
func _reset_combo() -> void:
	current_combo = 0
	combo_multiplier = 1.0
	_update_score_ui()

# 更新计分 UI
func _update_score_ui() -> void:
	if score_ui and score_ui.has_method("update_score"):
		score_ui.update_score(total_score, current_combo, combo_multiplier)

# 显示分数弹出
func _show_score_popup(pos: Vector2, score: int) -> void:
	var popup = Label.new()
	popup.text = "+" + str(score)
	popup.position = pos
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	popup.z_index = 100
	add_child(popup)

	# 飘字动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", pos.y - 80, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.finished.connect(popup.queue_free)

# ==================== BOSS相关 ====================
## BOSS被击败
func _on_boss_defeated(_boss: Boss, _score: int) -> void:
	# TODO 游戏获得胜利
	pass

# ==================== 按键绑定 ====================

func _bind_keys() -> void:
	var animals = animalList.get_children()
	for i in range(animals.size()):
		var animal = animals[i]
		animal.key_binding = COMBO_KEYS[i]
		key_bindings[_get_key_by_string(animal.key_binding)] = animal

func _get_key_by_string(key: String) -> int:
	match key:
		"S":
			return KEY_S
		"D":
			return KEY_D
		"F":
			return KEY_F
		_:
			return 0

# ==================== 技能系统 ====================

## 执行技能释放
func _execute_pending_skills() -> void:
	for combo_key in combo_key_state:
		if key_bindings.has(combo_key):
			var animal = key_bindings[combo_key]
			if animal and animal.has_method("can_use_skill"):
				if animal.can_use_skill():
					_activate_skill(animal)

## 激活技能效果
func _activate_skill(animal) -> void:
	var skill: SkillData = animal.animal_data.skill
	print("[Skill] ", animal.animal_data.name, " 释放技能: ", skill.skill_name, " (类型: ", skill.skill_type, ")")
	
	# 检查是否已有相同类型的技能激活
	var existing_skill_index = -1
	for i in range(active_skills.size()):
		if active_skills[i].skill.skill_type == skill.skill_type:
			existing_skill_index = i
			break
	
	if existing_skill_index >= 0:
		# 延长现有技能时间
		active_skills[existing_skill_index].timer += skill.duration
		print("[Skill] 延长技能时间: +", skill.duration, "秒")
	else:
		# 激活新技能
		var skill_data = {
			"animal": animal,
			"skill": skill,
			"timer": skill.duration
		}
		
		# 根据技能类型激活效果
		_apply_skill_effect(skill)
		
		active_skills.append(skill_data)
		print("[Skill] 激活新技能，持续: ", skill.duration, "秒")
	
	# 播放技能特效和音效
	_play_skill_effect(animal, skill)

## 应用技能效果（激活时调用）
func _apply_skill_effect(skill: SkillData) -> void:
	match skill.skill_type:
		Enums.SkillType.FREE_ATTACK:
			can_free_attack = true
			print("[Skill] 激活免费攻击模式")
		
		Enums.SkillType.DAMAGE_TO_BOSS:
			can_attack_boss = true
			print("[Skill] 激活积分转化BOSS伤害")
		
		Enums.SkillType.SCORE_MULTIPLIER:
			skill_score_multiplier *= 2
			print("[Skill] 分数翻倍")
			score_ui.update_skill_multiplier(skill_score_multiplier)
		
		Enums.SkillType.SHIELD:
			can_shield = true
			if shield_overlay and shield_overlay.has_method("show_shield"):
				shield_overlay.show_shield()
			print("[Skill] 激活护盾模式")

## 移除技能效果（技能结束时调用）
func _remove_skill_effect(skill: SkillData) -> void:
	match skill.skill_type:
		Enums.SkillType.FREE_ATTACK:
			# 检查是否还有其他免费攻击技能激活
			var has_other_free_attack = false
			for active_skill in active_skills:
				if active_skill.skill.skill_type == Enums.SkillType.FREE_ATTACK and active_skill.skill != skill:
					has_other_free_attack = true
					break
			
			if not has_other_free_attack:
				can_free_attack = false
				print("[Skill] 关闭免费攻击模式")
		
		Enums.SkillType.DAMAGE_TO_BOSS:
			var has_other_boss_damage = false
			for active_skill in active_skills:
				if active_skill.skill.skill_type == Enums.SkillType.DAMAGE_TO_BOSS and active_skill.skill != skill:
					has_other_boss_damage = true
					break
			
			if not has_other_boss_damage:
				can_attack_boss = false
				print("[Skill] 关闭积分转化BOSS伤害")
		
		Enums.SkillType.SCORE_MULTIPLIER:
			skill_score_multiplier /= 2
			score_ui.update_skill_multiplier(skill_score_multiplier)
			print("[Skill] 分数倍率恢复至: ", skill_score_multiplier)
		
		Enums.SkillType.SHIELD:
			var has_other_shield = false
			for active_skill in active_skills:
				if active_skill.skill.skill_type == Enums.SkillType.SHIELD and active_skill.skill != skill:
					has_other_shield = true
					break
			
			if not has_other_shield:
				can_shield = false
				if not cheat_mode and shield_overlay and shield_overlay.has_method("hide_shield"):
					shield_overlay.hide_shield()
				print("[Skill] 关闭护盾模式")

## 更新技能效果（每帧调用）
func _update_skill_effects(delta: float) -> void:
	var skills_to_remove = []
	
	# 更新所有激活的技能
	for i in range(active_skills.size()):
		var skill_data = active_skills[i]
		
		# 检查动物是否还有效
		if not is_instance_valid(skill_data.animal):
			skills_to_remove.append(i)
			continue
		
		# 更新计时器
		skill_data.timer -= delta
		
		# 技能时间结束
		if skill_data.timer <= 0:
			print("[Skill] ", skill_data.animal.animal_data.name, " 的技能 ", skill_data.skill.skill_name, " 结束")
			_remove_skill_effect(skill_data.skill)
			skills_to_remove.append(i)
	
	# 移除结束的技能（从后往前删除避免索引错误）
	for i in range(skills_to_remove.size() - 1, -1, -1):
		active_skills.remove_at(skills_to_remove[i])

## 播放技能特效
func _play_skill_effect(animal, skill: SkillData) -> void:
	# 视觉效果
	if skill.particle_effect:
		var effect = skill.particle_effect.instantiate()
		effect.position = animal.global_position
		add_child(effect)
	
	# 音效
	if skill.activation_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = skill.activation_sound
		audio_player.position = animal.global_position
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
	
	# 动物闪光效果
	if animal.has_method("play_skill_animation"):
		animal.play_skill_animation(skill.effect_color)

# ==================== 歌曲相关 ====================
func _on_song_player_finished() -> void:
	print("[Song] 歌曲结束")
