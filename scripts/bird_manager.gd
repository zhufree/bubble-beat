extends Node

# 静态小鸟数据
var bird_data_list: Array = []
# 动态小鸟进度 (Dictionary[String, BirdProgress])
var bird_progress_dict: Dictionary = {}

# 保存路径
const PROGRESS_SAVE_PATH = "user://bird_progress.save"

func _ready():
	load_bird_data()
	load_bird_progress()

# 加载所有小鸟静态数据
func load_bird_data():
	var dir = DirAccess.open("res://resources/bird_data/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var bird = load("res://resources/bird_data/" + file_name)
				if bird:
					bird_data_list.append(bird)
					# 确保每个小鸟都有对应的进度数据
					if not bird_progress_dict.has(bird.name):
						var progress = preload("res://models/bird_progress.gd").new()
						progress.bird_id = bird.name
						bird_progress_dict[bird.name] = progress
			file_name = dir.get_next()
		
		dir.list_dir_end()

# 获取小鸟静态数据
func get_bird_data(bird_name: String):
	for bird in bird_data_list:
		if bird.name == bird_name:
			return bird
	return null

# 获取小鸟进度数据
func get_bird_progress(bird_name: String):
	return bird_progress_dict.get(bird_name, null)

# 解锁小鸟
func unlock_bird(bird_name: String) -> bool:
	var progress = get_bird_progress(bird_name)
	if progress and not progress.is_unlocked:
		progress.unlock_bird()
		save_bird_progress()
		return true
	return false

# 增加小鸟数量
func add_bird_count(bird_name: String, amount: int = 1) -> void:
	var progress = get_bird_progress(bird_name)
	if progress:
		progress.add_count(amount)
		save_bird_progress()

# 获取所有已解锁的小鸟
func get_unlocked_birds() -> Array:
	var unlocked = []
	for bird in bird_data_list:
		var progress = get_bird_progress(bird.name)
		if progress and progress.is_unlocked:
			unlocked.append(bird)
	return unlocked

# 获取所有小鸟（包含进度信息）
func get_all_birds_with_progress() -> Array:
	var result: Array[Dictionary] = []
	for bird in bird_data_list:
		var progress = get_bird_progress(bird.name)
		result.append({
			"data": bird,
			"progress": progress
		})
	return result

# 保存小鸟进度
func save_bird_progress():
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_data = {}
		for bird_name in bird_progress_dict:
			var progress = bird_progress_dict[bird_name]
			save_data[bird_name] = {
				"is_unlocked": progress.is_unlocked,
				"count": progress.count
			}
		file.store_string(JSON.stringify(save_data))
		file.close()

# 加载小鸟进度
func load_bird_progress():
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			for bird_name in save_data:
				var progress_data = save_data[bird_name]
				var progress = preload("res://models/bird_progress.gd").new()
				progress.bird_id = bird_name
				progress.is_unlocked = progress_data.get("is_unlocked", false)
				progress.count = progress_data.get("count", 0)
				bird_progress_dict[bird_name] = progress
