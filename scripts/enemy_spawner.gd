class_name EnemySpawner
extends Node

## 敌人生成器
## 负责根据 EnemyData 智能生成对应的敌人实例
##
## 设计理念:
## - 工厂模式：统一的生成接口
## - 自动识别：通过数据对象的虚函数获取场景路径
## - 场景缓存：减少重复加载开销
## - 加权随机：支持概率生成

# 场景缓存
static var _scene_cache: Dictionary = {}

## 生成单个敌人
## @param enemy_data: 敌人数据
## @param parent: 父节点（敌人将被添加到此节点）
## @param spawn_position: 生成位置
## @param target_y: 目标Y坐标
## @param move_speed: 移动速度
## @return: 生成的敌人实例（Enemy）或子敌人数组（CompositeEnemy）
static func spawn(
	enemy_data: EnemyData,
	parent: Node,
	target_y: float = 880.0,
	move_speed: float = 200.0
) -> Array[Enemy]:
	if not enemy_data:
		push_error("EnemySpawner: enemy_data is null!")
		return []

	if not parent:
		push_error("EnemySpawner: parent node is null!")
		return []

	# 检查是否是组合敌人
	if enemy_data is CompositeEnemyData:
		return _spawn_composite_enemy(enemy_data, parent, target_y, move_speed)

	# 普通敌人生成
	# 通过数据对象的虚函数获取场景路径（多态）
	var scene_path = enemy_data.get_scene_path()

	# 从缓存加载或首次加载场景
	var scene: PackedScene = _get_cached_scene(scene_path)
	if not scene:
		push_error("EnemySpawner: Failed to load scene: " + scene_path)
		return []

	# 实例化敌人
	var enemy_instance: Node2D = scene.instantiate()

	# 设置属性
	enemy_instance.enemy_data = enemy_data

	# 根据类型设置特定属性
	if "target_y" in enemy_instance:
		enemy_instance.target_y = target_y
	if "move_speed" in enemy_instance:
		enemy_instance.move_speed = move_speed

	# 添加到父节点
	parent.add_child(enemy_instance)

	return [enemy_instance]

## 生成组合敌人（内部方法）
## @param composite_data: 组合敌人数据
## @param parent: 父节点
## @param target_y: 目标Y坐标
## @param move_speed: 移动速度
## @return: 子敌人数组
static func _spawn_composite_enemy(
	enemy_data: EnemyData,
	parent: Node,
	target_y: float = 880.0,
	move_speed: float = 200.0
) -> Array[Enemy]:	
	var enemies: Array[Enemy] = []
	var offsets: Array[Vector2] = enemy_data.get_formation_offsets()

	for i in range(enemy_data.child_enemy_datas.size()):
		if i >= offsets.size():
			push_warning("EnemySpawner: Not enough formation offsets for all children")
			break

		var child_data = enemy_data.child_enemy_datas[i]
		var offset = offsets[i]
	
		# 使用场景路径加载子敌人
		var scene_path = child_data.get_scene_path()
		var scene = _get_cached_scene(scene_path)
		if not scene:
			push_error("EnemySpawner: Failed to load child enemy scene: " + scene_path)
			continue

		var child_enemy: Enemy = scene.instantiate()
		child_enemy.enemy_data = child_data
		child_enemy.target_y = target_y
		child_enemy.move_speed = move_speed

		# 设置子敌人的初始位置偏移
		child_enemy.position = offset

		# 添加到父节点
		parent.add_child(child_enemy)
		enemies.append(child_enemy)

	return enemies

## 加权随机生成敌人
## @param enemy_pool: 敌人数据池 [{data: EnemyData, weight: float}]
## @param parent: 父节点
## @param spawn_position: 生成位置
## @param target_y: 目标Y坐标
## @param move_speed: 移动速度
## @return: 生成的敌人实例数组（Array[Enemy]）
static func spawn_weighted(
	enemy_pool: Array,
	parent: Node,
	target_y: float = 880.0,
	move_speed: float = 200.0
) -> Array[Enemy]:
	if enemy_pool.is_empty():
		push_error("EnemySpawner: enemy_pool is empty!")
		return []

	# 计算总权重
	var total_weight: float = 0.0
	for entry in enemy_pool:
		total_weight += entry.get("weight", 1.0)

	# 随机选择
	var rand_value = randf() * total_weight
	var accumulated_weight: float = 0.0

	for entry in enemy_pool:
		var weight = entry.get("weight", 1.0)
		accumulated_weight += weight

		if rand_value <= accumulated_weight:
			var _enemy_data: EnemyData = entry.get("data")
			return spawn(_enemy_data, parent, target_y, move_speed)

	return []

## 简化的加权生成（使用数组和权重数组）
## @param enemy_datas: 敌人数据数组
## @param weights: 权重数组（与 enemy_datas 对应）
## @param parent: 父节点
## @param spawn_position: 生成位置
## @param target_y: 目标Y坐标
## @param move_speed: 移动速度
## @return: 生成的敌人实例数组（Array[Enemy]）
static func spawn_with_weights(
	enemy_datas: Array[EnemyData],
	weights: Array[float],
	parent: Node,
	target_y: float = 880.0,
	move_speed: float = 200.0
) -> Array[Enemy]:
	if enemy_datas.is_empty():
		push_error("EnemySpawner: enemy_datas is empty!")
		return []

	if enemy_datas.size() != weights.size():
		push_error("EnemySpawner: enemy_datas and weights size mismatch!")
		return []

	# 构建 pool
	var pool = []
	for i in range(enemy_datas.size()):
		pool.append({"data": enemy_datas[i], "weight": weights[i]})

	return spawn_weighted(pool, parent, target_y, move_speed)

## 从缓存获取场景
static func _get_cached_scene(scene_path: String) -> PackedScene:
	if _scene_cache.has(scene_path):
		return _scene_cache[scene_path]

	# 加载并缓存
	var scene = load(scene_path) as PackedScene
	if scene:
		_scene_cache[scene_path] = scene

	return scene

## 清空场景缓存（可选，用于内存管理）
static func clear_cache() -> void:
	_scene_cache.clear()

## 预加载场景到缓存
## @param scene_paths: 场景路径数组
static func preload_scenes(scene_paths: Array[String]) -> void:
	for path in scene_paths:
		_get_cached_scene(path)

## 从 EnemyData 数组预加载所有场景
static func preload_from_enemy_datas(enemy_datas: Array[EnemyData]) -> void:
	var paths: Array[String] = []
	for data in enemy_datas:
		if data:
			# 如果是组合敌人，预加载所有子敌人的场景
			if data is CompositeEnemyData:
				var composite = data as CompositeEnemyData
				for child_data in composite.child_enemy_datas:
					if child_data:
						paths.append(child_data.get_scene_path())
			else:
				paths.append(data.get_scene_path())
	preload_scenes(paths)
