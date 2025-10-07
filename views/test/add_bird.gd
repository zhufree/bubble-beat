extends Button
@export var skill_ball:Array[Colors]
enum Colors {BLUE,GREEN,RED,YELLOW}
var balls = [BirdManager.BLUE_SKILL_BALL,
	BirdManager.GREEN_SKILL_BALL,
	BirdManager.RED_SKILL_BALL,
	BirdManager.YELLOW_SKILL_BALL
	]

func _on_pressed() -> void:
	var ball_list:Array[SkillBall] = []
	for index in skill_ball:
		ball_list.append(balls[index])
	BirdManager.add_bird(ball_list)
