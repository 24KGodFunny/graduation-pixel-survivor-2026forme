## 存档管理器 —— 代理模式，所有操作委托给 GlobalSave
## 保持原有 API 不变，内部全部转发到 GlobalSave
extends Node

# ── 信号 ──────────────────────────────────────────────
signal save_loaded
signal save_reset

# ── 生命周期 ──────────────────────────────────────────

func _ready() -> void:
	print("[SaveManager] 初始化完成（代理模式，数据存储在 GlobalSave）")

# ── 角色相关（委托给 GlobalSave）──────────────────────

## 获取已解锁的角色列表
func get_unlocked_characters() -> Array:
	return GlobalSave.unlocked_characters

## 检查角色是否已解锁
func is_character_unlocked(character_code: String) -> bool:
	return GlobalSave.is_character_unlocked(character_code)

## 解锁角色
func unlock_character(character_code: String) -> void:
	GlobalSave.unlock_character(character_code)

## 获取角色等级
func get_character_level(character_code: String) -> int:
	return GlobalSave.get_character_level(character_code)

## 升级角色
func upgrade_character(character_code: String) -> void:
	GlobalSave.upgrade_character(character_code)

# ── 地图相关（委托给 GlobalSave）──────────────────────

## 获取已解锁的地图列表
func get_unlocked_maps() -> Array:
	return GlobalSave.unlocked_maps

## 检查地图是否已解锁
func is_map_unlocked(map_code: String) -> bool:
	return GlobalSave.is_map_unlocked(map_code)

## 解锁地图
func unlock_map(map_code: String) -> void:
	GlobalSave.unlock_map(map_code)

## 获取已通关的地图列表
func get_completed_maps() -> Array:
	return GlobalSave.completed_maps

## 检查地图是否已通关
func is_map_completed(map_code: String) -> bool:
	return GlobalSave.is_map_completed(map_code)

## 通关地图
func complete_map(map_code: String) -> void:
	GlobalSave.complete_map(map_code)

# ── 成就相关（委托给 GlobalSave）──────────────────────

## 获取已解锁的成就列表
func get_unlocked_achievements() -> Array:
	return GlobalSave.unlocked_achievements

## 检查成就是否已解锁
func is_achievement_unlocked(achievement_code: String) -> bool:
	return achievement_code in GlobalSave.unlocked_achievements

## 解锁成就
func unlock_achievement(achievement_code: String) -> void:
	GlobalSave.unlock_achievement(achievement_code)

# ── 货币相关（委托给 GlobalSave）──────────────────────

## 获取金币数量
func get_coins() -> int:
	return GlobalSave.coins

## 增加金币
func add_coins(amount: int) -> void:
	GlobalSave.add_coins(amount)

## 消费金币
func spend_coins(amount: int) -> bool:
	return GlobalSave.spend_coins(amount)

## 获取钻石数量
func get_diamonds() -> int:
	return GlobalSave.diamonds

## 增加钻石
func add_diamonds(amount: int) -> void:
	GlobalSave.add_diamonds(amount)

## 消费钻石
func spend_diamonds(amount: int) -> bool:
	return GlobalSave.spend_diamonds(amount)

# ── 登录数据本地持久化（token 等会话信息，不属于游戏存档）──────

const LOGIN_DATA_PATH = "user://login_data.cfg"

## 保存登录数据到本地文件
func save_login_data(p_token: String, p_user_id: int, p_nickname: String, p_username: String) -> void:
	var config = ConfigFile.new()
	config.set_value("login", "token", p_token)
	config.set_value("login", "user_id", p_user_id)
	config.set_value("login", "nickname", p_nickname)
	config.set_value("login", "username", p_username)
	config.save(LOGIN_DATA_PATH)
	print("[SaveManager] 登录数据已保存")

## 获取保存的 token
func get_saved_token() -> String:
	var config = ConfigFile.new()
	if config.load(LOGIN_DATA_PATH) == OK:
		return config.get_value("login", "token", "")
	return ""

## 获取保存的 user_id
func get_saved_user_id() -> int:
	var config = ConfigFile.new()
	if config.load(LOGIN_DATA_PATH) == OK:
		return config.get_value("login", "user_id", 0)
	return 0

## 获取保存的 nickname
func get_saved_nickname() -> String:
	var config = ConfigFile.new()
	if config.load(LOGIN_DATA_PATH) == OK:
		return config.get_value("login", "nickname", "")
	return ""

## 获取保存的 username
func get_saved_username() -> String:
	var config = ConfigFile.new()
	if config.load(LOGIN_DATA_PATH) == OK:
		return config.get_value("login", "username", "")
	return ""

## 清除登录数据
func clear_login_data() -> void:
	if FileAccess.file_exists(LOGIN_DATA_PATH):
		DirAccess.remove_absolute(LOGIN_DATA_PATH)
	print("[SaveManager] 登录数据已清除")

# ── 存档操作 ──────────────────────────────────────────

## 重置存档
func reset_save() -> void:
	GlobalSave.reset()
	save_reset.emit()
	print("[SaveManager] 存档已重置")

## 从服务器下载存档并应用到 GlobalSave
func apply_download_data(data: Dictionary) -> void:
	GlobalSave.from_dict(data)
	save_loaded.emit()
	print("[SaveManager] 服务器存档已应用到 GlobalSave")

## 获取上传数据（从 GlobalSave 导出）
func get_upload_data() -> Dictionary:
	return GlobalSave.to_dict()

# ── 最佳成绩（委托给 GlobalSave）──────────────────────

## 获取某地图最佳成绩
func get_best_score(map_code: String) -> int:
	return GlobalSave.get_best_score(map_code)

## 设置某地图最佳成绩
func set_best_score(map_code: String, score: int) -> void:
	GlobalSave.set_best_score(map_code, score)
