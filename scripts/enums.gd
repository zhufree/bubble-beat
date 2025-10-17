extends Node
class_name Enums

enum BubbleColor {
	BLUE, GREEN, RED, YELLOW,
	REDYELLOW, REDGREEN, REDBLUE, YELLOWGREEN, YELLOWBLUE, BLUEGREEN,
	YELLOWGREENBLUE, REDGREENBLUE, REDYELLOWBLUE, REDYELLOWGREEN,
	RAINBOW, DEFAULT
}
enum SkillColor {BLUE, GREEN, RED, YELLOW}
enum GameStatus {NOTSTARTED, PLAYING, PAUSED, FINISHED}
enum BirdType {CHICK, FLEDGLING, FLYER, PHOENIX}
enum PressKeyCode {DEFAULT, KEY_E, KEY_D, KEY_O, KEY_K}

# 技能类型枚举
enum SkillType {
	FREE_ATTACK,       # 免费攻击（不消耗攻击次数）
	DAMAGE_TO_BOSS,    # 积分转化为BOSS伤害
	SCORE_MULTIPLIER,  # 分数倍率提升
	SHIELD,            # 护盾（防止敌人到达后排时扣血）
}


static func bubble_color_icon_sprite(color: BubbleColor) -> String:
	match color:
		BubbleColor.BLUE:
			return "res://assets/sprites/bubbles/blue.png"
		BubbleColor.GREEN:
			return "res://assets/sprites/bubbles/green.png"
		BubbleColor.RED:
			return "res://assets/sprites/bubbles/red.png"
		BubbleColor.YELLOW:
			return "res://assets/sprites/bubbles/yellow.png"
		BubbleColor.REDYELLOW:
			return "res://assets/sprites/bubbles/red_yellow.png"
		BubbleColor.REDGREEN:
			return "res://assets/sprites/bubbles/red_green.png"
		BubbleColor.REDBLUE:
			return "res://assets/sprites/bubbles/red_blue.png"
		BubbleColor.YELLOWGREEN:
			return "res://assets/sprites/bubbles/yellow_green.png"
		BubbleColor.YELLOWBLUE:
			return "res://assets/sprites/bubbles/yellow_blue.png"
		BubbleColor.BLUEGREEN:
			return "res://assets/sprites/bubbles/blue_green.png"
		BubbleColor.YELLOWGREENBLUE:
			return "res://assets/sprites/bubbles/yellow_green_blue.png"
		BubbleColor.REDGREENBLUE:
			return "res://assets/sprites/bubbles/red_green_blue.png"
		BubbleColor.REDYELLOWBLUE:
			return "res://assets/sprites/bubbles/red_yellow_blue.png"
		BubbleColor.REDYELLOWGREEN:
			return "res://assets/sprites/bubbles/red_yellow_green.png"
		BubbleColor.RAINBOW:
			return "res://assets/sprites/bubbles/rainbow.png"
		_:
			return "res://assets/sprites/bubbles/default.png"


static func get_bubble_color_icon_sprite(color:int) -> Texture2D:
	return load(bubble_color_icon_sprite(color)) as Texture2D


static func press_key_code_to_string(key: PressKeyCode) -> String:
	match key:
		PressKeyCode.KEY_E:
			return "E"
		PressKeyCode.KEY_D:
			return "D"
		PressKeyCode.KEY_O:
			return "O"
		PressKeyCode.KEY_K:
			return "K"
		_:
			return "None"
