## 全局存档脚本 —— 所有解锁/通关状态、金币、钻石都存在这里
## 上传下载只操作这个对象
extends Node

# ── 角色 ──────────────────────────────────────────────
## 已解锁的角色列表（默认解锁前三个角色）
var unlocked_characters: Array = ["maphy", "minami", "yuria"]
## 角色等级 { "角色代码": 等级 }
var character_levels: Dictionary = { "maphy": 1, "minami": 1, "yuria": 1 }

# ── 地图 ──────────────────────────────────────────────
## 已解锁的地图列表
var unlocked_maps: Array = ["tutorial"]
## 已通关的地图列表
var completed_maps: Array = []

# ── 成就 ──────────────────────────────────────────────
## 已解锁的成就列表
var unlocked_achievements: Array = []

# ── 货币 ──────────────────────────────────────────────
## 金币数量
var coins: int = 0
## 钻石数量
var diamonds: int = 0

# ── 最佳成绩 ──────────────────────────────────────────
## 各地图最佳成绩 { "地图代码": 分数 }
var best_scores: Dictionary = {}

# ── 序列化 ─────────────────────────────────────────────

## 将所有存档数据转为字典（用于上传到服务器）
func to_dict() -> Dictionary:
	return {
		"unlocked_characters": unlocked_characters.duplicate(),
		"character_levels": character_levels.duplicate(),
		"unlocked_maps": unlocked_maps.duplicate(),
		"completed_maps": completed_maps.duplicate(),
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"coins": coins,
		"diamonds": diamonds,
		"best_scores": best_scores.duplicate(),
	}

## 从字典恢复存档数据（用于从服务器下载后加载）
func from_dict(data: Dictionary) -> void:
	if data.has("unlocked_characters"):
		unlocked_characters = data["unlocked_characters"]
	if data.has("character_levels"):
		character_levels = data["character_levels"]
	if data.has("unlocked_maps"):
		unlocked_maps = data["unlocked_maps"]
	if data.has("completed_maps"):
		completed_maps = data["completed_maps"]
	if data.has("unlocked_achievements"):
		unlocked_achievements = data["unlocked_achievements"]
	if data.has("coins"):
		coins = int(data["coins"])
	if data.has("diamonds"):
		diamonds = int(data["diamonds"])
	if data.has("best_scores"):
		best_scores = data["best_scores"]

## 重置为默认值
func reset() -> void:
	unlocked_characters = ["maphy", "minami", "yuria"]
	character_levels = { "maphy": 1, "minami": 1, "yuria": 1 }
	unlocked_maps = ["tutorial"]
	completed_maps = []
	unlocked_achievements = []
	coins = 0
	diamonds = 0
	best_scores = {}

# ── 便捷查询方法 ──────────────────────────────────────

## 检查角色是否已解锁
func is_character_unlocked(character_code: String) -> bool:
	return character_code in unlocked_characters

## 检查地图是否已解锁
func is_map_unlocked(map_code: String) -> bool:
	return map_code in unlocked_maps

## 检查地图是否已通关
func is_map_completed(map_code: String) -> bool:
	return map_code in completed_maps

## 获取角色等级
func get_character_level(character_code: String) -> int:
	return character_levels.get(character_code, 1)

## 解锁角色
func unlock_character(character_code: String) -> void:
	if character_code not in unlocked_characters:
		unlocked_characters.append(character_code)
	if not character_levels.has(character_code):
		character_levels[character_code] = 1

## 升级角色
func upgrade_character(character_code: String) -> void:
	if character_code in unlocked_characters:
		character_levels[character_code] = character_levels.get(character_code, 1) + 1

## 解锁地图
func unlock_map(map_code: String) -> void:
	if map_code not in unlocked_maps:
		unlocked_maps.append(map_code)

## 通关地图
func complete_map(map_code: String) -> void:
	if map_code not in completed_maps:
		completed_maps.append(map_code)

## 解锁成就
func unlock_achievement(achievement_code: String) -> void:
	if achievement_code not in unlocked_achievements:
		unlocked_achievements.append(achievement_code)

## 增加金币
func add_coins(amount: int) -> void:
	coins += amount

## 消费金币
func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false

## 增加钻石
func add_diamonds(amount: int) -> void:
	diamonds += amount

## 消费钻石
func spend_diamonds(amount: int) -> bool:
	if diamonds >= amount:
		diamonds -= amount
		return true
	return false

# ── 最佳成绩 ──────────────────────────────────────────

## 获取某地图最佳成绩
func get_best_score(map_code: String) -> int:
	return best_scores.get(map_code, 0)

## 设置某地图最佳成绩（仅在新成绩更高时更新）
func set_best_score(map_code: String, score: int) -> void:
	if score > best_scores.get(map_code, 0):
		best_scores[map_code] = score
