extends Node
var difficulty: float = 2.0
var selected_song: SongData
var max_combo: int = 0
var final_score: int = 0
var game_status = Enums.GameStatus.NOTSTARTED
var selected_birds: Array[BirdSlot] = []
