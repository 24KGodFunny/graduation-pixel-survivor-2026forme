extends Node2D

var camera: Camera2D
var player: CharacterBody2D
var bg_color_rect: ColorRect
var boss_hp_bar: Control
var settlement_shown: bool = false
var map_size: Vector2

func _ready():
	camera = $Camera2D
	player = $Player
	
	# Background
	var map_data = Database.maps[GameManager.selected_map_id]
	map_size = map_data["size"]
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = map_data["bg_color"]
	bg_color_rect.size = map_size
	bg_color_rect.position = -map_size / 2
	bg_color_rect.z_index = -10
	add_child(bg_color_rect)
	
	# TileMapLayer for visual tile grid
	var tile_layer = TileMapLayer.new()
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(64, 64)
	var source = TileSetAtlasSource.new()
	var tile_tex_path = map_data.get("tile", "")
	if tile_tex_path != "" and ResourceLoader.exists(tile_tex_path):
		source.texture = load(tile_tex_path)
		source.texture_region_size = Vector2i(64, 64)
		# Create a single tile at (0,0)
		source.create_tile(Vector2i(0, 0))
	else:
		# Fallback: create a colored tile
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var col = map_data["bg_color"]
		img.fill(Color(col.r * 0.9, col.g * 0.9, col.b * 0.9))
		source.texture = ImageTexture.create_from_image(img)
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)
	tile_layer.tile_set = tileset
	tile_layer.z_index = -9
	add_child(tile_layer)
	
	# Fill the map area with tiles
	var tile_px = 64
	var cols = int(map_size.x / tile_px) + 1
	var rows = int(map_size.y / tile_px) + 1
	for x in range(cols):
		for y in range(rows):
			var cell = Vector2i(x - int(cols / 2.0), y - int(rows / 2.0))
			tile_layer.set_cell(cell, 0, Vector2i(0, 0))
	
	# Boundary walls (StaticBody2D) - 4 sides
	_create_boundary_walls()
	
	# Boss health bar
	boss_hp_bar = preload("res://scripts/boss_health_bar.gd").new()
	add_child(boss_hp_bar)
	
	# Enemy spawner
	var spawner = Node2D.new()
	spawner.set_script(preload("res://scripts/enemy_spawner.gd"))
	add_child(spawner)
	
	# Connect signals
	GameManager.start_game()
	GameManager.game_over.connect(_on_game_over)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_defeated.connect(_on_boss_defeated)

func _process(_delta):
	if GameManager.current_state == GameManager.GameState.PLAYING:
		if player:
			camera.global_position = player.global_position
		
		# Update boss health bar
		if GameManager.boss_active and GameManager.boss_ref and is_instance_valid(GameManager.boss_ref):
			boss_hp_bar.current_hp = GameManager.boss_ref.current_hp
			boss_hp_bar.max_hp = GameManager.boss_ref.max_hp
			boss_hp_bar.phase = GameManager.boss_ref.phase
			boss_hp_bar.max_phases = GameManager.boss_ref.max_phases

func _on_boss_spawned(boss_name: String):
	var boss_data = null
	var boss_id = ""
	# Find the boss data from the map
	var map_data = Database.maps[GameManager.selected_map_id]
	boss_id = map_data.get("boss", "sakura")
	if Database.bosses.has(boss_id):
		boss_data = Database.bosses[boss_id]
	
	if boss_data:
		boss_hp_bar.show_boss(boss_name, boss_data["max_hp"] * GameManager.difficulty_mult, boss_data["phases"])
	else:
		boss_hp_bar.show_boss(boss_name, 1000, 2)

func _on_boss_defeated(_boss_id: String):
	boss_hp_bar.hide_bar()

func _on_game_over(victory: bool):
	if settlement_shown:
		return
	settlement_shown = true
	
	if victory:
		# Show victory settlement UI
		var victory_ui = preload("res://scripts/victory_settlement_ui.gd").new()
		add_child(victory_ui)
	else:
		# Show defeat UI
		var defeat_ui = preload("res://scripts/game_over_ui.gd").new()
		add_child(defeat_ui)

func _create_boundary_walls():
	var half = map_size / 2
	var wall_thickness = 50.0
	# collision_layer = 4 (wall layer), player collision_mask already includes 4
	var sides = [
		# top wall
		{"pos": Vector2(0, -half.y - wall_thickness / 2), "size": Vector2(map_size.x + wall_thickness * 2, wall_thickness)},
		# bottom wall
		{"pos": Vector2(0, half.y + wall_thickness / 2), "size": Vector2(map_size.x + wall_thickness * 2, wall_thickness)},
		# left wall
		{"pos": Vector2(-half.x - wall_thickness / 2, 0), "size": Vector2(wall_thickness, map_size.y)},
		# right wall
		{"pos": Vector2(half.x + wall_thickness / 2, 0), "size": Vector2(wall_thickness, map_size.y)},
	]
	for side in sides:
		var body = StaticBody2D.new()
		body.position = side["pos"]
		body.collision_layer = 4
		body.collision_mask = 0
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = side["size"]
		col.shape = rect
		body.add_child(col)
		add_child(body)
