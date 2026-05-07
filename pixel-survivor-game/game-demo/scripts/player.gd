extends CharacterBody2D

var sprite: Sprite2D
var magnet_area: Area2D
var magnet_shape: CollisionShape2D
var invincible_timer: float = 0.0
var flash_timer: float = 0.0
var facing_right: bool = true

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

func _physics_process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
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
	
	if input_dir.x > 0 and not facing_right:
		facing_right = true
		sprite.flip_h = false
	elif input_dir.x < 0 and facing_right:
		facing_right = false
		sprite.flip_h = true
	
	var ms = magnet_shape.shape as CircleShape2D
	ms.radius = GameManager.player_magnet_range
	
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("enemies") and invincible_timer <= 0:
			take_damage(collider.damage if "damage" in collider else 5)

func take_damage(amount: float):
	if invincible_timer > 0:
		return
	GameManager.damage_player(amount)
	invincible_timer = 0.5
	flash_timer = 0.0
