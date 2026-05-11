## 全局存档脚本 —— 所有解锁/通关状态、金币、钻石都存在这里
## 上传下载只操作这个对象
extends Node

const SAVE_PATH := "user://save_data.json"

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

# ── 游戏设置 ──────────────────────────────────────────
## 游戏设置（音量、全屏等）
var settings: Dictionary = {
	"master_volume": 1.0,
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"fullscreen": false,
	"show_damage_numbers": true,
}

# ── 按键绑定 ──────────────────────────────────────────
## 自定义按键绑定 { "action_name": physical_keycode_int }
var key_bindings: Dictionary = {}

func _ready():
	load_game()

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
		"settings": settings.duplicate(),
		"key_bindings": key_bindings.duplicate(),
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
	if data.has("settings"):
		for key in data["settings"]:
			settings[key] = data["settings"][key]
	if data.has("key_bindings"):
		key_bindings = data["key_bindings"]

## 重置为默认值
func reset() -> void:
	unlocked_characters = ["maphy", "minami", "yuria"]
	character_levels = { "maphy": 1, "minami": 1, "yuria": 1 }
	unlocked_maps = ["tutorial"]
	completed_maps = []
	unlocked_achievements = []
	coins = 500
	diamonds = 0
	best_scores = {}
	# 设置不重置
	save_game()

# ── 本地存档持久化 ─────────────────────────────────────

## 保存存档到本地文件
func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_dict(), "\t"))
		file.close()

## 从本地文件加载存档
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()  # 首次运行，写入默认值
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		file.close()
		if err == OK and json.data is Dictionary:
			from_dict(json.data)
		else:
			push_warning("GlobalSave: 本地存档解析失败，使用默认值")
	# 启动时应用全屏设置
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

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
	save_game()

## 升级角色
func upgrade_character(character_code: String) -> void:
	if character_code in unlocked_characters:
		character_levels[character_code] = character_levels.get(character_code, 1) + 1
		save_game()

## 解锁地图
func unlock_map(map_code: String) -> void:
	if map_code not in unlocked_maps:
		unlocked_maps.append(map_code)
		save_game()

## 通关地图
func complete_map(map_code: String) -> void:
	if map_code not in completed_maps:
		completed_maps.append(map_code)
		save_game()

## 解锁成就
func unlock_achievement(achievement_code: String) -> void:
	if achievement_code not in unlocked_achievements:
		unlocked_achievements.append(achievement_code)
		save_game()

## 增加金币
func add_coins(amount: int) -> void:
	coins += amount
	save_game()

## 消费金币
func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		save_game()
		# 消费金币时自动上传存档
		_auto_upload()
		return true
	return false

## 消费金币后自动上传存档（静默，不弹提示）
func _auto_upload():
	if NetworkManager.is_logged_in:
		NetworkManager.sync_upload()

## 增加钻石
func add_diamonds(amount: int) -> void:
	diamonds += amount
	save_game()

## 消费钻石
func spend_diamonds(amount: int) -> bool:
	if diamonds >= amount:
		diamonds -= amount
		save_game()
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
		save_game()

# ── 设置读写 ──────────────────────────────────────────

## 获取设置值
func get_setting(key: String, default_value = null):
	return settings.get(key, default_value)

## 设置值
func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()

# ── 按键绑定读写 ──────────────────────────────────────

## 获取按键绑定（返回 physical_keycode，0 表示未自定义）
func get_key_binding(action_name: String) -> int:
	return key_bindings.get(action_name, 0)

## 设置按键绑定
func set_key_binding(action_name: String, physical_keycode: int) -> void:
	key_bindings[action_name] = physical_keycode
	save_game()

## 应用所有自定义按键绑定到 InputMap
func apply_key_bindings() -> void:
	for action_name in key_bindings:
		var keycode = key_bindings[action_name]
		if keycode == 0:
			continue
		if not InputMap.has_action(action_name):
			continue
		# 清除该动作的旧事件
		InputMap.action_erase_events(action_name)
		# 创建新的按键事件
		var event = InputEventKey.new()
		event.physical_keycode = keycode as Key
		event.pressed = true
		InputMap.action_add_event(action_name, event)

## 重置按键绑定为默认
func reset_key_bindings() -> void:
	key_bindings.clear()
	save_game()
