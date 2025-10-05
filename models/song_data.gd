extends Resource

class_name SongData

@export var name: String
@export var stream: AudioStream
@export var BPM: int
@export var give_bird: String = "" # 完成后赠送的小鸟
@export var colors = [Enums.BubbleColor.RED, Enums.BubbleColor.BLUE, Enums.BubbleColor.GREEN, Enums.BubbleColor.YELLOW]
