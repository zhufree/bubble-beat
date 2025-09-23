extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Control = $MarginContainer/HBoxContainer/Tracks
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var combo_label: Label = $HBoxContainer/ComboLabel
@onready var chick: Control = $MarginContainer/HBoxContainer/LeftCharContainer/Chick
@onready var duck: Control = $MarginContainer/HBoxContainer/LeftCharContainer/Duck
@onready var parrot: Control = $MarginContainer/HBoxContainer/RightCharContainer/Parrot
@onready var hippo: Control = $MarginContainer/HBoxContainer/RightCharContainer/Hippo

var song: SongData
var combo = 0
var score = 0
var max_combo = 0

func _ready():
	# 使用Global中选中的歌曲，如果没有则使用默认歌曲
	Global.game_status = Enums.GameStatus.PLAYING
	if Global.selected_song:
		song = Global.selected_song
	else:
		song = preload("res://resources/song_data/waiting_for_love.tres")
	
	song_player.stream = song.stream
	song_player.play()
	
	# 连接信号
	EventBus.connect("update_hit", _on_update_hit)
	EventBus.connect("update_score", _on_update_score)
	song_player.finished.connect(_on_song_finished)

func _on_update_hit(character_name: String, hit_count: int):
	if character_name == "Chick":
		chick.update_hit(hit_count)
	elif character_name == "Duck":
		duck.update_hit(hit_count)
	elif character_name == "Parrot":
		parrot.update_hit(hit_count)
	elif character_name == "Hippo":
		hippo.update_hit(hit_count)

func _on_update_score(amount: int):
	score = score + amount
	if amount > 0:
		combo += 1
		# 更新最大连击数
		if combo > max_combo:
			max_combo = combo
	else:
		combo = 0
	score_label.text = "Score:" + str(score)
	combo_label.text = "Combo:" + str(combo)

func _on_song_finished():
	# 保存最终分数和最大连击数到Global
	Global.final_score = score
	Global.max_combo = max_combo
	Global.game_status = Enums.GameStatus.FINISHED
	# 发送游戏结束信号
	EventBus.game_finished.emit(score, max_combo)
