extends Area2D

var pickup_type: String = "exp"
var value: int = 1
var magnetized: bool = false
var absorbing: bool = false  # Set to true when boss is defeated, absorb all pickups
var sprite: Sprite2D

func _ready():
	sprite = Sprite2D.new()
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	match pickup_type:
		"exp":
			img.fill(Color(0.2, 0.6, 1.0))
		"coin":
			img.fill(Color(1.0, 0.85, 0.0))
		"heal":
			img.fill(Color(0.2, 1.0, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)
	
	collision_layer = 16
	collision_mask = 0
	
	var magnet_area = Area2D.new()
	magnet_area.collision_layer = 0
	magnet_area.collision_mask = 1
	var mcol = CollisionShape2D.new()
	var mshape = CircleShape2D.new()
	mshape.radius = 100.0
	mcol.shape = mshape
	magnet_area.add_child(mcol)
	add_child(magnet_area)
	magnet_area.body_entered.connect(_on_magnet_entered)

func _on_magnet_entered(body):
	if body.is_in_group("player"):
		magnetized = true

func set_absorbing(_val: bool):
	absorbing = true
	magnetized = true

func force_collect():
	_collect()

func _process(delta):
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if absorbing or magnetized:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var speed = 1200.0 if absorbing else 600.0
			var dir = (players[0].global_position - global_position).normalized()
			position += dir * speed * delta
			if global_position.distance_to(players[0].global_position) < 20:
				_collect()

func _collect():
	match pickup_type:
		"exp":
			GameManager.add_exp(value)
		"coin":
			GameManager.add_coins(value)
		"heal":
			GameManager.heal_player(value)
	queue_free()
