extends Node2D

var coin_amount: int = 1
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 20.0
var attracted: bool = false
var attract_speed: float = 400.0
var player_ref: Node2D

var area: Area2D
var sprite: Sprite2D
var amount_label: Label

# 共享纹理缓存，避免每个金币都创建Image
static var _cached_texture: ImageTexture = null

func _get_coin_texture() -> ImageTexture:
	if _cached_texture == null:
		var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.84, 0.0))
		_cached_texture = ImageTexture.create_from_image(img)
	return _cached_texture

func _ready():
	add_to_group("coins")
	
	sprite = Sprite2D.new()
	sprite.texture = _get_coin_texture()
	add_child(sprite)
	
	# 当金币数量 > 1 时显示数字
	if coin_amount > 1:
		amount_label = Label.new()
		amount_label.text = str(coin_amount)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount_label.position = Vector2(-8, -14)
		amount_label.add_theme_font_size_override("font_size", 8)
		amount_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(amount_label)
	
	area = Area2D.new()
	area.collision_layer = 16
	area.collision_mask = 0
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	area.add_child(col)
	call_deferred("add_child", area)
	
	# Random scatter velocity
	var angle = randf() * TAU
	var speed = randf_range(80.0, 160.0)
	velocity = Vector2(cos(angle), sin(angle)) * speed

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	# 闪烁提示即将消失
	if lifetime < 5.0:
		sprite.visible = int(lifetime * 4.0) % 2 == 0
	
	# Slow down scatter velocity
	velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)
	
	# Float animation
	sprite.position.y = sin(Time.get_ticks_msec() * 0.005 + get_instance_id()) * 2.0
	
	# Check for player magnet
	if not attracted:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			var dist = global_position.distance_to(player_ref.global_position)
			if dist < GameManager.player_magnet_range:
				attracted = true
	
	# Move towards player when attracted
	if attracted and player_ref and is_instance_valid(player_ref):
		var dir = (player_ref.global_position - global_position).normalized()
		attract_speed += 600.0 * delta
		velocity = dir * attract_speed
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 15.0:
			AudioManager.play_sfx_throttled("res://assets/audio/sfx_coin.wav", 0.08, -8.0)
			GameManager.add_coins(coin_amount)
			queue_free()
			return
	
	global_position += velocity * delta