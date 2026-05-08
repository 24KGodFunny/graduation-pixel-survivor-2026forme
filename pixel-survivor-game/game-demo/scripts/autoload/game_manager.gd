extends Node
## GameManager autoload - manages game state, player stats, and game flow

signal game_started
signal game_paused
signal game_resumed
signal game_over(victory: bool)
signal player_leveled_up(new_level: int)
signal player_damaged(current_hp: int, max_hp: int)
signal player_healed(amount: int)
signal enemy_killed(enemy_pos: Vector2, exp_amount: int)
@warning_ignore("unused_signal")
signal boss_spawned(boss_name: String)
@warning_ignore("unused_signal")
signal boss_defeated(boss_id: String)
signal time_updated(seconds: int)
signal weapon_acquired(weapon_id: String)
signal passive_acquired(passive_id: String)
signal boss_phase_started  # Emitted when normal phase ends, boss phase begins
signal boss_intro_started  # Emitted after 3s intro, boss can spawn
signal all_pickups_absorbed  # Emitted when all pickups have been absorbed

# Game state
enum GameState { MENU, PLAYING, PAUSED, LEVEL_UP, DIALOGUE, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU
var selected_character_id: String = "maphy"
var selected_map_id: String = "endless_road"

# Player stats (runtime)
var player_hp: int = 100
var player_max_hp: int = 100
var player_speed: float = 200.0
var player_armor: int = 0
var player_damage_mult: float = 1.0
var player_cooldown_mult: float = 1.0
var player_crit_chance: float = 0.05
var player_crit_damage: float = 1.5
var player_luck: float = 1.0
var player_growth: float = 1.0
var player_greed: float = 1.0
var player_magnet_range: float = 50.0
var player_speed_mult: float = 1.0
var player_area_mult: float = 1.0
var player_duration_mult: float = 1.0
var player_amount_bonus: int = 0
var player_hp_regen: float = 0.0
var player_max_hp_mult: float = 1.0
var player_revival_count: int = 0
var player_projectile_speed_mult: float = 1.0

# Experience
var player_level: int = 1
var player_exp: int = 0
var player_coins: int = 0

# Weapons and passives
var equipped_weapons: Array[Dictionary] = []  # [{id, level}]
var equipped_passives: Array[Dictionary] = []  # [{id, level}]

# Game timer
var game_time: float = 0.0
var game_time_limit: float = 900.0  # 15 minutes (kept for reference)

# Kill counter
var kill_count: int = 0
var boss_spawned_flag: bool = false

# Boss battle state
var boss_active: bool = false
var boss_ref: Node = null

# Boss phase flow
var boss_phase: bool = false  # Whether we've entered boss phase
var normal_phase_duration: float = 300.0  # 5 minutes of normal enemies
var boss_intro_playing: bool = false  # Boss intro animation playing
var boss_intro_timer: float = 0.0
var boss_intro_duration: float = 3.0  # 3 seconds for boss intro
var absorbing_pickups: bool = false  # Absorbing pickups after boss defeat

# Combat statistics
var total_damage_dealt: float = 0.0
var damage_taken: int = 0
var coins_collected: int = 0
var weapons_collected: int = 0

# Difficulty scaling
var difficulty_mult: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float):
	if current_state == GameState.PLAYING:
		game_time += delta
		# Update difficulty
		difficulty_mult = 1.0 + game_time / 300.0  # +1x every 5 minutes
		# HP regen
		if player_hp_regen > 0:
			var heal_amount = player_hp_regen * delta
			_heal_accumulator += heal_amount
			if _heal_accumulator >= 1.0:
				var heal_int = int(_heal_accumulator)
				_heal_accumulator -= heal_int
				player_hp = mini(player_hp + heal_int, player_max_hp)
		# Emit time signal every second
		var prev_second = int(game_time - delta)
		var curr_second = int(game_time)
		if curr_second > prev_second:
			time_updated.emit(curr_second)
		# Check normal phase end -> boss phase
		if not boss_phase and game_time >= normal_phase_duration:
			_start_boss_phase()
		# Boss intro countdown
		if boss_intro_playing:
			boss_intro_timer -= delta
			if boss_intro_timer <= 0:
				boss_intro_playing = false
				boss_intro_started.emit()
		# Pickup absorption
		if absorbing_pickups:
			_process_pickup_absorption(delta)

var _heal_accumulator: float = 0.0

