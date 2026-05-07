extends Control
## Minimap - shows player, enemies, pickups, and boss on a small radar

var map_size: Vector2 = Vector2(4000, 4000)
var radar_range: float = 800.0
var radar_size: float = 120.0
var center_offset: Vector2 = Vector2.ZERO

var player_pos: Vector2 = Vector2.ZERO
var enemy_positions: Array[Vector2] = []
var pickup_positions: Array[Vector2] = []
var boss_pos: Vector2 = Vector2.ZERO
var has_boss: bool = false

func _ready():
	custom_minimum_size = Vector2(radar_size + 4, radar_size + 4)
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = -(radar_size + 14)
	offset_top = 10
	offset_right = -10
	offset_bottom = radar_size + 14

func _process(_delta):
	# Gather positions from game
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_pos = player.global_position
	
	enemy_positions.clear()
	pickup_positions.clear()
	has_boss = false
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var rel = enemy.global_position - player_pos
		if rel.length() < radar_range:
			enemy_positions.append(rel)
		if enemy.is_in_group("boss"):
			boss_pos = rel
			has_boss = true
	
	for pickup in get_tree().get_nodes_in_group("pickups"):
		var rel = pickup.global_position - player_pos
		if rel.length() < radar_range:
			pickup_positions.append(rel)
	
	queue_redraw()

func _draw():
	var center = Vector2(radar_size / 2.0 + 2, radar_size / 2.0 + 2)
	var half = radar_size / 2.0
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(radar_size + 4, radar_size + 4)), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(Vector2(2, 2), Vector2(radar_size, radar_size)), Color(0.1, 0.1, 0.15, 0.8))
	
	# Grid
	var grid_color = Color(0.2, 0.3, 0.4, 0.3)
	for i in range(1, 4):
		var offset = radar_size * i / 4.0
		draw_line(Vector2(2 + offset, 2), Vector2(2 + offset, 2 + radar_size), grid_color, 1.0)
		draw_line(Vector2(2, 2 + offset), Vector2(2 + radar_size, 2 + offset), grid_color, 1.0)
	
	# Range circle
	draw_arc(center, half - 2, 0, TAU, 32, Color(0.3, 0.5, 0.7, 0.4), 1.0)
	
	# Pickups (small green dots)
	for p in pickup_positions:
		var screen_pos = center + (p / radar_range) * half
		if screen_pos.distance_to(center) < half:
			draw_circle(screen_pos, 1.5, Color(0.2, 1.0, 0.2, 0.6))
	
	# Enemies (red dots)
	for e in enemy_positions:
		var screen_pos = center + (e / radar_range) * half
		if screen_pos.distance_to(center) < half:
			draw_circle(screen_pos, 2.0, Color(1.0, 0.3, 0.3, 0.8))
	
	# Boss (large pulsing red dot)
	if has_boss:
		var screen_pos = center + (boss_pos / radar_range) * half
		if screen_pos.distance_to(center) < half:
			var pulse = sin(Time.get_ticks_msec() * 0.005) * 0.3 + 0.7
			draw_circle(screen_pos, 4.0, Color(1.0, 0.1, 0.1, pulse))
			draw_arc(screen_pos, 6.0, 0, TAU, 16, Color(1.0, 0.2, 0.2, pulse * 0.5), 1.5)
	
	# Player (white triangle at center)
	var points = PackedVector2Array([
		center + Vector2(0, -5),
		center + Vector2(-4, 4),
		center + Vector2(4, 4),
	])
	draw_colored_polygon(points, Color(0.5, 1.0, 0.8))
	
	# Border
	draw_rect(Rect2(Vector2.ZERO, Vector2(radar_size + 4, radar_size + 4)), Color(0.4, 0.6, 0.8, 0.6), false, 2.0)