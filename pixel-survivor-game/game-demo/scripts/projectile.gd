extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 10
var pierce: int = 0
var knockback: float = 50.0
var lifetime: float = 5.0
var hit_enemies: Array = []

func _ready():
	var sprite := Sprite2D.new()
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 0.3))
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	add_child(col)
	
	collision_layer = 4
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)

func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func setup(dir: Vector2, spd: float, dmg: int, p_pierce: int, kb: float, area_scale: float = 1.0):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	pierce = p_pierce
	knockback = kb
	scale = Vector2(area_scale, area_scale)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies") and body not in hit_enemies:
		hit_enemies.append(body)
		if body.has_method("take_hit"):
			body.take_hit(damage, direction, knockback)
		pierce -= 1
		if pierce < 0:
			queue_free()
