extends Area2D
## Unified projectile script - supports multiple visual/behavior types

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 10
var pierce: int = 0
var knockback: float = 50.0
var lifetime: float = 5.0
var hit_enemies: Array = []
var proj_type: String = "bullet"  # bullet/orbiting/explosive/bouncing/flame/homing/missile/beam/pulse/puddle/fireroad
var weapon_id: String = ""

# Orbiting specific
var orbit_angle: float = 0.0
var orbit_radius: float = 80.0
var orbit_speed: float = 3.0
var orbit_owner: Node2D = null

# Bouncing specific
var bounce_count: int = 0
var max_bounces: int = 3

# Homing specific
var target_enemy: Node2D = null
var homing_strength: float = 3.0
var _target_search_timer: float = 0.0
var _target_search_interval: float = 0.2  # 每0.2秒搜索一次，而非每帧

# Explosive specific
var exploded: bool = false
var explosion_radius: float = 60.0

# Flame specific
var fade_speed: float = 2.0

# Puddle specific
var tick_timer: float = 0.0
var tick_interval: float = 0.5

# Beam specific
var beam_length: float = 400.0
var beam_angle: float = 0.0

# Pulse specific
var pulse_max_radius: float = 150.0
var pulse_current_radius: float = 0.0

# Fireroad specific
var spawn_interval: float = 0.3
var spawn_timer: float = 0.0

# Visual
var sprite_node: Sprite2D = null
var alpha: float = 1.0
var rotation_speed: float = 0.0

func _ready():
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_setup_visual()

func _setup_visual():
	match proj_type:
		"bullet":
			_setup_bullet_visual()
		"orbiting":
			_setup_orbiting_visual()
		"explosive":
			_setup_explosive_visual()
		"bouncing":
			_setup_bouncing_visual()
		"flame":
			_setup_flame_visual()
		"homing":
			_setup_homing_visual()
		"missile":
			_setup_missile_visual()
		"beam":
			_setup_beam_visual()
		"pulse":
			_setup_pulse_visual()
		"puddle":
			_setup_puddle_visual()
		"fireroad":
			_setup_fireroad_visual()
		_:
			_setup_bullet_visual()

func _setup_bullet_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	# Different colors per weapon
	var color = _get_weapon_color()
	img.fill(color)
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	add_child(col)
	rotation_speed = deg_to_rad(720.0)

func _setup_orbiting_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Draw a diamond/talisman shape
	for x in range(12):
		for y in range(12):
			var cx = x - 5.5
			var cy = y - 5.5
			if abs(cx) + abs(cy) <= 5.0:
				img.set_pixel(x, y, color)
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func _setup_explosive_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Draw a circle
	for x in range(10):
		for y in range(10):
			var cx = x - 4.5
			var cy = y - 4.5
			if cx * cx + cy * cy <= 20.0:
				img.set_pixel(x, y, color)
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5.0
	col.shape = shape
	add_child(col)
	rotation_speed = deg_to_rad(360.0)

func _setup_bouncing_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Draw a filled circle (ball)
	for x in range(10):
		for y in range(10):
			var cx = x - 4.5
			var cy = y - 4.5
			if cx * cx + cy * cy <= 20.0:
				img.set_pixel(x, y, color)
			elif cx * cx + cy * cy <= 22.0:
				img.set_pixel(x, y, color.darkened(0.3))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5.0
	col.shape = shape
	add_child(col)

func _setup_flame_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	# Flame gradient: orange core, red outer
	for x in range(12):
		for y in range(12):
			var cx = x - 5.5
			var cy = y - 5.5
			var dist = sqrt(cx * cx + cy * cy)
			if dist < 3.0:
				img.set_pixel(x, y, Color(1.0, 0.9, 0.2, 0.9))
			elif dist < 5.0:
				img.set_pixel(x, y, Color(1.0, 0.4, 0.0, 0.7))
			elif dist < 6.0:
				img.set_pixel(x, y, Color(0.8, 0.1, 0.0, 0.4))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func _setup_homing_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Drone shape - small cross
	for x in range(14):
		for y in range(14):
			var cx = x - 6.5
			var cy = y - 6.5
			if (abs(cx) <= 1.5 and abs(cy) <= 5.0) or (abs(cy) <= 1.5 and abs(cx) <= 5.0):
				img.set_pixel(x, y, color)
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	add_child(col)

