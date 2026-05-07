extends Node2D

var coin_amount: int = 1
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 30.0
var attracted: bool = false
var attract_speed: float = 400.0
var player_ref: Node2D

var area: Area2D
var sprite: Sprite2D

func _ready():
	sprite = Sprite2D.new()
	var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.84, 0.0))
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
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
			GameManager.add_coins(coin_amount)
			queue_free()
			return
	
	global_position += velocity * delta