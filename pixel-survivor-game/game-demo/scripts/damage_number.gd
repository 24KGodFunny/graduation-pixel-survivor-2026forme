extends Node2D
## Floating damage number that rises and fades

var damage: int = 0
var color: Color = Color.WHITE
var is_critical: bool = false
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.8
var timer: float = 0.0
var font_size: int = 14

func _ready():
	velocity = Vector2(randf_range(-30, 30), randf_range(-120, -80))
	if is_critical:
		color = Color(1.0, 0.85, 0.0)
		font_size = 22
		scale = Vector2(1.5, 1.5)
	else:
		font_size = 14

func _process(delta):
	timer += delta
	position += velocity * delta
	velocity.y += 100 * delta  # gravity
	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = clampf(alpha, 0.0, 1.0)
	# Scale down
	if is_critical:
		scale = Vector2(1.5, 1.5).lerp(Vector2(0.8, 0.8), timer / lifetime)
	if timer >= lifetime:
		queue_free()
	queue_redraw()

func _draw():
	var text = str(damage)
	if is_critical:
		text += "!"
	draw_string(ThemeDB.fallback_font, Vector2(-20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
	# Outline
	var outline_color = Color(0, 0, 0, modulate.a * 0.8)
	draw_string(ThemeDB.fallback_font, Vector2(-21, -1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)
	draw_string(ThemeDB.fallback_font, Vector2(-19, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, outline_color)

static func create(parent: Node, pos: Vector2, dmg: int, crit: bool = false) -> Node2D:
	var dn = preload("res://scripts/damage_number.gd").new()
	dn.position = pos
	dn.damage = dmg
	dn.is_critical = crit
	parent.add_child(dn)
	return dn