extends Node
class_name Enums

enum BubbleColor {DEFAULT, BLUE, GREEN, RED, YELLOW, PURPLE, BLACK, WHITE}
enum GameStatus {NOTSTARTED, PLAYING, PAUSED, FINISHED}
enum BirdType {CHICK, FLEDGLING, FLYER, PHOENIX}
enum PressKeyCode {DEFAULT, KEY_E, KEY_D, KEY_O, KEY_K}
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
		BubbleColor.PURPLE:
			return "res://assets/sprites/bubbles/purple.png"
		BubbleColor.BLACK:
			return "res://assets/sprites/bubbles/black.png"
		_:
			return "res://assets/sprites/bubbles/default.png"

static func get_bubble_color_icon_sprite(color: BubbleColor) -> Texture2D:
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
