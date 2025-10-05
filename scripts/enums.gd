extends Node
class_name Enums

enum BubbleColor {DEFAULT, BLUE, GREEN, RED, YELLOW}
enum GameStatus {NOTSTARTED, PLAYING, PAUSED, FINISHED}
enum BirdType {CHICK, FLEDGLING, FLYER, PHOENIX}
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
		_:
			return "res://assets/sprites/bubbles/default.png"

static func get_bubble_color_icon_sprite(color: BubbleColor) -> Texture2D:
	return load(bubble_color_icon_sprite(color)) as Texture2D
