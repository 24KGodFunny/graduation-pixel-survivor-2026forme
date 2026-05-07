extends Node
## SaveManager autoload - handles save/load, unlocks, achievements, and easter eggs

signal achievement_unlocked(achievement_id: String)
signal character_unlocked(character_id: String)

const SAVE_PATH = "user://save_data.json"

# Unlocked characters (default unlocked - only initial two)
var unlocked_characters: Array[String] = ["maphy", "minami"]
# Unlocked maps
var unlocked_maps: Array[String] = ["endless_road"]
# Achievements
var achievements: Dictionary = {}
# Stats
var total_kills: int = 0
var total_games: int = 0
var total_wins: int = 0
var total_coins: int = 0
var best_time: float = 0.0

# Currency
var gold: int = 0
var diamond: int = 0
# Best scores per map
var best_scores: Dictionary = {}
# Character levels (char_id -> level, default 1)
var character_levels: Dictionary = {}

# Easter egg flags
var konami_activated: bool = false
var konami_sequence: Array[int] = []
var konami_code: Array[int] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A
]
var secret_character_unlocked: bool = false
var dev_room_found: bool = false
var kill_milestone_reached: Array[int] = []

# Settings
var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false

# Login data
var saved_token: String = ""
var saved_user_id: int = 0
var saved_nickname: String = ""
var saved_username: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_achievements()
	load_data()

func _init_achievements():
	achievements = {
		"first_blood": {"name": "初次击杀", "desc": "击杀第一个敌人", "unlocked": false},
		"kill_100": {"name": "百人斩", "desc": "累计击杀100个敌人", "unlocked": false},
		"kill_1000": {"name": "千人斩", "desc": "累计击杀1000个敌人", "unlocked": false},
		"kill_10000": {"name": "万人斩", "desc": "累计击杀10000个敌人", "unlocked": false},
		"first_win": {"name": "初次胜利", "desc": "首次通关任意地图", "unlocked": false},
		"all_maps": {"name": "探索者", "desc": "通关所有地图", "unlocked": false},
		"no_damage": {"name": "完美闪避", "desc": "不受伤通关", "unlocked": false},
		"speed_run": {"name": "速通达人", "desc": "5分钟内通关", "unlocked": false},
		"konami": {"name": "???秘籍???", "desc": "输入神秘代码", "unlocked": false},
		"boss_rush": {"name": "Boss猎手", "desc": "击败所有Boss", "unlocked": false},
		"max_weapon": {"name": "武器大师", "desc": "将任意武器升到满级", "unlocked": false},
		"full_build": {"name": "满装出击", "desc": "同时装备6把武器", "unlocked": false},
		"survivor": {"name": "生存专家", "desc": "存活超过10分钟", "unlocked": false},
		"collector": {"name": "收藏家", "desc": "解锁所有角色", "unlocked": false},
		"secret_char": {"name": "隐藏角色", "desc": "发现隐藏角色", "unlocked": false},
	}

func _input(event):
	if event is InputEventKey and event.pressed:
		_check_konami_code(event.keycode)

func _check_konami_code(key: int):
	konami_sequence.append(key)
	if konami_sequence.size() > konami_code.size():
		konami_sequence.pop_front()
	
	if konami_sequence.size() == konami_code.size():
		var match_all = true
		for i in range(konami_code.size()):
			if konami_sequence[i] != konami_code[i]:
				match_all = false
				break
		if match_all:
			_activate_konami()
			konami_sequence.clear()

func _activate_konami():
	if konami_activated:
		return
	konami_activated = true
	unlock_achievement("konami")
	# Unlock secret character
	if not unlocked_characters.has("mika"):
		unlocked_characters.append("mika")
		secret_character_unlocked = true
		character_unlocked.emit("mika")
		unlock_achievement("secret_char")
	save_data()

func check_kill_achievements(kills: int):
	if kills >= 1 and not achievements["first_blood"]["unlocked"]:
		unlock_achievement("first_blood")
	if kills >= 100 and not achievements["kill_100"]["unlocked"]:
		unlock_achievement("kill_100")
	if kills >= 1000 and not achievements["kill_1000"]["unlocked"]:
		unlock_achievement("kill_1000")
	if kills >= 10000 and not achievements["kill_10000"]["unlocked"]:
		unlock_achievement("kill_10000")
	# Kill milestones for easter eggs
	var milestones = [50, 100, 200, 500, 1000, 2000, 5000, 10000]
	for m in milestones:
		if kills >= m and not kill_milestone_reached.has(m):
			kill_milestone_reached.append(m)

