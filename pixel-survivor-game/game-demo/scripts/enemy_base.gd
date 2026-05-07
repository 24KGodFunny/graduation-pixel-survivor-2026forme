extends CharacterBody2D

var enemy_id: String = "brainless_basic"
var max_hp: int = 10
var current_hp: int = 10
var damage: int = 5
var move_speed: float = 80.0
var exp_reward: int = 1
var armor: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var hp_bar: ProgressBar
var player_ref: Node2D

func _ready():
	add_to_group("enemies")
	sprite = Sprite2D.new()
	add_child(sprite)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)
	
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 1.0
	hp_bar.value = 1.0
	hp_bar.custom_minimum_size = Vector2(30, 4)
	hp_bar.position = Vector2(-15, -20)
	hp_bar.show_percentage = false
	add_child(hp_bar)
	
	collision_layer = 2
	collision_mask = 1 | 4

func setup(p_enemy_id: String, diff_mult: float):
	enemy_id = p_enemy_id
	var data = Database.enemies[enemy_id]
	max_hp = int(data["max_hp"] * diff_mult)
	current_hp = max_hp
	damage = int(data["damage"] * diff_mult)
	move_speed = data["speed"]
	exp_reward = data["exp"]
	armor = data["armor"]
	var tex_path = data["sprite"]
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
		img.fill(data["color"])
		sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if player_ref == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
		else:
			return
	var dir = (player_ref.global_position - global_position).normalized()
	velocity = dir * move_speed + knockback_velocity
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 5.0 * delta)
	move_and_slide()

func take_hit(hit_damage: int, knockback_dir: Vector2, knockback_force: float):
	var actual = maxi(1, hit_damage - armor)
	current_hp -= actual
	GameManager.record_damage_dealt(actual)
	knockback_velocity = knockback_dir * knockback_force
	hp_bar.value = float(current_hp) / float(max_hp)
	if current_hp <= 0:
		die()

func die():
	GameManager.kill_enemy(global_position, exp_reward)
	# Drop coins
	var coin_min: int = 1
	var coin_max: int = 3
	if Database.enemies.has(enemy_id):
		var data = Database.enemies[enemy_id]
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
			coin.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_tree().current_scene.add_child(coin)
	queue_free()
