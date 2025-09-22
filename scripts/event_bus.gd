extends Node

# 定义信号
signal update_hit(character_name: String, hit_count: int)
signal update_score(amount: int)
signal game_finished(final_score: int, max_combo: int)
