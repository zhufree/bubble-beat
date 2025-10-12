extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Control = $MarginContainer/HBoxContainer/Tracks
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var combo_label: Label = $HBoxContainer/ComboLabel
@onready var left_up: Control = $MarginContainer/HBoxContainer/LeftCharContainer/LeftUp
@onready var left_down: Control = $MarginContainer/HBoxContainer/LeftCharContainer/LeftDown
@onready var right_up: Control = $MarginContainer/HBoxContainer/RightCharContainer/RightUp
@onready var right_down: Control = $MarginContainer/HBoxContainer/RightCharContainer/RightDown
@onready var health_progress_bar: TextureProgressBar = $HBoxContainer/Health/HealthProgressBar
@onready var shield_progress_bar: TextureProgressBar = $HBoxContainer/Shield/ShieldProgressBar
@onready var game_pause_modal: Control = $UI/GamePauseModal
@export var bird_entities: Array[BirdEntity]
var song: SongData

func _ready():
	# 添加组标签以便其他节点可以找到主场景
	add_to_group("main_scene")

	# 初始化游戏状态（重置护盾、分数、连击、生命值）
	Global.initialize_game()

	_init_bird_entities()
	EventBus.emit_signal("update_judgement_rules")

	# 初始化生命值和护盾UI
	if health_progress_bar:
		health_progress_bar.max_value = Global.max_health
		health_progress_bar.value = Global.health
	if shield_progress_bar:
		shield_progress_bar.max_value = int(Global.max_shields)
		shield_progress_bar.value = int(Global.shields)

	# 初始化分数和连击标签
	score_label.text = "Score:" + str(Global.score)
	combo_label.text = "Combo:" + str(Global.combo)

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
	EventBus.connect("health_updated", _on_health_updated)
	EventBus.connect("shield_updated", _on_shield_updated)
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

# 生命值更新信号处理
func _on_health_updated(current_health: int, max_health: int):
	if health_progress_bar:
		health_progress_bar.max_value = max_health
		health_progress_bar.value = current_health

# 护盾更新信号处理
func _on_shield_updated(current_shields: int, max_shields: int):
	if shield_progress_bar:
		shield_progress_bar.max_value = max_shields
		shield_progress_bar.value = current_shields

func _on_song_finished():
	# 歌曲结束时立即设置游戏状态为FINISHED，停止生成新气泡
	Global.game_status = Enums.GameStatus.FINISHED
	print("歌曲结束，停止生成新气泡，等待5秒后显示结果")

	# 等待5秒让玩家处理剩余气泡
	await get_tree().create_timer(5.0).timeout

	# 调用游戏结束逻辑
	Global.game_over("song")

# 输入处理
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC键
		toggle_pause()

# 暂停/恢复游戏
func toggle_pause():
	if Global.game_status == Enums.GameStatus.PLAYING:
		pause_game()
	elif Global.game_status == Enums.GameStatus.PAUSED:
		resume_game()

# 暂停游戏
func pause_game():
	Global.game_status = Enums.GameStatus.PAUSED
	get_tree().paused = true
	if game_pause_modal:
		game_pause_modal.visible = true
	# 暂停音乐
	if song_player and song_player.playing:
		song_player.stream_paused = true

# 恢复游戏
func resume_game():
	Global.game_status = Enums.GameStatus.PLAYING
	get_tree().paused = false
	if game_pause_modal:
		game_pause_modal.visible = false
	# 恢复音乐
	if song_player:
		song_player.stream_paused = false
