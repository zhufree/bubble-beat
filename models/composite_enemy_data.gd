class_name CompositeEnemyData
extends EnemyData

## 组合敌人数据
## 用于定义由多个子敌人组成的敌人类型
##
## 特性:
## - 子敌人独立移动和战斗
## - 支持多种阵型排列
## - 每个子敌人独立计分

# 阵型类型
enum FormationType {
	VERTICAL,    # 垂直排列
	HORIZONTAL,  # 水平排列
	TRIANGLE,    # 三角阵型
	CIRCLE,      # 圆形阵型
}

# 子敌人数据列表
@export var child_enemy_datas: Array[EnemyData] = []

# 阵型设置
@export var formation_type: FormationType = FormationType.VERTICAL
@export var formation_spacing: float = 50.0  # 子敌人之间的间距

func _init() -> void:
	# 组合敌人本身不参与战斗，所有属性由子敌人决定
	health = 0.0
	score_value = 0
	energy_damage = 0

## 返回组合敌人的场景路径
func get_scene_path() -> String:
	return "res://views/gameplay/composite_enemy.tscn"

## 计算子敌人的总分数
func get_total_score() -> int:
	var total = 0
	for child_data in child_enemy_datas:
		total += child_data.score_value
	return total

## 计算子敌人的总伤害
func get_total_damage() -> int:
	var total = 0
	for child_data in child_enemy_datas:
		total += child_data.energy_damage
	return total

## 获取阵型中子敌人的位置偏移列表
func get_formation_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var count = child_enemy_datas.size()

	match formation_type:
		FormationType.VERTICAL:
			# 垂直排列：居中对齐
			var start_offset = -(count - 1) * formation_spacing / 2.0
			for i in range(count):
				offsets.append(Vector2(0, start_offset + i * formation_spacing))

		FormationType.HORIZONTAL:
			# 水平排列：居中对齐
			var start_offset = -(count - 1) * formation_spacing / 2.0
			for i in range(count):
				offsets.append(Vector2(start_offset + i * formation_spacing, 0))

		FormationType.TRIANGLE:
			# 三角阵型：适合3个敌人
			if count == 3:
				offsets.append(Vector2(0, -formation_spacing))  # 顶点
				offsets.append(Vector2(-formation_spacing * 0.6, formation_spacing * 0.5))  # 左下
				offsets.append(Vector2(formation_spacing * 0.6, formation_spacing * 0.5))   # 右下
			else:
				# 默认使用垂直排列
				var start_offset = -(count - 1) * formation_spacing / 2.0
				for i in range(count):
					offsets.append(Vector2(0, start_offset + i * formation_spacing))

		FormationType.CIRCLE:
			# 圆形阵型
			var radius = formation_spacing
			var angle_step = TAU / count
			for i in range(count):
				var angle = i * angle_step
				offsets.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	return offsets
