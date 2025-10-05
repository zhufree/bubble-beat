class_name CharacterFusionRules extends Resource

# 合成规则数据结构

@export var tier: int
@export var required_materials: Array[String] # 需要的角色名称
@export var required_colors: Array[Enums.BubbleColor] # 需要的颜色
@export var result_character: String
@export var result_colors: Array[Enums.BubbleColor]
@export var unlock_condition: String # 解锁条件
@export var cost: Dictionary # 合成消耗（经验、金币等）

# 合成梯度系统
static func get_fusion_tier_rules() -> Dictionary:
	return {
		# Tier 1: 基础单色（游戏开始就拥有）
		1: {
			"max_colors": 1,
			"materials_needed": 0,
			"unlock_condition": "default"
		},
		
		# Tier 2: 双色合成
		2: {
			"max_colors": 2,
			"materials_needed": 2, # 需要2个Tier1角色
			"unlock_condition": "complete_5_songs",
			"fusion_rules": [
				# 相邻色合成（色轮理论）
				{
					"materials": ["Parrot", "Chick"], # 红+黄
					"result": "Phoenix",
					"result_color": "ORANGE",
					"description": "火焰之鸟，擅长连击加成"
				},
				{
					"materials": ["Chick", "Duck"], # 黄+绿
					"result": "Canary",
					"result_color": "LIME",
					"description": "敏捷小鸟，扩大判定窗口"
				},
				{
					"materials": ["Duck", "Hippo"], # 绿+蓝
					"result": "Peacock",
					"result_color": "CYAN",
					"description": "优雅孔雀，提供护盾保护"
				},
				{
					"materials": ["Hippo", "Parrot"], # 蓝+红
					"result": "Eagle",
					"result_color": "PURPLE",
					"description": "威猛老鹰，多重击打"
				}
			]
		},
		
		# Tier 3: 三色合成（需要特殊组合）
		3: {
			"max_colors": 3,
			"materials_needed": 3, # 1个Tier2 + 1个Tier1，或者特殊组合
			"unlock_condition": "achieve_S_rank_10_times",
			"fusion_rules": [
				{
					"materials": ["Phoenix", "Duck"], # 橙+绿（三色）
					"result": "Forest_Dragon",
					"result_colors": ["ORANGE", "GREEN"],
					"description": "森林之龙，可处理橙色和绿色气泡"
				},
				{
					"materials": ["Peacock", "Parrot"], # 青+红（三色）
					"result": "Ice_Phoenix",
					"result_colors": ["CYAN", "RED"],
					"description": "冰火凤凰，冰火双重属性"
				}
			]
		},
		
		# Tier 4: 四色终极合成
		4: {
			"max_colors": 4,
			"materials_needed": 2, # 需要2个Tier3角色
			"unlock_condition": "complete_all_songs_S_rank",
			"fusion_rules": [
				{
					"materials": ["Forest_Dragon", "Ice_Phoenix"],
					"result": "Cosmic_Entity",
					"result_colors": "ALL_COLORS",
					"description": "宇宙实体，掌控所有颜色"
				}
			]
		}
	}

# 检查合成是否可行
static func can_fuse(char1: String, char2: String, player_progress: Dictionary) -> bool:
	var rules = get_fusion_tier_rules()
	
	for tier_level in rules:
		var tier_rules = rules[tier_level]
		if "fusion_rules" in tier_rules:
			for rule in tier_rules.fusion_rules:
				var materials = rule.materials
				if (materials[0] == char1 and materials[1] == char2) or \
				   (materials[0] == char2 and materials[1] == char1):
					# 检查解锁条件
					return check_unlock_condition(tier_rules.unlock_condition, player_progress)
	return false

# 检查解锁条件
static func check_unlock_condition(condition: String, progress: Dictionary) -> bool:
	match condition:
		"default":
			return true
		"complete_5_songs":
			return progress.get("completed_songs", 0) >= 5
		"achieve_S_rank_10_times":
			return progress.get("s_rank_count", 0) >= 10
		"complete_all_songs_S_rank":
			return progress.get("all_s_rank", false)
		_:
			return false

# 获取合成结果
static func get_fusion_result(char1: String, char2: String) -> Dictionary:
	var rules = get_fusion_tier_rules()
	
	for tier_level in rules:
		var tier_rules = rules[tier_level]
		if "fusion_rules" in tier_rules:
			for rule in tier_rules.fusion_rules:
				var materials = rule.materials
				if (materials[0] == char1 and materials[1] == char2) or \
				   (materials[0] == char2 and materials[1] == char1):
					return rule
	return {}