func start_game():
	# Reset all stats (use leveled stats)
	var char_level = SaveManager.get_character_level(selected_character_id)
	var char_data = Database.get_character_stats_at_level(selected_character_id, char_level)
	player_max_hp = int(char_data["max_hp"] * player_max_hp_mult)
	player_hp = player_max_hp
	player_speed = char_data["speed"]
	player_armor = char_data["armor"]
	player_damage_mult = char_data["damage_mult"]
	player_cooldown_mult = char_data["cooldown_mult"]
	player_crit_chance = char_data["crit_chance"]
	player_crit_damage = char_data["crit_damage"]
	player_luck = char_data["luck"]
	player_growth = char_data["growth"]
	player_greed = char_data["greed"]
	player_magnet_range = char_data["magnet_range"]
	player_speed_mult = 1.0
	player_area_mult = 1.0
	player_duration_mult = 1.0
	player_amount_bonus = 0
	player_hp_regen = 0.0
	player_max_hp_mult = 1.0
	player_revival_count = 0
	player_projectile_speed_mult = 1.0
	_heal_accumulator = 0.0
	
	player_level = 1
	player_exp = 0
	player_coins = 0
	game_time = 0.0
	kill_count = 0
	boss_spawned_flag = false
	boss_active = false
	boss_ref = null
	boss_phase = false
	boss_intro_playing = false
	boss_intro_timer = 0.0
	absorbing_pickups = false
	total_damage_dealt = 0.0
	damage_taken = 0
	coins_collected = 0
	weapons_collected = 0
	difficulty_mult = 1.0
	
	equipped_weapons.clear()
	equipped_passives.clear()
	
	# Add starting weapon
	var start_weapon = char_data["starting_weapon"]
	equipped_weapons.append({"id": start_weapon, "level": 0})
	
	# Add starting passive if character has one
	if char_data["passive"] != "":
		equipped_passives.append({"id": char_data["passive"], "level": 0})
	
	# Set time limit from map (used for reference, boss phase triggers at normal_phase_duration)
	var map_data = Database.maps[selected_map_id]
	game_time_limit = map_data["time_limit"]
	# Use map's normal_phase_duration if defined, otherwise default 300
	normal_phase_duration = map_data.get("normal_phase_duration", 300.0)
	
	current_state = GameState.PLAYING
	game_started.emit()

func pause_game():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()

func resume_game():
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func damage_player(amount: float):
	if current_state != GameState.PLAYING:
		return
	var actual_damage = maxi(1, int(amount) - player_armor)
	player_hp -= actual_damage
	damage_taken += actual_damage
	player_damaged.emit(player_hp, player_max_hp)
	if player_hp <= 0:
		if player_revival_count > 0:
			player_revival_count -= 1
			player_hp = int(player_max_hp / 2.0)
			player_healed.emit(int(player_max_hp / 2.0))
		else:
			lose_game()

func heal_player(amount: int):
	player_hp = mini(player_hp + amount, player_max_hp)
	player_healed.emit(amount)

func add_exp(amount: int):
	var actual_amount = int(amount * player_growth)
	player_exp += actual_amount
	var exp_needed = Database.get_exp_for_level(player_level)
	while player_exp >= exp_needed:
		player_exp -= exp_needed
		player_level += 1
		# Set state BEFORE emitting signal so UI can check it
		if current_state == GameState.PLAYING:
			current_state = GameState.LEVEL_UP
		player_leveled_up.emit(player_level)
		exp_needed = Database.get_exp_for_level(player_level)

func add_coins(amount: int):
	var gained = int(amount * player_greed)
	player_coins += gained
	coins_collected += gained

func record_damage_dealt(amount: float):
	total_damage_dealt += amount

func record_damage_taken(amount: int):
	damage_taken += amount

func kill_enemy(pos: Vector2, exp_amount: int):
	kill_count += 1
	enemy_killed.emit(pos, exp_amount)
	add_exp(exp_amount)

func add_weapon(weapon_id: String):
	# Check if already owned
	for w in equipped_weapons:
		if w["id"] == weapon_id:
			# Level up
			var max_lvl = Database.weapons[weapon_id]["max_level"] - 1
			w["level"] = mini(w["level"] + 1, max_lvl)
			return
	equipped_weapons.append({"id": weapon_id, "level": 0})
	weapon_acquired.emit(weapon_id)

func add_passive(passive_id: String):
	for p in equipped_passives:
		if p["id"] == passive_id:
			var max_lvl = Database.passive_items[passive_id]["max_level"] - 1
			p["level"] = mini(p["level"] + 1, max_lvl)
			_apply_passive_stats()
			return
	equipped_passives.append({"id": passive_id, "level": 0})
	_apply_passive_stats()
	passive_acquired.emit(passive_id)

