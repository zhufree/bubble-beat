extends Resource

class_name BirdSlot

# 小鸟类别信息
@export var bird_data:BirdData
# 昵称（用户给起的名字）
@export var nickname:String
# 技能球
@export var skill_balls: Array[SkillBall]

func get_bird_name() -> String:
	if nickname:
		return nickname
	else:
		return bird_data.name
