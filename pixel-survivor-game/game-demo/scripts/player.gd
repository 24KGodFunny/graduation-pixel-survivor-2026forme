extends CharacterBody2D

var sprite: Sprite2D
var magnet_area: Area2D
var magnet_shape: CollisionShape2D
var invincible_timer: float = 0.0
var flash_timer: float = 0.0
var facing_right: bool = true
var is_dead: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0
var move_anim_timer: float = 0.0
var move_anim_frame: int = 0
var spawn_finished: bool = false

# 方向枚举
enum Dir { DOWN, UP, RIGHT, LEFT }
var facing_dir: int = Dir.DOWN

func _ready():
	add_to_group("player")
	sprite = Sprite2D.new()
	var tex_path = Database.characters[GameManager.selected_character_id]["sprite"]
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var col = Database.characters[GameManager.selected_character_id]["color"]
		img.fill(col)
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)
	
	magnet_area = Area2D.new()
	magnet_area.collision_layer = 0
	magnet_area.collision_mask = 16
	magnet_shape = CollisionShape2D.new()
	var mshape = CircleShape2D.new()
	mshape.radius = GameManager.player_magnet_range
	magnet_shape.shape = mshape
	magnet_area.add_child(magnet_shape)
	add_child(magnet_area)
	
	collision_layer = 1
	collision_mask = 2 | 4
	
	# 播放出生动画
	_play_spawn_anim()

func _play_spawn_anim():
	# 出生时短暂无敌
	invincible_timer = 0.8
	AnimHelper.play_spawn(self, 0.5, _on_spawn_finished)

func _on_spawn_finished():
	spawn_finished = true

func _physics_process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if is_dead:
		return
	
	# 攻击动画计时
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	
	if invincible_timer > 0:
		invincible_timer -= delta
		flash_timer -= delta
		if flash_timer <= 0:
			flash_timer = 0.1
			sprite.modulate.a = 0.3 if sprite.modulate.a > 0.5 else 1.0
		if invincible_timer <= 0:
			sprite.modulate.a = 1.0
	
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	
	var spd = GameManager.player_speed * GameManager.player_speed_mult
	velocity = input_dir * spd
	move_and_slide()
	
	# 更新朝向和移动动画
	_update_facing(input_dir, delta)
	
	var ms = magnet_shape.shape as CircleShape2D
	ms.radius = GameManager.player_magnet_range
	
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("enemies") and invincible_timer <= 0:
			take_damage(collider.damage if "damage" in collider else 5)

func _update_facing(input_dir: Vector2, delta: float):
	if input_dir.length() < 0.1:
		# 静止时恢复默认帧
		move_anim_timer = 0.0
		move_anim_frame = 0
		sprite.rotation = 0
		sprite.scale = Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
		return
	
	# 根据输入方向判断朝向
	if abs(input_dir.x) > abs(input_dir.y):
		if input_dir.x > 0:
			facing_dir = Dir.RIGHT
			facing_right = true
			sprite.flip_h = false
		else:
			facing_dir = Dir.LEFT
			facing_right = false
			sprite.flip_h = true
	else:
		if input_dir.y > 0:
			facing_dir = Dir.DOWN
		else:
			facing_dir = Dir.UP
	
	# 移动时的微动画效果（上下弹跳）
	move_anim_timer += delta
	if move_anim_timer >= 0.15:
		move_anim_timer = 0.0
		move_anim_frame = (move_anim_frame + 1) % 4
	
	# 根据移动帧应用微缩放模拟行走
	var bounce = sin(move_anim_frame * PI / 2.0) * 0.08
	sprite.scale.x = (1.0 + bounce) * (1.0 if facing_right else -1.0)
	sprite.scale.y = 1.0 - bounce * 0.5
	
	# 根据朝向微调 sprite 倾斜
	match facing_dir:
		Dir.UP:
			sprite.rotation = 0
		Dir.DOWN:
			sprite.rotation = 0
		Dir.RIGHT:
			sprite.rotation = deg_to_rad(5 * sin(move_anim_frame * PI / 2.0))
		Dir.LEFT:
			sprite.rotation = deg_to_rad(-5 * sin(move_anim_frame * PI / 2.0))

func take_damage(amount: float):
	if invincible_timer > 0 or is_dead:
		return
	GameManager.damage_player(amount)
	invincible_timer = 0.5
	flash_timer = 0.0
	
	# 受击闪红效果
	AnimHelper.play_hit_red(self, 0.2)
	# 受击屏幕震动
	AnimHelper.play_screen_shake(self, 3.0, 0.2)
	
	# 播放受击音效
	if AudioManager:
		AudioManager.play_sfx("sfx_player_hit")
	
	# 检查是否死亡
	if GameManager.player_hp <= 0:
		_player_die()

func _player_die():
	if is_dead:
		return
	is_dead = true
	
	# 播放死亡音效
	if AudioManager:
		AudioManager.play_sfx("sfx_death")
	
	# 死亡屏幕震动
	AnimHelper.play_screen_shake(self, 8.0, 0.5)
	
	# 播放死亡动画
	AnimHelper.play_death(self, 1.0, _on_player_death_finished)

func _on_player_death_finished():
	# 通知 GameManager 玩家死亡
	GameManager.lose_game()

## 攻击动画（由武器系统调用）
func play_attack_anim():
	if is_dead:
		return
	is_attacking = true
	attack_timer = 0.2
	AnimHelper.play_attack(self, 0.2)