func _apply_passive_stats():
	# Reset to base (use leveled stats)
	var char_level = SaveManager.get_character_level(selected_character_id)
	var char_data = Database.get_character_stats_at_level(selected_character_id, char_level)
	player_armor = char_data["armor"]
	player_damage_mult = char_data["damage_mult"]
	player_cooldown_mult = char_data["cooldown_mult"]
	player_crit_chance = char_data["crit_chance"]
	player_luck = char_data["luck"]
	player_growth = char_data["growth"]
	player_greed = char_data["greed"]
	player_magnet_range = char_data["magnet_range"]
	player_speed_mult = 1.0
	player_area_mult = 1.0
	player_duration_mult = 1.0
	player_amount_bonus = 0
	player_hp_regen = 0.0
	player_max_hp_mult = 1.0
	player_projectile_speed_mult = 1.0
	
	for p in equipped_passives:
		var passive_data = Database.passive_items[p["id"]]
		var stat = passive_data["stat"]
		var value = passive_data["values"][p["level"]]
		match stat:
			"armor": player_armor += value
			"damage_mult": player_damage_mult *= value
			"cooldown_mult": player_cooldown_mult *= value
			"crit_chance": player_crit_chance += value
			"luck": player_luck *= value
			"growth": player_growth *= value
			"greed": player_greed *= value
			"magnet_range": player_magnet_range = value
			"speed_mult": player_speed_mult *= value
			"area_mult": player_area_mult *= value
			"duration_mult": player_duration_mult *= value
			"amount_bonus": player_amount_bonus += value
			"hp_regen": player_hp_regen += value
			"max_hp_mult": player_max_hp_mult *= value
			"projectile_speed_mult": player_projectile_speed_mult *= value
			"revival_count": player_revival_count += value
	
	# Recalculate max HP (use leveled base)
	var old_max = player_max_hp
	player_max_hp = int(char_data["max_hp"] * player_max_hp_mult)
	player_hp = mini(player_hp + (player_max_hp - old_max), player_max_hp)

func get_level_up_choices() -> Array:
	var choices := []
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Collect available weapons (new or upgradeable)
	var available_weapons := []
	for weapon_id in Database.weapons:
		var owned = false
		for w in equipped_weapons:
			if w["id"] == weapon_id:
				owned = true
				if w["level"] < Database.weapons[weapon_id]["max_level"] - 1:
					available_weapons.append({"type": "weapon", "id": weapon_id, "is_new": false})
				break
		if not owned and equipped_weapons.size() < 6:
			available_weapons.append({"type": "weapon", "id": weapon_id, "is_new": true})
	
	# Collect available passives
	var available_passives := []
	for passive_id in Database.passive_items:
		var owned = false
		for p in equipped_passives:
			if p["id"] == passive_id:
				owned = true
				if p["level"] < Database.passive_items[passive_id]["max_level"] - 1:
					available_passives.append({"type": "passive", "id": passive_id, "is_new": false})
				break
		if not owned and equipped_passives.size() < 6:
			available_passives.append({"type": "passive", "id": passive_id, "is_new": true})
	
	# Mix and pick 3-4 choices
	var pool = available_weapons + available_passives
	pool.shuffle()
	var count = mini(4, pool.size())
	for i in range(count):
		choices.append(pool[i])
	
	# Always include a heal option if HP < 50%
	if player_hp < int(player_max_hp / 2.0) and choices.size() < 4:
		choices.append({"type": "heal", "id": "heal", "is_new": true})
	
	return choices

func apply_level_up_choice(choice: Dictionary):
	match choice["type"]:
		"weapon":
			add_weapon(choice["id"])
		"passive":
			add_passive(choice["id"])
		"heal":
			heal_player(int(player_max_hp / 4.0))
	current_state = GameState.PLAYING

func _start_boss_phase():
	boss_phase = true
	
	# 1. 清空场上所有怪物
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# 2. 将主角传送至出生点
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].global_position = Vector2.ZERO
	
	# 3. 创建Boss竞技场阻挡物
	var game_scene = get_tree().current_scene
	if game_scene.has_method("create_boss_arena"):
		game_scene.create_boss_arena()
	
	boss_phase_started.emit()
	# Start boss intro
	boss_intro_playing = true
	boss_intro_timer = boss_intro_duration

func absorb_all_pickups():
	# Collect all pickups on the field and absorb them to the player
	absorbing_pickups = true
	var pickups = get_tree().get_nodes_in_group("pickups")
	if pickups.size() == 0:
		absorbing_pickups = false
		all_pickups_absorbed.emit()
		win_game()
		return
	# Move all pickups toward player at high speed
	for pickup in pickups:
		if is_instance_valid(pickup) and pickup.has_method("set_absorbing"):
			pickup.set_absorbing(true)
	# Set a timeout to force-complete absorption
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_force_finish_absorption)

func _process_pickup_absorption(_delta: float):
	var pickups = get_tree().get_nodes_in_group("pickups")
	if pickups.size() == 0:
		absorbing_pickups = false
		all_pickups_absorbed.emit()
		win_game()

func _force_finish_absorption():
	if absorbing_pickups:
		absorbing_pickups = false
		# Force collect remaining pickups
		var pickups = get_tree().get_nodes_in_group("pickups")
		for pickup in pickups:
			if is_instance_valid(pickup):
				if pickup.has_method("force_collect"):
					pickup.force_collect()
				else:
					pickup.queue_free()
		all_pickups_absorbed.emit()
		win_game()

func win_game():
	current_state = GameState.VICTORY
	SaveManager.add_coins(player_coins)
	game_over.emit(true)

func lose_game():
	current_state = GameState.GAME_OVER
	SaveManager.add_coins(player_coins)
	game_over.emit(false)

func get_game_time_string() -> String:
	var total_seconds := floori(game_time)
	var minutes := int(total_seconds / 60.0)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func get_player_position() -> Vector2:
	# This will be set by the player node
	return Vector2.ZERO