extends Node2D

var spawn_timer: float = 0.0
var boss_timer: float = 0.0
var enemy_count: int = 0
var max_enemies: int = 200
var map_data: Dictionary = {}

func _ready():
	GameManager.game_started.connect(_on_game_started)

func _on_game_started():
	map_data = Database.maps[GameManager.selected_map_id]
	max_enemies = map_data["max_enemies"]
	spawn_timer = 1.0
	boss_timer = 600.0  # Boss at 10 min
	enemy_count = 0

func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	enemy_count = get_tree().get_nodes_in_group("enemies").size()
	
	spawn_timer -= delta
	if spawn_timer <= 0 and enemy_count < max_enemies:
		var rate = map_data.get("spawn_rate_base", 1.0) - GameManager.game_time * map_data.get("spawn_rate_increase", 0.01)
		spawn_timer = maxf(0.1, rate)
		_spawn_enemy()
	
	# Boss spawn
	if not GameManager.boss_spawned_flag and GameManager.game_time >= boss_timer:
		GameManager.boss_spawned_flag = true
		_spawn_boss()

func _clamp_to_map(pos: Vector2) -> Vector2:
	var half = map_data["size"] / 2
	var margin = 32.0
	pos.x = clampf(pos.x, -half.x + margin, half.x - margin)
	pos.y = clampf(pos.y, -half.y + margin, half.y - margin)
	return pos

func _spawn_enemy():
	var player_pos = Vector2.ZERO
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_pos = players[0].global_position
	
	var angle = randf() * TAU
	var dist = randf_range(400, 600)
	var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * dist
	spawn_pos = _clamp_to_map(spawn_pos)
	
	var enemy_types = map_data.get("enemy_types", ["brainless_basic"])
	var eid = enemy_types[randi() % enemy_types.size()]
	
	var enemy = CharacterBody2D.new()
	enemy.set_script(preload("res://scripts/enemy_base.gd"))
	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)
	enemy.call_deferred("setup", eid, GameManager.difficulty_mult)

func _spawn_boss():
	var player_pos = Vector2.ZERO
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_pos = players[0].global_position
	
	var angle = randf() * TAU
	var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * 500
	spawn_pos = _clamp_to_map(spawn_pos)
	
	var boss_id = map_data.get("boss", "sakura")
	var boss = CharacterBody2D.new()
	boss.set_script(preload("res://scripts/boss.gd"))
	boss.global_position = spawn_pos
	get_tree().current_scene.add_child(boss)
	boss.call_deferred("setup_boss", boss_id, GameManager.difficulty_mult)
	
	# Set boss active state
	GameManager.boss_active = true
	GameManager.boss_ref = boss
	
	# Play boss intro dialogue
	var dialogue_key = "boss_" + boss_id
	if Database.story_dialogues.has(dialogue_key):
		DialogueManager.play_dialogue(dialogue_key)
