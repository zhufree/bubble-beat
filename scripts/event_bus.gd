extends Node

# 定义信号
@warning_ignore_start("unused_signal")
signal update_hit(bird_index: int, hit_count: int)
signal score_updated(new_score: int)
signal combo_updated(new_combo: int)
signal game_finished(final_score: int, max_combo: int)
signal show_character_border(character: BirdSlot)
signal update_guide_text(type: int)
signal update_judgement_rules()
signal pat(pos:int)
@warning_ignore_restore("unused_signal")
