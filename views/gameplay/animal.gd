extends PanelContainer

@onready var recovery_timer: Timer = $Recovery
@onready var attack_interval_timer: Timer = $AttackInterval
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# UI References
@onready var key_label: Label = $Content/IconContainer/KeyBinding/MarginContainer/Label
@onready var icon: TextureRect = $Content/IconContainer/Icon
@onready var cooldown_overlay: ColorRect = $Content/IconContainer/CooldownOverlay
@onready var current_count_label: Label = $Content/IconContainer/AttackCount/MarginContainer/HBoxContainer/CurrentLabel
@onready var max_count_label: Label = $Content/IconContainer/AttackCount/MarginContainer/HBoxContainer/MaxLabel
@onready var energy_bar: HBoxContainer = $Content/IconContainer/EnergyBar

@export var animal_data: AnimalData
@export var key_binding: String = "S"
@export var energy: int = 0: # 能量
	set(value):
		var old_energy = energy
		energy = clamp(value, 0, animal_data.skill_energy_required if animal_data else 7)
		if is_node_ready():
			_update_energy_bar(old_energy, energy)

@export var attack_count: int = 5: # 剩余攻击次数
	set(value):
		attack_count = value
		if is_node_ready():
			_update_attack_count_display()

var can_attack_status: bool = true:
	set(value):
		can_attack_status = value
		if is_node_ready():
			_update_cooldown_visual()

var energy_cells: Array[EnergyCell] = []

func _ready() -> void:
	if not animal_data:
		push_error("Animal data is missing!")
		return

	# 初始化数据
	attack_count = animal_data.max_attack_count
	icon.texture = animal_data.icon
	key_label.text = key_binding

	# 设置图标大小
	icon.custom_minimum_size = Vector2(96, 96)

	# 初始化UI
	_setup_energy_bar()
	_update_attack_count_display()
	_update_cooldown_visual()

# 设置能量条
func _setup_energy_bar() -> void:
	# 清除现有的能量格子
	for child in energy_bar.get_children():
		child.queue_free()
	energy_cells.clear()

	# 创建新的能量格子
	var energy_cell_scene = load("res://views/gameplay/energy_cell.tscn")
	for i in range(animal_data.skill_energy_required):
		var cell: EnergyCell = energy_cell_scene.instantiate()
		energy_bar.add_child(cell)
		cell.set_filled_color(animal_data.energy_color)
		energy_cells.append(cell)

# 更新能量条显示
func _update_energy_bar(old_value: int, new_value: int) -> void:
	if energy_cells.is_empty():
		return

	# 填充或清空格子
	if new_value > old_value:
		# 能量增加
		for i in range(old_value, new_value):
			if i < energy_cells.size():
				energy_cells[i].fill(true)
	else:
		# 能量减少
		for i in range(new_value, old_value):
			if i < energy_cells.size():
				energy_cells[i].drain(true)

	# 检查是否满能量
	if new_value >= animal_data.skill_energy_required:
		# 延迟启动脉动动画，等待填充动画完成
		await get_tree().create_timer(0.3).timeout
		if energy >= animal_data.skill_energy_required:  # 再次确认仍然满能量
			_start_full_energy_animation()
	elif old_value >= animal_data.skill_energy_required:
		_stop_full_energy_animation()

# 开始满能量动画
func _start_full_energy_animation() -> void:
	for cell in energy_cells:
		cell.start_full_animation()

# 停止满能量动画
func _stop_full_energy_animation() -> void:
	for cell in energy_cells:
		cell.stop_full_animation()

# 更新攻击次数显示
func _update_attack_count_display() -> void:
	if current_count_label and max_count_label and animal_data:
		current_count_label.text = str(attack_count)
		max_count_label.text = str(animal_data.max_attack_count)

		# 攻击次数变化时的动画效果
		if attack_count > 0:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			tween.tween_property(current_count_label, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(current_count_label, "scale", Vector2(1.0, 1.0), 0.15)

# 更新冷却视觉效果
func _update_cooldown_visual() -> void:
	if not animation_player:
		return

	# 当攻击次数为0或者处于冷却中时，显示灰色遮罩
	var should_show_cooldown = not can_attack_status or attack_count <= 0

	if should_show_cooldown:
		if cooldown_overlay.modulate.a < 0.1:  # 如果遮罩未显示
			animation_player.play("cooldown_start")
	else:
		if cooldown_overlay.modulate.a > 0.1:  # 如果遮罩正在显示
			animation_player.play("cooldown_end")

# 普通单次攻击
func attack() -> float:
	if can_attack():
		attack_count -= 1
		energy += 1
		can_attack_status = false
		recover_attack_count()
		attack_interval_timer.start(animal_data.attack_cooldown)

		# 攻击动画
		_play_attack_animation()

		return animal_data.single_attack_damage
	return 0.0

# 攻击动画
func _play_attack_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon, "scale", Vector2(0.85, 0.85), 0.1)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.15)

# 不消耗次数的攻击
func free_attack() -> float:
	energy += 1
	_play_attack_animation()
	return animal_data.single_attack_damage

# 恢复攻击次数
func recover_attack_count() -> void:
	if attack_count < animal_data.max_attack_count:
		recovery_timer.start(animal_data.attack_recovery_time)

# 检查攻击状态
func can_attack() -> bool:
	return can_attack_status and attack_count > 0

# 被敌人攻击
func on_enemy_attack(enemy) -> void:
	if enemy.has_method("get") and enemy.has("enemy_data"):
		consume_energy(enemy.enemy_data.energy_damage)

# 被攻击消耗能量
func consume_energy(amount: int = 1) -> void:
	energy = max(energy - amount, 0)

# 检查是否可以使用技能
func can_use_skill() -> bool:
	return energy >= animal_data.skill_energy_required and animal_data.skill != null

# 释放技能
func use_skill() -> bool:
	if can_use_skill():
		energy = 0
		# 播放释放动画
		_play_skill_release_animation()
		return true
	return false

# 播放技能动画效果
func play_skill_animation(effect_color: Color) -> void:
	# 创建闪光效果
	var flash_duration = 0.3
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# 保存原始调制颜色
	var original_modulate = modulate
	
	# 闪光效果
	tween.tween_property(self, "modulate", effect_color, flash_duration * 0.5)
	tween.tween_property(self, "modulate", original_modulate, flash_duration * 0.5)
	
	# 缩放效果
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.2)
	scale_tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.3)

# 播放技能释放动画
func _play_skill_release_animation() -> void:
	# 能量条清空动画已在 energy setter 中处理
	
	# 图标释放效果
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# 脉冲效果
	tween.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(icon, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 旋转效果
	var rotate_tween = create_tween()
	rotate_tween.set_ease(Tween.EASE_OUT)
	rotate_tween.set_trans(Tween.TRANS_QUAD)
	rotate_tween.tween_property(icon, "rotation", deg_to_rad(360), 0.5)
	rotate_tween.tween_callback(func(): icon.rotation = 0)

func _on_recovery_timer_timeout() -> void:
	if attack_count < animal_data.max_attack_count:
		attack_count += 1
		recover_attack_count()
	else:
		recovery_timer.stop()

func _on_attack_interval_timer_timeout() -> void:
	can_attack_status = true

func _on_body_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var enemy = area.get_parent()
		on_enemy_attack(enemy)
		if enemy.has_method("release_after_attack"):
			enemy.release_after_attack()
