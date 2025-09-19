extends Control

@onready var song_player: AudioStreamPlayer2D = $SongPlayer
@onready var tracks: Node2D = $MarginContainer/HBoxContainer/TrackContainer/Tracks
@onready var track_container: VBoxContainer = $MarginContainer/HBoxContainer/TrackContainer

var song = preload("res://resources/song_data/waiting_for_love.tres")

func _ready():
	song_player.stream = song.stream
	song_player.play()
	get_tree().root.connect("size_changed", _on_resized)
	_on_resized()

func _on_resized():
	tracks.update_area_size(track_container.size.x)
