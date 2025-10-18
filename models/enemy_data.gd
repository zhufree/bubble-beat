class_name EnemyData
extends Resource

## 敌人数据基类
## 定义所有敌人的基础属性和行为
##
## 设计理念:
## - 数据与视图分离
## - 通过继承实现多态
## - 每个数据类知道自己对应的场景路径

# ==================== 基础信息 ====================
@export var name: String = "单点"  # 敌人名称
@export var sprite: Texture2D  # 敌人精灵图
@export var description: String = "最基础的敌人，任何动物都可以轻松击败"  # 描述

# ==================== 战斗属性 ====================
@export var energy_damage: int = 2  # 对动物能量造成的伤害
@export var score_value: int = 1  # 击败后获得的分数
@export var health: float = 1.0  # 生命值

# ==================== 受伤类型 ====================
enum DamageType {
	TAP,   # 点击伤害
	HOLD,  # 长按伤害
}

@export var damage_type: DamageType = DamageType.TAP

# ==================== 虚函数 ====================

## 获取对应的场景路径 (虚函数)
## 子类应该重写此方法返回自己的场景路径
## @virtual
func get_scene_path() -> String:
	return "res://views/gameplay/enemy.tscn"

## 获取敌人的缩放因子 (虚函数)
## 子类可以重写以自定义大小
## @virtual
func get_scale_factor() -> float:
	# 特殊处理：巨大化敌人
	if name == "巨大化":
		return 1.5
	return 1.0
