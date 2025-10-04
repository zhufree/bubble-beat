extends Resource

class_name BirdData

@export var name: String
@export var colors: Array[Enums.BubbleColor] = []
@export var icon_path: String
@export var description: String
@export var bird_type: Enums.BirdType = Enums.BirdType.CHICK
@export var needFusion: bool = false # 是否需要合成解锁
@export var unlockNeedBirds: Array[String] = [] # 解锁所需的小鸟（默认空，表示无要求）


# 获取图标纹理资源
func get_icon_texture() -> Texture2D:
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D

# 检查是否包含指定颜色
func has_color(color: Enums.BubbleColor) -> bool:
	return color in colors

# 获取指定颜色
func get_color(index: int) -> Enums.BubbleColor:
	if index >= 0 and index < colors.size():
		return colors[index]
	return Enums.BubbleColor.DEFAULT

# 获取主要颜色（第一个颜色）
func get_primary_color() -> Enums.BubbleColor:
	return get_color(0)

# 获取颜色数量
func get_color_count() -> int:
	return colors.size()
