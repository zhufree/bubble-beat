extends Panel
class_name AnimalCard

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animal_label: Label = $Sprite2D/animalLabel
@onready var count_label: Label = $Sprite2D/Label2
@onready var info_label: Label = $Sprite2D/Label

# 动物数据
var animal_data: AnimalData
var owned_count: int = 1
var max_count: int = 3
var is_locked: bool = false

func _ready():
	pass

# 设置动物数据
func set_animal_data(data: AnimalData, count: int = 0) -> void:
	animal_data = data
	owned_count = count
	is_locked = false
	update_display()

# 设置为未解锁状态
func set_locked() -> void:
	is_locked = true
	animal_data = null
	update_display()

# 更新显示
func update_display() -> void:
	if is_locked:
		# 显示未解锁状态
		if animal_label:
			animal_label.text = "???"
		if sprite:
			sprite.texture = null
		if count_label:
			count_label.visible = false
		if info_label:
			info_label.visible = false
		return

	if not animal_data:
		return

	# 显示拥有数量标签
	if count_label:
		count_label.visible = true

	# 显示信息标签
	if info_label:
		info_label.visible = true

	# 设置动物图标
	if sprite and animal_data.icon:
		sprite.texture = animal_data.icon

	# 设置动物名称
	if animal_label:
		animal_label.text = animal_data.name

	# 设置拥有数量
	if count_label:
		count_label.text = "拥有数量%d/%d" % [owned_count, max_count]

	# 设置详细信息
	if info_label:
		var attack_type_text = get_attack_type_text(animal_data.animal_type)
		var skill_name = animal_data.skill.skill_name if animal_data.skill else "无"

		info_label.text = """攻击方式：%s
攻击频率：%.1f秒
连击上限：%d
特殊技能：%s
特殊技能消耗能量：%d""" % [
			attack_type_text,
			animal_data.attack_cooldown,
			animal_data.max_attack_count,
			skill_name,
			animal_data.skill_energy_required
		]

# 获取攻击方式文本
func get_attack_type_text(type: AnimalData.AnimalType) -> String:
	match type:
		AnimalData.AnimalType.MEDIUM:
			return "中型（单体）"
		AnimalData.AnimalType.HEAVY:
			return "重型（范围）"
		AnimalData.AnimalType.AGILE:
			return "敏捷（快速）"
	return "未知"
