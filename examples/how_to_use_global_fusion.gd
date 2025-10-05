# 示例：如何在任何脚本中使用全局合成数据

extends Control

func _ready():
	# 直接访问全局单例
	print("当前拥有的角色：", GlobalFusionData.get_all_owned_characters())
	
	# 连接全局信号
	GlobalFusionData.character_unlocked.connect(_on_character_unlocked)
	GlobalFusionData.fusion_completed.connect(_on_fusion_completed)
	
	# 检查是否可以合成
	if GlobalFusionData.can_fuse("Parrot", "Chick"):
		print("可以合成 Parrot + Chick")
	
	# 尝试合成
	var result = GlobalFusionData.attempt_fusion("Parrot", "Chick")
	if result.success:
		print("合成成功：", result.result)
	else:
		print("合成失败：", result.error)

func _on_character_unlocked(character_name: String):
	print("解锁了新角色：", character_name)

func _on_fusion_completed(result_character: String):
	print("合成完成：", result_character)

# 在按钮点击时添加角色
func _on_add_character_button_pressed():
	GlobalFusionData.add_character("Phoenix", 1)

# 获取角色信息
func _on_info_button_pressed():
	var info = GlobalFusionData.get_character_info("Phoenix")
	print("Phoenix信息：", info)