func check_win_achievements(time: float, damage_taken: bool):
	total_wins += 1
	if not achievements["first_win"]["unlocked"]:
		unlock_achievement("first_win")
	if time < 300.0 and not achievements["speed_run"]["unlocked"]:
		unlock_achievement("speed_run")
	if not damage_taken and not achievements["no_damage"]["unlocked"]:
		unlock_achievement("no_damage")
	save_data()

func unlock_achievement(achievement_id: String):
	if achievements.has(achievement_id) and not achievements[achievement_id]["unlocked"]:
		achievements[achievement_id]["unlocked"] = true
		achievement_unlocked.emit(achievement_id)

func unlock_character(character_id: String):
	if not unlocked_characters.has(character_id):
		unlocked_characters.append(character_id)
		character_unlocked.emit(character_id)
		if unlocked_characters.size() >= Database.characters.size():
			unlock_achievement("collector")
		save_data()

func unlock_map(map_id: String):
	if not unlocked_maps.has(map_id):
		unlocked_maps.append(map_id)
		save_data()

func get_best_score(map_id: String) -> int:
	if best_scores.has(map_id):
		return best_scores[map_id]
	return 0

func set_best_score(map_id: String, score: int):
	if not best_scores.has(map_id) or score > best_scores[map_id]:
		best_scores[map_id] = score
		save_data()

func is_character_unlocked(character_id: String) -> bool:
	return unlocked_characters.has(character_id)

func is_map_unlocked(map_id: String) -> bool:
	return unlocked_maps.has(map_id)

func add_game_stats(kills: int, coins: int, time: float, won: bool):
	total_kills += kills
	total_coins += coins
	total_games += 1
	if time > best_time:
		best_time = time
	check_kill_achievements(total_kills)
	if time >= 600.0:
		unlock_achievement("survivor")
	# Unlock maps based on wins
	if won:
		if total_wins >= 1:
			unlock_map("wasteland")
		if total_wins >= 3:
			unlock_map("crimson_forest")
	save_data()

func save_login_data(token: String, user_id: int, nick: String, user: String):
	saved_token = token
	saved_user_id = user_id
	saved_nickname = nick
	saved_username = user
	save_data()

func clear_login_data():
	saved_token = ""
	saved_user_id = 0
	saved_nickname = ""
	saved_username = ""
	save_data()

func get_saved_token() -> String:
	return saved_token

func get_saved_user_id() -> int:
	return saved_user_id

func get_saved_nickname() -> String:
	return saved_nickname

func get_saved_username() -> String:
	return saved_username

func get_character_level(char_id: String) -> int:
	if character_levels.has(char_id):
		return character_levels[char_id]
	return 1

func upgrade_character(char_id: String) -> bool:
	var current_level = get_character_level(char_id)
	if current_level >= Database.CHARACTER_MAX_LEVEL:
		return false
	var cost = Database.get_character_level_up_cost(current_level)
	if gold < cost:
		return false
	gold -= cost
	character_levels[char_id] = current_level + 1
	save_data()
	return true

func add_gold(amount: int):
	gold += amount
	save_data()

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		save_data()
		return true
	return false

func add_diamond(amount: int):
	diamond += amount
	save_data()

# 准备上传数据（本地 -> 服务器）
func prepare_upload_data() -> Dictionary:
	var characters = []
	for char_id in unlocked_characters:
		var char_data = {
			"characterCode": char_id,
			"level": get_character_level(char_id),
			"hpUpgrade": 0,
			"atkUpgrade": 0,
			"defUpgrade": 0,
			"speedUpgrade": 0,
			"combatPower": 0
		}
		characters.append(char_data)
	
	var map_progress = []
	for map_id in unlocked_maps:
		var map_data = {
			"mapCode": map_id,
			"unlocked": 1,
			"bestWave": best_scores.get(map_id, 0),
			"bestGrade": "",
			"clearCount": total_wins
		}
		map_progress.append(map_data)
	
	var achievements_list = []
	for ach_id in achievements:
		var ach = achievements[ach_id]
		var ach_data = {
			"achievementCode": ach_id,
			"unlocked": 1 if ach.get("unlocked", false) else 0,
			"progress": 0
		}
		achievements_list.append(ach_data)
	
	var data = {
		"coins": gold,
		"diamonds": diamond,
		"level": 1,
		"exp": 0,
		"characters": characters,
		"mapProgress": map_progress,
		"achievements": achievements_list,
		"gameStats": {
			"totalKills": total_kills,
			"totalDeaths": 0,
			"totalPlayTime": int(best_time),
			"maxKillsInGame": 0,
			"maxWave": 0,
			"totalClears": total_wins
		}
	}
	return data

