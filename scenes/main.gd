extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Control = $MarginContainer/HBoxContainer/Tracks
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var combo_label: Label = $HBoxContainer/ComboLabel
@onready var left_up: Control = $MarginContainer/HBoxContainer/LeftCharContainer/LeftUp
@onready var left_down: Control = $MarginContainer/HBoxContainer/LeftCharContainer/LeftDown
@onready var right_up: Control = $MarginContainer/HBoxContainer/RightCharContainer/RightUp
@onready var right_down: Control = $MarginContainer/HBoxContainer/RightCharContainer/RightDown
@export var bird_entities: Array[BirdEntity]
var song: SongData

func _ready():
	_init_bird_entities()
	EventBus.emit_signal("update_judgement_rules")

	# 使用Global中选中的歌曲，如果没有则使用默认歌曲
	Global.game_status = Enums.GameStatus.PLAYING
	if Global.selected_song:
		song = Global.selected_song
	else:
		song = preload("res://resources/song_data/waiting_for_love.tres")
	
	song_player.stream = song.stream
	song_player.bpm = song.BPM
	song_player.play_with_beat_offset(8)
	# 连接信号
	EventBus.connect("update_hit", _on_update_hit)
	EventBus.connect("score_updated", _on_score_updated)
	EventBus.connect("combo_updated", _on_combo_updated)
	song_player.finished.connect(_on_song_finished)

func _init_bird_entities():
	# 假设Global.selected_birds已经包含了选中的鸟类数据
	for i in range(bird_entities.size()):
		if i < Global.selected_birds.size():
			bird_entities[i].setup_bird_slot(Global.selected_birds[i])
			bird_entities[i].visible = true
		else:
			bird_entities[i].visible = false

func _on_update_hit(bird_index: int, hit_count: int):
	if bird_index >= 0 and bird_index < bird_entities.size():
		bird_entities[bird_index].update_hit(hit_count)


# 分数更新信号处理
func _on_score_updated(new_score: int):
	score_label.text = "Score:" + str(new_score)

# 连击更新信号处理
func _on_combo_updated(new_combo: int):
	combo_label.text = "Combo:" + str(new_combo)

func _on_song_finished():
	Global.game_status = Enums.GameStatus.FINISHED
