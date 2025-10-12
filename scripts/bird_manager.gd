extends Node

var game_save:GameSave
# 静态小鸟数据
var bird_data_list: Array[BirdData] = []

# 保存路径
const SAVE_DIR = "user://"
const DEFAULT_SAVE_PATH = "user://game_save.tres"
const BLUE_SKILL_BALL = preload("uid://c5wybo81hm8k4")
const GREEN_SKILL_BALL = preload("uid://blosftdxlxmx3")
const RED_SKILL_BALL = preload("uid://cpik2yklxgwxe")
const YELLOW_SKILL_BALL = preload("uid://2tswkxsrei5r")
const DEFAULT_BIRD_DATA = preload("uid://ruby001")

func _ready():
	_load_bird_data()
	# 注释掉自动重置功能 - 改用Ctrl+R手动重置
	# delete_save_file()

	load_game()
	print("BirdManager初始化完成，game_save: ", game_save)
	print(("小鸟数量: "+str(game_save.birds.size())) if game_save else "game_save为null")



# 加载所有小鸟静态数据
func _load_bird_data():
	var dir = DirAccess.open("res://resources/bird_data/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var bird = load("res://resources/bird_data/" + file_name)
				if bird:
					bird_data_list.append(bird)
					print("加载小鸟数据: ", bird.name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("总共加载了 ", bird_data_list.size(), " 个小鸟数据")
	else:
		print("无法打开小鸟数据目录")

# 获取小鸟静态数据
func get_bird_data(bird_name: String):
	for bird in bird_data_list:
		if bird.name == bird_name:
			return bird
	return null


# 增加小鸟
func add_bird(skill_balls:Array[SkillBall]) -> BirdSlot:
	var slot = BirdSlot.new()
	slot.skill_balls = skill_balls
	# 匹配技能球颜色和小鸟毛色
	var data = _match_skill_color(skill_balls)
	if data:
		slot.bird_data = data
	else:
		printerr("匹配技能球颜色出现错误，技能球颜色为：")
		for ball in skill_balls:
			print(ball.skill_color)
		slot.bird_data = DEFAULT_BIRD_DATA
	game_save.birds.append(slot)
	print("添加小鸟: ", slot.bird_data.name if slot.bird_data else "无数据")
	# 开启图鉴
	if data and !get_bird_atlas(data.name):
		set_bird_atlas(data.name)
	save_game()
	return slot

# 匹配技能球和BirdData
func _match_skill_color(skill_balls:Array[SkillBall]) -> BirdData:
	# 获取小鸟槽中所有不重复的技能颜色
	var slot_colors := []
	for skill_ball in skill_balls:
		var color = skill_ball.skill_color
		if not slot_colors.has(color):
			slot_colors.append(color)
	
	# 对颜色进行排序，确保匹配的一致性
	slot_colors.sort()
	print("小鸟技能槽中的颜色："+str(slot_colors))
	
	# 在bird_data_list中寻找匹配的BirdData
	for bird_data in bird_data_list:
		var data_colors = bird_data.skill_color.duplicate()
		data_colors.sort()
		print("正在寻找一致的技能槽："+str(data_colors))
		# 如果颜色组合完全匹配，则返回该BirdData
		if slot_colors == data_colors:
			print("找到匹配的小鸟数据: ", bird_data.name)
			return bird_data
	
	# 如果没有找到完全匹配，返回null或默认值
	print("未找到匹配的小鸟数据，返回默认值")
	return null


## 保存存档，返回是否保存成功
func save_game() -> bool:
	# 记录时间
	game_save.save_date = Time.get_datetime_string_from_system()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	return ResourceSaver.save(game_save, DEFAULT_SAVE_PATH) == OK

## 加载存档
func load_game():
	if FileAccess.file_exists(DEFAULT_SAVE_PATH):
		game_save = ResourceLoader.load(DEFAULT_SAVE_PATH)
		print("加载存档成功，小鸟数量: ", game_save.birds.size())
	else:#无存档时
		print("无存档文件，创建新存档")
		delete_save_file()

# 删除存档（重置所有槽）
func delete_save_file():
	# 删除存档文件
	if FileAccess.file_exists(DEFAULT_SAVE_PATH):
		DirAccess.remove_absolute(DEFAULT_SAVE_PATH)
	
	# 重置内存中的槽数据
	game_save = GameSave.new()
	
	# 重新初始化所有小鸟的槽
	add_bird([BLUE_SKILL_BALL])
	add_bird([RED_SKILL_BALL])
	add_bird([YELLOW_SKILL_BALL])
	add_bird([GREEN_SKILL_BALL])
	
	print("存档已删除，槽已重置，小鸟数量: ", game_save.birds.size())

func get_bird_atlas(bird_name:String):
	if game_save.atlas.has(bird_name):
		return game_save.atlas[bird_name]
	else:
		return false

func set_bird_atlas(bird_name:String):
	game_save.atlas[bird_name] = true
