extends Node2D

@onready var animal1 = $Hinterland/Animals/Animal
@onready var animal2 = $Hinterland/Animals/Animal2
@onready var animal3 = $Hinterland/Animals/Animal3
@onready var animalList: HBoxContainer = $Hinterland/Animals
@onready var enemy_area = $EnemyArea
@onready var attack_zone = $Hinterland/AttackZone
@onready var hinterland = $Hinterland
@onready var score_ui: Control = $ScoreUI

# 敌人数据
var enemy_types: Array[EnemyData] = []
var enemies_in_attack_zone: Array[Enemy] = []

# 生成设置
@export var spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.8
@export var spawn_positions: Array[float] = [-200.0, -100.0, 0.0, 100.0, 200.0]
var spawn_timer: float = 0.0
var current_wave: int = 0

# 计分系统
var total_score: int = 0
var current_combo: int = 0
var combo_multiplier: float = 1.0


func _ready() -> void:
	# 加载所有敌人类型
	_load_enemy_types()

	# 添加测试说明
	var label = Label.new()
	label.text = """测试说明:
	S - 猫头鹰攻击
	D - 啄木鸟攻击
	F - 气球熊攻击
	Q - 猫头鹰添加能量
	W - 啄木鸟添加能量
	E - 猫头鹰消耗能量
	R - 啄木鸟消耗能量
	"""
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

	# 连接攻击区域信号
	if attack_zone:
		attack_zone.area_entered.connect(_on_attack_zone_area_entered)
		attack_zone.area_exited.connect(_on_attack_zone_area_exited)

# 加载敌人类型
func _load_enemy_types() -> void:
	enemy_types.append(load("res://resources/enemy_data/single_tap.tres"))
	enemy_types.append(load("res://resources/enemy_data/multi_tap.tres"))
	enemy_types.append(load("res://resources/enemy_data/giant.tres"))

	# 预加载场景到缓存
	EnemySpawner.preload_from_enemy_datas(enemy_types)

func _process(delta: float) -> void:
	# 敌人生成逻辑
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

		# 随着波次增加，生成速度加快
		current_wave += 1
		if current_wave % 5 == 0:
			spawn_interval = max(min_spawn_interval, spawn_interval - 0.1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				if animal1:
					_try_attack(animal1)
			KEY_D:
				if animal2:
					_try_attack(animal2)
			KEY_F:
				if animal3:
					_try_attack(animal3)
			KEY_Q:
				if animal1:
					animal1.energy += 1
					print("猫头鹰能量: ", animal1.energy, "/", animal1.animal_data.skill_energy_required)
			KEY_W:
				if animal2:
					animal2.energy += 1
					print("啄木鸟能量: ", animal2.energy, "/", animal2.animal_data.skill_energy_required)
			KEY_E:
				if animal1:
					animal1.consume_energy(1)
					print("猫头鹰能量被消耗: ", animal1.energy, "/", animal1.animal_data.skill_energy_required)
			KEY_R:
				if animal2:
					animal2.consume_energy(1)
					print("啄木鸟能量被消耗: ", animal2.energy, "/", animal2.animal_data.skill_energy_required)

# 生成敌人
func _spawn_enemy() -> void:
	if enemy_types.is_empty():
		return

	# 使用工厂的加权生成
	var weights: Array[float] = [0.6, 0.3, 0.1]  # 单点:60%, 连点:30%, 巨大化:10%

	# 使用 EnemySpawner 工厂生成敌人
	var enemy_instance = EnemySpawner.spawn_with_weights(
		enemy_types,
		weights,
		enemy_area,
		hinterland.position.y,
		200.0  # move_speed
	)

	if not enemy_instance:
		push_error("Failed to spawn enemy!")
		return

	# 连接信号（统一处理 Enemy 和 CompositeEnemy）
	_connect_enemy_signals(enemy_instance)

## 连接敌人信号（支持 Enemy 和 CompositeEnemy）
func _connect_enemy_signals(enemy_instance: Node2D) -> void:
	# 检查是否是 CompositeEnemy
	if enemy_instance is CompositeEnemy:
		var composite = enemy_instance as CompositeEnemy
		# 连接子敌人信号
		composite.child_defeated.connect(_on_enemy_defeated)
		composite.child_reached_hinterland.connect(_on_enemy_reached_hinterland)
	# 普通敌人
	elif enemy_instance is Enemy:
		var enemy = enemy_instance as Enemy
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.reached_hinterland.connect(_on_enemy_reached_hinterland)
	else:
		push_error("Unknown enemy type!")

# 尝试攻击
func _try_attack(animal) -> void:
	print("[Attack] ", animal.animal_data.name, " 尝试攻击...")
	print("[Attack] 攻击区域内的敌人数量: ", enemies_in_attack_zone.size())

	if not animal.can_attack():
		print(animal.animal_data.name, " 无法攻击（冷却中或次数耗尽）")
		return

	# 查找攻击区域内的敌人
	var hit_enemy: Enemy = null
	for enemy in enemies_in_attack_zone:
		if enemy and not enemy.is_defeated:
			hit_enemy = enemy
			break

	if hit_enemy:
		var damage = animal.attack()
		hit_enemy.take_damage(damage, EnemyData.DamageType.TAP)
		print(animal.animal_data.name, " 攻击了 ", hit_enemy.enemy_data.name, "！伤害: ", damage)
	else:
		print("[Attack] 攻击区域内没有可攻击的敌人")

# 敌人被击败
func _on_enemy_defeated(enemy: Enemy, score: int) -> void:
	# 增加 combo
	current_combo += 1
	combo_multiplier = _get_combo_multiplier(current_combo)

	# 增加分数
	var earned_score = int(score * combo_multiplier)
	total_score += earned_score

	print("击败敌人！得分: ", earned_score, " (基础: ", score, " x ", combo_multiplier, ") | Combo: ", current_combo)

	# 更新 UI
	_update_score_ui()

	# 显示飘字效果
	_show_score_popup(enemy.global_position, earned_score)

	# 从列表中移除
	_remove_enemy_from_attack_zone(enemy)

# 敌人到达 Hinterland
func _on_enemy_reached_hinterland(enemy: Enemy) -> void:
	# 对所有动物造成伤害
	var animals = animalList.get_children()
	for animal in animals:
		if animal as Control and animal.has_method("consume_energy"):
			animal.consume_energy(enemy.enemy_data.energy_damage)
			print(animal.animal_data.name, " 受到 ", enemy.enemy_data.energy_damage, " 点伤害")

	# 重置 combo
	_reset_combo()

	# 从列表中移除
	_remove_enemy_from_attack_zone(enemy)

# 进入攻击区域
func _on_attack_zone_area_entered(area: Area2D) -> void:
	print("[AttackZone] Area entered: ", area.name, " | Groups: ", area.get_groups())

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
			print("[AttackZone] Enemy added to attack zone: ", enemy.enemy_data.name, " | Total enemies: ", enemies_in_attack_zone.size())
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


# 获取 combo 倍率
func _get_combo_multiplier(combo: int) -> float:
	if combo <= 3:
		return 1.0
	elif combo <= 6:
		return 1.5
	elif combo <= 10:
		return 2.0
	elif combo <= 15:
		return 3.0
	elif combo <= 25:
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
