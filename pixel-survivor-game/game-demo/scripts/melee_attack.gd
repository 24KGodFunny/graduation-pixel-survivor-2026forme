extends Area2D
## Melee attack - fan-shaped slash for axe weapon

var damage: int = 20
var knockback: float = 80.0
var hit_enemies: Array = []
var lifetime: float = 0.3
var slash_angle: float = 0.0  # Direction angle in radians
var arc_degrees: float = 120.0  # Fan arc in degrees
var slash_radius: float = 60.0

func _ready():
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	# Auto cleanup
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _setup_visual():
	# Create fan-shaped visual using a sprite
	var sprite = Sprite2D.new()
	var img_size = int(slash_radius * 2.5)
	var img = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	var center = float(img_size) / 2.0
	var half_arc = deg_to_rad(arc_degrees / 2.0)
	
	for x in range(img_size):
		for y in range(img_size):
			var cx = float(x) - center
			var cy = float(y) - center
			var dist = sqrt(cx * cx + cy * cy)
			if dist > slash_radius * 0.4 and dist < slash_radius:
				var angle = atan2(cy, cx)
				var diff = abs(wrapf(angle - slash_angle, -PI, PI))
				if diff < half_arc:
					var alpha = 0.7 * (1.0 - (dist - slash_radius * 0.4) / (slash_radius * 0.6))
					alpha *= (1.0 - diff / half_arc)
					img.set_pixel(x, y, Color(0.9, 0.75, 0.2, alpha))
	sprite.texture = ImageTexture.create_from_image(img)
	# 不需要额外旋转，因为像素绘制时已经根据 slash_angle 确定了扇形方向
	sprite.rotation = 0
	add_child(sprite)
	
	# Create collision polygon for the fan shape
	var col = CollisionPolygon2D.new()
	var points = PackedVector2Array()
	var segments = 12
	var half = deg_to_rad(arc_degrees / 2.0)
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var a = slash_angle - half + (half * 2.0) * float(i) / float(segments)
		points.append(Vector2(cos(a), sin(a)) * slash_radius)
	col.polygon = points
	add_child(col)

func setup(dmg: int, kb: float, angle: float, area_scale: float = 1.0):
	damage = dmg
	knockback = kb
	slash_angle = angle
	slash_radius *= area_scale
	arc_degrees = min(120.0 + (area_scale - 1.0) * 30.0, 200.0)
	_setup_visual()

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies") and body not in hit_enemies:
		hit_enemies.append(body)
		AudioManager.play_sfx("res://assets/audio/sfx_hit.wav")
		if body.has_method("take_hit"):
			var kb_dir = (body.global_position - global_position).normalized()
			body.take_hit(damage, kb_dir, knockback)