func _setup_missile_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(16, 8, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Missile shape - elongated
	for x in range(16):
		for y in range(8):
			var cx = x
			var cy = y - 3.5
			# Body
			if x >= 2 and x <= 12 and abs(cy) <= 2.5:
				img.set_pixel(x, y, color)
			# Nose
			elif x >= 12 and x <= 15 and abs(cy) <= (15.0 - x) * 0.8:
				img.set_pixel(x, y, color.lightened(0.3))
			# Tail fins
			elif x >= 0 and x <= 3 and abs(cy) <= 3.5:
				img.set_pixel(x, y, color.darkened(0.3))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func _setup_beam_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(8, 64, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Beam - glowing line
	for x in range(8):
		for y in range(64):
			var cx = x - 3.5
			if abs(cx) <= 1.0:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.9))
			elif abs(cx) <= 2.5:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.3))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 64)
	col.shape = shape
	add_child(col)

func _setup_pulse_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Ring shape
	for x in range(64):
		for y in range(64):
			var cx = x - 31.5
			var cy = y - 31.5
			var dist = sqrt(cx * cx + cy * cy)
			if dist >= 26.0 and dist <= 31.0:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.7))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0
	col.shape = shape
	add_child(col)

func _setup_puddle_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = _get_weapon_color()
	# Puddle - filled circle with gradient
	for x in range(32):
		for y in range(32):
			var cx = x - 15.5
			var cy = y - 15.5
			var dist = sqrt(cx * cx + cy * cy)
			if dist < 14.0:
				var a = 0.6 * (1.0 - dist / 14.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, a + 0.2))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

func _setup_fireroad_visual():
	sprite_node = Sprite2D.new()
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	# Small fire patch
	for x in range(16):
		for y in range(16):
			var cx = x - 7.5
			var cy = y - 7.5
			var dist = sqrt(cx * cx + cy * cy)
			if dist < 5.0:
				img.set_pixel(x, y, Color(1.0, 0.5, 0.0, 0.6))
			elif dist < 7.0:
				img.set_pixel(x, y, Color(0.8, 0.2, 0.0, 0.3))
	sprite_node.texture = ImageTexture.create_from_image(img)
	add_child(sprite_node)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)

func _get_weapon_color() -> Color:
	match weapon_id:
		"pistol": return Color(1.0, 0.9, 0.3)  # Yellow
		"sniper": return Color(0.3, 0.8, 1.0)  # Cyan
		"axe": return Color(0.8, 0.3, 0.1)  # Orange-red
		"grenade": return Color(0.3, 0.6, 0.2)  # Green
		"baseball": return Color(1.0, 0.85, 0.6)  # Cream
		"flamethrower": return Color(1.0, 0.4, 0.0)  # Orange
		"drone": return Color(0.4, 0.9, 1.0)  # Light blue
		"missile": return Color(0.7, 0.7, 0.7)  # Gray
		"talisman": return Color(0.9, 0.8, 0.2)  # Gold
		"dagger": return Color(0.8, 0.8, 0.9)  # Silver
		"orbital": return Color(0.3, 0.5, 1.0)  # Blue
		"pulse": return Color(0.6, 0.2, 0.9)  # Purple
		"matrix": return Color(0.2, 0.9, 0.5)  # Green
		"star": return Color(1.0, 0.9, 0.2)  # Yellow
		"holywater": return Color(0.3, 0.6, 1.0)  # Blue
		"fireroad": return Color(1.0, 0.3, 0.0)  # Red-orange
		_: return Color(1.0, 1.0, 0.3)

func setup(dir: Vector2, spd: float, dmg: int, p_pierce: int, kb: float, area_scale: float = 1.0):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	pierce = p_pierce
	knockback = kb
	scale = Vector2(area_scale, area_scale)

func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	match proj_type:
		"bullet":
			_process_bullet(delta)
		"orbiting":
			_process_orbiting(delta)
		"explosive":
			_process_explosive(delta)
		"bouncing":
			_process_bouncing(delta)
		"flame":
			_process_flame(delta)
		"homing":
			_process_homing(delta)
		"missile":
			_process_missile(delta)
		"beam":
			_process_beam(delta)
		"pulse":
			_process_pulse(delta)
		"puddle":
			_process_puddle(delta)
		"fireroad":
			_process_fireroad(delta)
		_:
			_process_bullet(delta)

func _process_bullet(delta):
	position += direction * speed * delta
	rotation += rotation_speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _process_orbiting(delta):
	if orbit_owner == null or not is_instance_valid(orbit_owner):
		queue_free()
		return
	orbit_angle += orbit_speed * delta
	position = orbit_owner.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	rotation += deg_to_rad(360.0) * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _process_explosive(delta):
	if not exploded:
		position += direction * speed * delta
		rotation += rotation_speed * delta
		lifetime -= delta
		if lifetime <= 0:
			_explode()

