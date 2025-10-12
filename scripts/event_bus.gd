extends Node

# 定义信号
@warning_ignore_start("unused_signal")
signal update_hit(bird_index: int, hit_count: int)
signal score_updated(new_score: int)
signal combo_updated(new_combo: int)
signal health_updated(current_health: int, max_health: int)
signal shield_updated(current_shields: int, max_shields: int)
signal game_finished()
signal game_over_by_health()  # 生命值为0导致的游戏结束
signal song_finished()  # 歌曲播放完毕
signal show_character_border(character: BirdSlot)
signal update_guide_text(type: int)
signal update_judgement_rules()
signal pat(pos:int)
@warning_ignore_restore("unused_signal")
