extends Node2D

var player_ref: Node2D
var weapon_timers: Dictionary = {}

# Weapons that fire towards cursor (handheld weapons)
const CURSOR_AIM_WEAPONS = ["bullet", "bouncing", "flame"]
# Melee weapons
const MELEE_WEAPONS = ["axe"]
# Weapon sound effects mapping (full resource paths)
const WEAPON_SFX = {
	"pistol": "res://assets/audio/sfx_shoot.wav",
	"sniper": "res://assets/audio/sfx_shoot.wav",
	"axe": "res://assets/audio/sfx_hit.wav",
	"grenade": "res://assets/audio/sfx_explosion.wav",
	"baseball": "res://assets/audio/sfx_hit.wav",
	"flamethrower": "res://assets/audio/sfx_shoot.wav",
	"drone": "res://assets/audio/sfx_shoot.wav",
	"missile": "res://assets/audio/sfx_explosion.wav",
	"talisman": "res://assets/audio/sfx_shoot.wav",
	"dagger": "res://assets/audio/sfx_hit.wav",
	"orbital": "res://assets/audio/sfx_shoot.wav",
	"pulse": "res://assets/audio/sfx_shoot.wav",
	"matrix": "res://assets/audio/sfx_shoot.wav",
	"star": "res://assets/audio/sfx_shoot.wav",
	"holywater": "res://assets/audio/sfx_shoot.wav",
	"fireroad": "res://assets/audio/sfx_shoot.wav",
}

func _ready():
	GameManager.game_started.connect(_on_game_started)
	GameManager.weapon_acquired.connect(_on_weapon_acquired)

func _on_game_started():
	weapon_timers.clear()
	for w in GameManager.equipped_weapons:
		weapon_timers[w["id"]] = 0.0

func _on_weapon_acquired(weapon_id: String):
	weapon_timers[weapon_id] = 0.0

func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if player_ref == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
		else:
			return
	
	for w in GameManager.equipped_weapons:
		var wid = w["id"]
		var lvl = w["level"]
		var lvl_data = Database.get_weapon_data(wid, lvl)
		var cd = lvl_data["cooldown"] * GameManager.player_cooldown_mult
		
		weapon_timers[wid] -= delta
		if weapon_timers[wid] <= 0:
			weapon_timers[wid] = cd
			_fire_weapon(wid, lvl_data)

func _fire_weapon(weapon_id: String, lvl_data: Dictionary):
	var wdata = Database.weapons[weapon_id]
	var count = lvl_data["count"] + GameManager.player_amount_bonus
	var damage = int(lvl_data["damage"] * GameManager.player_damage_mult)
	var speed = lvl_data.get("speed", wdata["projectile_speed"]) * GameManager.player_projectile_speed_mult
	var pierce = lvl_data["pierce"]
	var area = lvl_data["area"] * GameManager.player_area_mult
	var kb = wdata["knockback"]
	var proj_scene = wdata["projectile_scene"]
	
	# Check crit
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var is_crit = rng.randf() < GameManager.player_crit_chance
	if is_crit:
		damage = int(damage * GameManager.player_crit_damage)
	
	# Play weapon sound effect
	var sfx_path = WEAPON_SFX.get(proj_scene, "res://assets/audio/sfx_shoot.wav")
	AudioManager.play_sfx(sfx_path)
	
	# Melee weapons
	if MELEE_WEAPONS.has(proj_scene):
		_fire_melee(weapon_id, count, damage, kb, area)
		return
	
	# Determine aim mode: cursor for handheld weapons, auto-aim for skill/buff weapons
	var use_cursor = CURSOR_AIM_WEAPONS.has(proj_scene)
	
	if use_cursor:
		_fire_towards_cursor(weapon_id, proj_scene, count, damage, speed, pierce, kb, area)
	else:
		_fire_auto_aim(weapon_id, proj_scene, count, damage, speed, pierce, kb, area)

func _fire_melee(_weapon_id: String, count: int, damage: int, kb: float, area: float):
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player_ref.global_position).normalized()
	var angle = dir.angle()
	
	for i in range(count):
		var slash = Area2D.new()
		slash.set_script(preload("res://scripts/melee_attack.gd"))
		slash.global_position = player_ref.global_position
		get_tree().current_scene.add_child(slash)
		# Spread slashes for multiple count
		var slash_angle = angle
		if count > 1:
			slash_angle = angle + deg_to_rad(20.0 * (i - float(count - 1) / 2.0))
		slash.setup(damage, kb, slash_angle, area)

func _fire_towards_cursor(weapon_id: String, proj_scene: String, count: int, damage: int, speed: float, pierce: int, kb: float, area: float):
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player_ref.global_position).normalized()
	
	for i in range(count):
		var bullet_dir = dir
		# Add spread for multiple projectiles
		if count > 1:
			var spread = deg_to_rad(15.0 * (i - float(count - 1) / 2.0))
			bullet_dir = dir.rotated(spread)
		
		var proj = _create_projectile(weapon_id, proj_scene)
		if proj:
			proj.global_position = player_ref.global_position
			proj.setup(bullet_dir, speed, damage, pierce, kb, area)
			get_tree().current_scene.add_child(proj)

func _fire_auto_aim(weapon_id: String, proj_scene: String, count: int, damage: int, speed: float, pierce: int, kb: float, area: float):
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	for i in range(count):
		var target = _find_nearest_enemy(enemies, i)
		if target == null:
			break
		var dir = (target.global_position - player_ref.global_position).normalized()
		# Add spread for multiple projectiles
		if count > 1:
			var spread = deg_to_rad(15.0 * (i - float(count - 1) / 2.0))
			dir = dir.rotated(spread)
		
		var proj = _create_projectile(weapon_id, proj_scene)
		if proj:
			proj.global_position = player_ref.global_position
			proj.setup(dir, speed, damage, pierce, kb, area)
			get_tree().current_scene.add_child(proj)

func _find_nearest_enemy(enemies: Array, index: int) -> Node2D:
	if enemies.is_empty():
		return null
	var sorted = enemies.duplicate()
	sorted.sort_custom(func(a, b):
		var da = a.global_position.distance_squared_to(player_ref.global_position)
		var db = b.global_position.distance_squared_to(player_ref.global_position)
		return da < db
	)
	return sorted[index % sorted.size()]

func _create_projectile(weapon_id: String, proj_scene: String) -> Node2D:
	var proj_node = Area2D.new()
	proj_node.set_script(preload("res://scripts/projectile.gd"))
	proj_node.weapon_id = weapon_id
	proj_node.proj_type = proj_scene
	return proj_node