func _explode():
	if exploded:
		return
	exploded = true
	# Play explosion sound
	AudioManager.play_sfx("res://assets/audio/sfx_explosion.wav")
	# Damage all enemies in explosion radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.global_position.distance_to(global_position) <= explosion_radius * scale.x:
			if enemy.has_method("take_hit"):
				var kb_dir = (enemy.global_position - global_position).normalized()
				enemy.take_hit(damage, kb_dir, knockback)
	# Visual flash
	if sprite_node:
		var tween = create_tween()
		tween.tween_property(sprite_node, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _process_bouncing(delta):
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _process_flame(delta):
	position += direction * speed * delta
	alpha -= fade_speed * delta
	if sprite_node:
		sprite_node.modulate.a = max(alpha, 0.0)
	lifetime -= delta
	if lifetime <= 0 or alpha <= 0:
		queue_free()

func _process_homing(delta):
	# 优化：定时搜索最近敌人，而非每帧搜索
	_target_search_timer -= delta
	if (target_enemy == null or not is_instance_valid(target_enemy)) and _target_search_timer <= 0:
		_target_search_timer = _target_search_interval
		_find_nearest_enemy()
	
	if target_enemy and is_instance_valid(target_enemy):
		var to_target = (target_enemy.global_position - global_position).normalized()
		direction = direction.lerp(to_target, homing_strength * delta).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		var nearest_dist = INF
		for e in enemies:
			var d = global_position.distance_squared_to(e.global_position)
			if d < nearest_dist:
				nearest_dist = d
				target_enemy = e

func _process_missile(delta):
	# 优化：定时搜索最近敌人，而非每帧搜索
	_target_search_timer -= delta
	if (target_enemy == null or not is_instance_valid(target_enemy)) and _target_search_timer <= 0:
		_target_search_timer = _target_search_interval
		_find_nearest_enemy()
	
	if target_enemy and is_instance_valid(target_enemy):
		var to_target = (target_enemy.global_position - global_position).normalized()
		direction = direction.lerp(to_target, 2.0 * delta).normalized()
	
	position += direction * speed * delta
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0:
		_explode()

func _process_beam(delta):
	# Beam stays in place, damages over time
	lifetime -= delta
	if sprite_node:
		sprite_node.modulate.a = min(lifetime * 3.0, 1.0)
	if lifetime <= 0:
		queue_free()

func _process_pulse(delta):
	# Expand ring
	pulse_current_radius += (pulse_max_radius / 0.3) * delta
	if sprite_node:
		sprite_node.scale = Vector2(pulse_current_radius / 30.0, pulse_current_radius / 30.0)
	var col_node = get_node_or_null("CollisionShape2D")
	if col_node:
		col_node.scale = Vector2(pulse_current_radius / 30.0, pulse_current_radius / 30.0)
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _process_puddle(delta):
	# Stationary puddle, ticks damage
	tick_timer += delta
	lifetime -= delta
	if sprite_node:
		sprite_node.modulate.a = min(lifetime / 1.0, 0.7)
	if lifetime <= 0:
		queue_free()

func _process_fireroad(delta):
	# Stationary fire, fades out
	alpha -= (1.0 / lifetime) * delta if lifetime > 0 else delta
	if sprite_node:
		sprite_node.modulate.a = max(alpha, 0.0)
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies") and body not in hit_enemies:
		hit_enemies.append(body)
		# Play hit sound
		AudioManager.play_sfx("res://assets/audio/sfx_hit.wav")
		if body.has_method("take_hit"):
			body.take_hit(damage, direction, knockback)
		
		# Bouncing: change direction on hit
		if proj_type == "bouncing":
			bounce_count += 1
			if bounce_count >= max_bounces:
				pierce -= 1
			else:
				# Find next target
				var enemies = get_tree().get_nodes_in_group("enemies")
				var next_target = null
				var min_dist = INF
				for e in enemies:
					if e not in hit_enemies:
						var d = global_position.distance_squared_to(e.global_position)
						if d < min_dist:
							min_dist = d
							next_target = e
				if next_target:
					direction = (next_target.global_position - global_position).normalized()
				else:
					direction = direction.rotated(deg_to_rad(randf_range(120, 240)))
		else:
			pierce -= 1
		
		if pierce < 0:
			if proj_type == "explosive":
				_explode()
			else:
				queue_free()