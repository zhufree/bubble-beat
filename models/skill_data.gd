class_name SkillData
extends Resource

# 基础信息
@export var skill_name: String = "技能名称"
@export var skill_icon: Texture2D
@export_multiline var description: String = "技能描述"

# 技能类型 - 使用枚举明确定义技能效果
@export var skill_type: Enums.SkillType = Enums.SkillType.FREE_ATTACK
@export var duration: float = 5.0  # 技能持续时间（秒）

# 视觉效果
@export_group("Visual & Audio")
@export var effect_color: Color = Color(1.0, 1.0, 0.0, 1.0)  # 技能效果颜色
@export var particle_effect: PackedScene  # 粒子效果场景

# 音效
@export var activation_sound: AudioStream  # 激活音效
@export var effect_sound: AudioStream  # 持续效果音效
