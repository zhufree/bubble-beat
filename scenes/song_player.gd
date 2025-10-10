extends AudioStreamPlayer2D


var start = false
var first_time = true
var bpm = 0.0
var sec_per_beat = 0.0

var song_pos = 0.0
var song_pos_in_beats = 0.0

var beats_before_start = 8.0

var last_pos = 0.0
var output_latency = AudioServer.get_output_latency()
var last_emitted_beat = -999  # Track the last integer beat that was emitted


func _ready():
	if bpm > 0:
		sec_per_beat = 60.0 / bpm

func _physics_process(delta):
# 模拟播放开始
	if start:
		if playing:
			#播放开始后
			song_pos = get_playback_position() + AudioServer.get_time_since_last_mix()
			song_pos -= (output_latency/ 1000.0)
			song_pos_in_beats += (song_pos - last_pos) / sec_per_beat
			last_pos = song_pos
		else:
			#播放开始前
			song_pos_in_beats += delta / sec_per_beat
			if song_pos_in_beats >= 0 and first_time:
				first_time = false
				play()
		_report_beat()
		

func _report_beat():
	var current_integer_beat = int(song_pos_in_beats)
	if current_integer_beat > last_emitted_beat:
		EventBus.pat.emit(current_integer_beat)
		last_emitted_beat = current_integer_beat


func play_with_beat_offset(num):
	beats_before_start = float(num)
	song_pos_in_beats = -beats_before_start
	last_emitted_beat = -999
	if bpm > 0:
		sec_per_beat = 60.0 / bpm
	start = true


func _on_finished() -> void:
	start = false
	last_emitted_beat = -999
