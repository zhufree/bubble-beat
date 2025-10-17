class_name AnimalData
extends Resource

enum AnimalType{
	MEDIUM,
	HEAVY,
	AGILE,
}

# 基础信息
@export var name: String = "猫头鹰"
@export var icon: Texture2D
@export var bust: Texture2D
@export_multiline var description: String = "你的动物伙伴"
@export var animal_type: AnimalType = AnimalType.MEDIUM
@export var energy_color: Color = Color(1.0, 0.8, 0.2, 1.0)  # 能量条颜色

# 攻击属性
@export var attack_cooldown: float = 0.5  # 攻击频率（秒）
@export var attack_recovery_time: float = 1.2 # 攻击次数恢复时间（秒）
@export var max_attack_count: int = 7  # 攻击次数上限
@export var skill_energy_required: int = 7  # 释放技能所需能量
@export var single_attack_damage: float = 1.0 # 单次攻击最大伤害
@export var max_hold_time: float = 15.0 #最大长按时间（秒）
