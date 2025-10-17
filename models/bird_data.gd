extends Resource

class_name BirdData

@export var name: String
@export var bubble_color: Enums.BubbleColor
@export var skill_color: Array[Enums.SkillColor]
@export var gradient:Gradient
@export var icon: Texture2D
@export_multiline var description: String
@export var bird_type: Enums.BirdType = Enums.BirdType.CHICK
var default_icon_path = "res://assets/sprites/birds/green.png"

# 获取图标纹理资源
func get_icon_texture() -> Texture2D:
	if icon is Texture2D:
		return icon
	else:
		return load(default_icon_path)

# 获取星星颜色
func get_bubble_color() -> Enums.BubbleColor:
	if !bubble_color:
		return bubble_color
	return Enums.BubbleColor.DEFAULT
