class_name CompositeEnemy
extends Node2D

## 组合敌人
## 作为容器管理多个子敌人的生命周期
##
## 特性:
## - 容器本身不可见、不移动、不碰撞
## - 子敌人独立移动、战斗、计分
## - 所有子敌人被击败后，容器自动清理

signal all_children_defeated()
signal child_defeated(child_enemy: Enemy, score: int)
signal child_reached_hinterland(child_enemy: Enemy)

@export var enemy_data: CompositeEnemyData
@export var target_y: float = 880.0
@export var move_speed: float = 200.0

var child_enemies: Array[Enemy] = []
var spawner_parent: Node = null  # 子敌人的实际父节点

func _ready() -> void:
	if not enemy_data:
		push_error("CompositeEnemy: enemy_data is missing!")
		queue_free()
		return

	if not enemy_data is CompositeEnemyData:
		push_error("CompositeEnemy: enemy_data must be CompositeEnemyData type!")
		queue_free()
		return

	# 容器本身不可见
	visible = true  # 保持可见用于调试，实际上没有任何视觉元素

	# 获取父节点用于生成子敌人
	spawner_parent = get_parent()

	# 延迟一帧生成子敌人，确保父节点设置完毕
	call_deferred("_spawn_children")

## 生成所有子敌人
func _spawn_children() -> void:
	var offsets = enemy_data.get_formation_offsets()
	var child_count = enemy_data.child_enemy_datas.size()

	for i in range(child_count):
		if i >= offsets.size():
			push_warning("CompositeEnemy: Not enough formation offsets for all children")
			break

		var child_data = enemy_data.child_enemy_datas[i]
		var offset = offsets[i]

		# 使用场景路径加载子敌人
		var scene_path = child_data.get_scene_path()
		var scene = load(scene_path)
		if not scene:
			push_error("CompositeEnemy: Failed to load child enemy scene: " + scene_path)
			continue

		var child_enemy: Enemy = scene.instantiate()
		child_enemy.enemy_data = child_data
		child_enemy.target_y = target_y
		child_enemy.move_speed = move_speed

		# 设置子敌人的初始位置
		child_enemy.position = offset

		# 添加到场景（与父容器同级）
		spawner_parent.add_child(child_enemy)
		child_enemies.append(child_enemy)

		# 连接信号
		child_enemy.defeated.connect(_on_child_defeated.bind(child_enemy))
		child_enemy.reached_hinterland.connect(_on_child_reached_hinterland.bind(child_enemy))

## 子敌人被击败时
func _on_child_defeated(enemy: Enemy, score: int, child_enemy: Enemy) -> void:
	# 转发信号给外部
	child_defeated.emit(child_enemy, score)

	# 检查是否所有子敌人都被击败
	_check_all_defeated()

## 子敌人到达 Hinterland 时
func _on_child_reached_hinterland(enemy: Enemy, child_enemy: Enemy) -> void:
	# 转发信号给外部
	child_reached_hinterland.emit(child_enemy)

	# 从列表中移除（子敌人会自己销毁）
	if child_enemy in child_enemies:
		child_enemies.erase(child_enemy)

	# 检查是否所有子敌人都消失
	_check_all_defeated()

## 检查所有子敌人是否都被击败或消失
func _check_all_defeated() -> void:
	# 清理无效的引用
	child_enemies = child_enemies.filter(func(e): return is_instance_valid(e))

	# 检查剩余的子敌人是否都已被击败
	var all_defeated = true
	for child in child_enemies:
		if not child.is_defeated:
			all_defeated = false
			break

	if all_defeated and child_enemies.size() > 0:
		# 所有子敌人都被击败
		all_children_defeated.emit()
		# 等待子敌人动画结束后再清理容器
		await get_tree().create_timer(0.5).timeout
		queue_free()
	elif child_enemies.is_empty():
		# 所有子敌人都消失（到达底部或其他原因）
		queue_free()

## 获取存活的子敌人数量
func get_alive_child_count() -> int:
	var count = 0
	for child in child_enemies:
		if is_instance_valid(child) and not child.is_defeated:
			count += 1
	return count

## 获取所有子敌人
func get_children_enemies() -> Array[Enemy]:
	return child_enemies.duplicate()
