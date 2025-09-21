extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Control = $MarginContainer/HBoxContainer/Tracks
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var combo_label: Label = $HBoxContainer/ComboLabel
@onready var chick: VBoxContainer = $MarginContainer/HBoxContainer/LeftCharContainer/Chick
@onready var duck: VBoxContainer = $MarginContainer/HBoxContainer/LeftCharContainer/Duck
@onready var parrot: VBoxContainer = $MarginContainer/HBoxContainer/RightCharContainer/Parrot
@onready var hippo: VBoxContainer = $MarginContainer/HBoxContainer/RightCharContainer/Hippo

var song = preload("res://resources/song_data/waiting_for_love.tres")
var combo = 0
var score = 0
func _ready():
	song_player.stream = song.stream
	song_player.play()
	EventBus.connect("update_hit", _on_update_hit)
	EventBus.connect("update_score", _on_update_score)

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
	else:
		combo = 0
	score_label.text = "Score:" + str(score)
	combo_label.text = "Combo:" + str(combo)
