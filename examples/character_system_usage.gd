# 角色系统使用示例

extends Control

func _ready():
	# 等待CharacterManager初始化完成
	await get_tree().process_frame
	
	# 示例：解锁一个角色
	unlock_character_example()
	
	# 示例：显示图鉴界面
	display_character_gallery()

# 解锁角色示例
func unlock_character_example():
	# 通过特定条件解锁角色（比如完成某首歌曲）
	var success = CharacterManager.unlock_character("小鸡")
	if success:
		print("恭喜！解锁了新角色：小鸡")
		# 可以触发解锁动画或提示
	
	# 增加角色数量示例
	CharacterManager.add_character_count("小鸡", 2) # 增加2个

# 显示图鉴界面示例
func display_character_gallery():
	var all_characters = CharacterManager.get_all_characters_with_progress()
	
	print("=== 角色图鉴 ===")
	for char_info in all_characters:
		var character_data = char_info["data"]
		var progress = char_info["progress"]
		
		print("角色名：", character_data.name)
		print("状态：", progress.get_unlock_status_text())
		print("颜色数量：", character_data.get_color_count())
		print("描述：", character_data.description if progress.is_unlocked else "???")
		print("---")

# 角色查看示例
func view_character(character_name: String):
	var character_data = CharacterManager.get_character_data(character_name)
	var progress = CharacterManager.get_character_progress(character_name)
	
	if not progress.is_unlocked:
		print("此角色尚未解锁")
		return
	
	# 显示角色详细信息
	print("查看角色：", character_data.name)
	print("拥有数量：", progress.count)
	print("描述：", character_data.description)
	var icon = character_data.get_icon_texture()
	if icon:
		print("显示角色图标")