# 应用下载数据（服务器 -> 本地）
func apply_download_data(data: Dictionary):
	# 金币/钻石
	if data.has("coins"):
		gold = data["coins"]
	if data.has("diamonds"):
		diamond = data["diamonds"]
	
	# 角色列表 - 合并（取并集）
	if data.has("characters") and data["characters"] is Array:
		for char_data in data["characters"]:
			var char_code = char_data.get("characterCode", "")
			if char_code != "" and not unlocked_characters.has(char_code):
				unlocked_characters.append(char_code)
			# 更新角色等级
			if char_code != "" and char_data.has("level"):
				var server_level = char_data["level"]
				var local_level = get_character_level(char_code)
				if server_level > local_level:
					character_levels[char_code] = server_level
	
	# 地图进度 - 合并
	if data.has("mapProgress") and data["mapProgress"] is Array:
		for map_data in data["mapProgress"]:
			var map_code = map_data.get("mapCode", "")
			if map_code != "" and not unlocked_maps.has(map_code):
				unlocked_maps.append(map_code)
			# 更新最高分
			if map_code != "" and map_data.has("bestWave"):
				var server_wave = map_data["bestWave"]
				var local_wave = best_scores.get(map_code, 0)
				if server_wave > local_wave:
					best_scores[map_code] = server_wave
	
	# 成就 - 合并
	if data.has("achievements") and data["achievements"] is Array:
		for ach_data in data["achievements"]:
			var ach_code = ach_data.get("achievementCode", "")
			if ach_code != "" and achievements.has(ach_code):
				if ach_data.get("unlocked", 0) == 1:
					achievements[ach_code]["unlocked"] = true
	
	# 游戏统计 - 取最大值
	if data.has("gameStats") and data["gameStats"] is Dictionary:
		var stats = data["gameStats"]
		if stats.has("totalKills") and stats["totalKills"] > total_kills:
			total_kills = stats["totalKills"]
		if stats.has("totalClears") and stats["totalClears"] > total_wins:
			total_wins = stats["totalClears"]
	
	save_data()

func save_data():
	var data = {
		"unlocked_characters": unlocked_characters,
		"unlocked_maps": unlocked_maps,
		"achievements": achievements,
		"total_kills": total_kills,
		"total_games": total_games,
		"total_wins": total_wins,
		"total_coins": total_coins,
		"best_time": best_time,
		"konami_activated": konami_activated,
		"secret_character_unlocked": secret_character_unlocked,
		"kill_milestone_reached": kill_milestone_reached,
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"saved_token": saved_token,
		"saved_user_id": saved_user_id,
		"saved_nickname": saved_nickname,
		"saved_username": saved_username,
		"gold": gold,
		"diamond": diamond,
		"best_scores": best_scores,
		"character_levels": character_levels,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()
	if result != OK:
		return
	var data = json.data
	if not data is Dictionary:
		return
	
	if data.has("unlocked_characters"):
		unlocked_characters.clear()
		for c in data["unlocked_characters"]:
			unlocked_characters.append(c)
	if data.has("unlocked_maps"):
		unlocked_maps.clear()
		for m in data["unlocked_maps"]:
			unlocked_maps.append(m)
	if data.has("achievements"):
		for key in data["achievements"]:
			if achievements.has(key):
				achievements[key] = data["achievements"][key]
	if data.has("total_kills"):
		total_kills = data["total_kills"]
	if data.has("total_games"):
		total_games = data["total_games"]
	if data.has("total_wins"):
		total_wins = data["total_wins"]
	if data.has("total_coins"):
		total_coins = data["total_coins"]
	if data.has("best_time"):
		best_time = data["best_time"]
	if data.has("konami_activated"):
		konami_activated = data["konami_activated"]
	if data.has("secret_character_unlocked"):
		secret_character_unlocked = data["secret_character_unlocked"]
	if data.has("kill_milestone_reached"):
		kill_milestone_reached.clear()
		for m in data["kill_milestone_reached"]:
			kill_milestone_reached.append(m)
	if data.has("master_volume"):
		master_volume = data["master_volume"]
	if data.has("bgm_volume"):
		bgm_volume = data["bgm_volume"]
	if data.has("sfx_volume"):
		sfx_volume = data["sfx_volume"]
	if data.has("fullscreen"):
		fullscreen = data["fullscreen"]
	if data.has("saved_token"):
		saved_token = data["saved_token"]
	if data.has("saved_user_id"):
		saved_user_id = data["saved_user_id"]
	if data.has("saved_nickname"):
		saved_nickname = data["saved_nickname"]
	if data.has("saved_username"):
		saved_username = data["saved_username"]
	if data.has("gold"):
		gold = data["gold"]
	if data.has("diamond"):
		diamond = data["diamond"]
	if data.has("best_scores"):
		best_scores = data["best_scores"]
	if data.has("character_levels"):
		character_levels = data["character_levels"]
