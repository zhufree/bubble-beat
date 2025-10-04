extends Resource

class_name BirdProgress

# 角色ID（对应birdData的name或唯一标识）
@export var bird_id: String
# 是否解锁
@export var is_unlocked: bool = false
# 拥有数量
@export var count: int = 0

# 解锁角色
func unlock_bird() -> void:
	is_unlocked = true
	count = 1

# 增加数量
func add_count(amount: int = 1) -> void:
	count += amount
	if count > 0:
		is_unlocked = true

# 获取解锁状态文本
func get_unlock_status_text() -> String:
	if not is_unlocked:
		return "未解锁"
	else:
		return "已解锁 x" + str(count)