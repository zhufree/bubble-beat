extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Control = $MarginContainer/HBoxContainer/Tracks
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var combo_label: Label = $HBoxContainer/ComboLabel
@onready var chick: Control = $MarginContainer/HBoxContainer/LeftCharContainer/Chick
@onready var duck: Control = $MarginContainer/HBoxContainer/LeftCharContainer/Duck
@onready var parrot: Control = $MarginContainer/HBoxContainer/RightCharContainer/Parrot
@onready var hippo: Control = $MarginContainer/HBoxContainer/RightCharContainer/Hippo
@export var bird_entities: Array[BirdEntity]
var song: SongData
var combo = 0
var score = 0
var max_combo = 0

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
	song_player.play()
	# 连接信号
	EventBus.connect("update_hit", _on_update_hit)
	EventBus.connect("update_score", _on_update_score)
	song_player.finished.connect(_on_song_finished)

func _init_bird_entities():
	# 假设Global.selected_birds已经包含了选中的鸟类数据
	for i in range(bird_entities.size()):
		if i < Global.selected_birds.size():
			bird_entities[i].setup_bird_data(Global.selected_birds[i])
			bird_entities[i].visible = true
		else:
			bird_entities[i].visible = false

func _on_update_hit(character_name: String, hit_count: int):
	var entity = get_bird_entity_by_name(character_name)
	if entity:
		entity.update_hit(hit_count)
	# if character_name == "Chick":
	# 	chick.update_hit(hit_count)
	# elif character_name == "Duck":
	# 	duck.update_hit(hit_count)
	# elif character_name == "Parrot":
	# 	parrot.update_hit(hit_count)
	# elif character_name == "Hippo":
	# 	hippo.update_hit(hit_count)

func get_bird_entity_by_name(name: String) -> BirdEntity:
	for bird in bird_entities:
		if bird.bird_data and bird.bird_data.name == name:
			return bird
	return null

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
	Global.final_score = score
	Global.max_combo = max_combo
	Global.game_status = Enums.GameStatus.FINISHED
	EventBus.game_finished.emit(score, max_combo)
