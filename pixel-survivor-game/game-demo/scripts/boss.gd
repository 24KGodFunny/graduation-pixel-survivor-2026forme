extends "res://scripts/enemy_base.gd"

var boss_id: String = "sakura"
var phase: int = 1
var max_phases: int = 2
var attack_timer: float = 3.0
var phase_thresholds: Array[float] = []

func setup_boss(p_boss_id: String, diff_mult: float):
	boss_id = p_boss_id
	var data = Database.bosses[boss_id]
	enemy_id = boss_id
	max_hp = int(data["max_hp"] * diff_mult)
	current_hp = max_hp
	damage = int(data["damage"] * diff_mult)
	move_speed = data["speed"]
	exp_reward = data["exp"]
	armor = data["armor"]
	max_phases = data["phases"]
	for i in range(max_phases):
		phase_thresholds.append(1.0 - float(i + 1) / max_phases)
	var tex_path = data["sprite"]
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(data["color"])
		sprite.texture = ImageTexture.create_from_image(img)
	sprite.scale = Vector2(2.0, 2.0)
	GameManager.boss_spawned.emit(data["name"])

## Boss 使用更隆重的出生动画
func _play_spawn_anim():
	hp_bar.visible = false
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	
	AnimHelper.play_boss_spawn(self, 1.0, _on_spawn_finished)

func _physics_process(delta):
	super._physics_process(delta)
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if is_dying or not spawn_finished:
		return
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = 3.0 / phase
		_boss_attack()

func _boss_attack():
	# 攻击动画脉冲
	AnimHelper.play_attack(self, 0.3)

func take_hit(hit_damage: int, knockback_dir: Vector2, knockback_force: float):
	if is_dying:
		return
	var actual = maxi(1, hit_damage - armor)
	GameManager.record_damage_dealt(actual)
	super.take_hit(hit_damage, knockback_dir, knockback_force * 0.3)
	if current_hp <= 0:
		return
	var hp_ratio = float(current_hp) / float(max_hp)
	for i in range(phase - 1, max_phases - 1):
		if hp_ratio <= phase_thresholds[i]:
			phase = i + 2
			armor += 2
			damage += 5
			move_speed += 20
			# 阶段转换时播放屏幕震动
			AnimHelper.play_screen_shake(self, 8.0, 0.4)

func die():
	if is_dying:
		return
	is_dying = true
	
	# 播放Boss死亡音效
	if AudioManager:
		AudioManager.play_sfx("sfx_explosion")
	
	# 生成大量死亡粒子
	var boss_color = Color.WHITE
	if Database.bosses.has(boss_id):
		boss_color = Database.bosses[boss_id].get("color", Color.WHITE)
	AnimHelper.spawn_death_particles(self, boss_color, 16)
	
	# 屏幕震动
	AnimHelper.play_screen_shake(self, 12.0, 0.8)
	
	# 隐藏血条
	hp_bar.visible = false
	
	# 播放Boss死亡动画
	AnimHelper.play_boss_death(self, 1.5, _on_boss_death_finished)

func _on_boss_death_finished():
	GameManager.boss_active = false
	GameManager.boss_ref = null
	GameManager.boss_defeated.emit(boss_id)
	GameManager.kill_enemy(global_position, exp_reward)
	# Drop coins (boss drops more, scattered widely)
	var coin_min: int = 50
	var coin_max: int = 80
	if Database.bosses.has(boss_id):
		var data = Database.bosses[boss_id]
		if data.has("coin_min"):
			coin_min = data["coin_min"]
		if data.has("coin_max"):
			coin_max = data["coin_max"]
	var coin_count = randi_range(coin_min, coin_max)
	if coin_count > 0:
		var coin_scene = preload("res://scripts/coin_pickup.gd")
		for i in range(coin_count):
			var coin = Node2D.new()
			coin.set_script(coin_scene)
			coin.coin_amount = 1
			coin.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			get_tree().current_scene.add_child(coin)
	# Victory is now handled by game_scene.gd -> absorb_all_pickups -> win_game
	# No direct win_game() call here
	queue_free()
