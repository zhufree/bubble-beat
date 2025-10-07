extends Node

# 定义信号
@warning_ignore_start("unused_signal")
signal update_hit(character_name: String, hit_count: int)
signal update_score(amount: int)
signal game_finished(final_score: int, max_combo: int)
signal show_character_border(character_name: String)
signal update_guide_text(type: int)
signal update_judgement_rules()
@warning_ignore_restore("unused_signal")
