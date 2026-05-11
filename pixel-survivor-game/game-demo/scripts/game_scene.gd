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
	
	# Boss health bar - use the one already in HUD (CanvasLayer)
	boss_hp_bar = $HUD/BossHealthBar
	
	# Enemy spawner
	var spawner = Node2D.new()
	spawner.set_script(preload("res://scripts/enemy_spawner.gd"))
	add_child(spawner)
	
	# Connect signals
	# 播放战斗BGM（随机选择一首战斗曲目，循环播放）
	if AudioManager:
		var battle_bgms = [
			"res://assets/audio/bgm_battle1.wav",
			"res://assets/audio/bgm_battle2.wav",
			"res://assets/audio/bgm_battle3.wav",
		]
		var chosen_bgm = battle_bgms[randi() % battle_bgms.size()]
		print("[AudioManager] 尝试播放战斗BGM: ", chosen_bgm)
		AudioManager.play_bgm(chosen_bgm)
		if AudioManager.bgm_player.playing:
			print("[AudioManager] 战斗BGM播放成功，正在循环播放")
		else:
			push_warning("[AudioManager] 战斗BGM播放失败: " + chosen_bgm)
	
	GameManager.start_game()
	GameManager.game_over.connect(_on_game_over)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_defeated.connect(_on_boss_defeated)
	GameManager.boss_phase_started.connect(_on_boss_phase_started)
	GameManager.boss_intro_started.connect(_on_boss_intro_started)
	GameManager.boss_teleport_started.connect(_on_boss_teleport_started)

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
	
	# 切换到Boss BGM
	if AudioManager:
		AudioManager.crossfade_bgm("res://assets/audio/bgm_boss.wav", 1.0)
	
	if boss_data:
		boss_hp_bar.show_boss(boss_name, boss_data["max_hp"] * GameManager.difficulty_mult, boss_data["phases"])
	else:
		boss_hp_bar.show_boss(boss_name, 1000, 2)

func _on_boss_phase_started():
	# Show "高危目标即将降临" warning overlay on HUD (screen space)
	var hud = $HUD
	var overlay = ColorRect.new()
	overlay.color = Color(0.8, 0.0, 0.0, 0.3)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.name = "BossWarningOverlay"
	hud.add_child(overlay)
	
	var warning_label = Label.new()
	warning_label.text = "⚠ 高危目标即将降临 ⚠"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	warning_label.add_theme_font_size_override("font_size", 36)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	warning_label.add_theme_constant_override("shadow_offset_x", 3)
	warning_label.add_theme_constant_override("shadow_offset_y", 3)
	overlay.add_child(warning_label)
	
	# Fade out after 2 seconds
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(overlay, "modulate:a", 0.0, 1.0)
	tween.tween_callback(overlay.queue_free)

func _on_boss_intro_started():
	# Show boss portrait / intro display on HUD (screen space)
	var boss_id = Database.maps[GameManager.selected_map_id].get("boss", "sakura")
	var boss_data = Database.bosses.get(boss_id, {})
	var boss_name = boss_data.get("name", "???")
	
	var hud = $HUD
	# Create full-screen boss intro overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.name = "BossIntroOverlay"
	hud.add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	# Boss name
	var name_label = Label.new()
	name_label.text = boss_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 48)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	name_label.add_theme_constant_override("shadow_offset_x", 3)
	name_label.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(name_label)
	
	# "高危目标" subtitle
	var subtitle = Label.new()
	subtitle.text = "— 高危目标 —"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(subtitle)
	
	# Fade out after 3 seconds
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(overlay.queue_free)

func _on_boss_teleport_started(callback: Callable):
	# Black screen transition for player teleport
	var hud = $HUD
	var black_screen = ColorRect.new()
	black_screen.color = Color(0.0, 0.0, 0.0, 0.0)
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_screen.name = "TeleportBlackScreen"
	hud.add_child(black_screen)
	
	var tween = create_tween()
	# Fade in (0 -> 1 alpha) over 0.5s
	tween.tween_property(black_screen, "color:a", 1.0, 0.5)
	# Execute teleport callback while screen is black
	tween.tween_callback(callback)
	# Brief hold
	tween.tween_interval(0.3)
	# Fade out (1 -> 0 alpha) over 0.5s
	tween.tween_property(black_screen, "color:a", 0.0, 0.5)
	# Clean up
	tween.tween_callback(black_screen.queue_free)

func _on_boss_defeated(_boss_id: String):
	boss_hp_bar.hide_bar()
	# Boss defeated - 切回战斗BGM或停止
	if AudioManager:
		AudioManager.stop_bgm()
	# Boss defeated - absorb all pickups first, then victory
	GameManager.absorb_all_pickups()

func _on_game_over(victory: bool):
	if settlement_shown:
		return
	# 如果已经返回主菜单（暂停退出），不显示结算界面
	if GameManager.current_state == GameManager.GameState.MENU:
		return
	settlement_shown = true
	
	# 停止战斗BGM（结算界面会播放自己的BGM）
	if AudioManager:
		AudioManager.stop_bgm()
	
	if victory:
		# Show victory settlement UI
		var victory_ui = preload("res://scripts/victory_settlement_ui.gd").new()
		add_child(victory_ui)
	else:
		# Show defeat UI
		var defeat_ui = preload("res://scripts/game_over_ui.gd").new()
		add_child(defeat_ui)

## Boss竞技场阻挡物配置
## 调整这些参数来改变竞技场大小和阻挡物分布
var arena_radius: float = 350.0        # 竞技场半径（从中心到阻挡物内侧）
var arena_wall_thickness: float = 30.0  # 阻挡物厚度
var arena_wall_height: float = 40.0     # 阻挡物高度（碰撞体尺寸）
var arena_wall_count: int = 16          # 阻挡物数量（越多越圆）
var arena_gap_count: int = 2            # 缺口数量（可选，0=完全封闭）
var arena_gap_size: float = 60.0        # 缺口宽度
var arena_gap_angles: Array = [0.0, 180.0]  # 缺口角度（度，0=正右方）

var _arena_walls: Array = []  # 存储阻挡物引用，方便后续清理

func create_boss_arena():
	# 清除之前的竞技场阻挡物
	clear_boss_arena()
	
	var center = Vector2.ZERO  # Boss竞技场中心（玩家出生点）
	
	for i in range(arena_wall_count):
		var angle = (2.0 * PI * i) / arena_wall_count
		var angle_deg = rad_to_deg(angle)
		
		# 检查是否在缺口范围内
		var is_gap = false
		for gap_angle in arena_gap_angles:
			var diff = abs(angle_deg - gap_angle)
			if diff > 180.0:
				diff = 360.0 - diff
			if diff < arena_gap_size / (2.0 * arena_radius / arena_wall_count) * (360.0 / arena_wall_count):
				is_gap = true
				break
		
		if is_gap:
			continue
		
		# 计算阻挡物位置（在圆周上）
		var wall_pos = center + Vector2(cos(angle), sin(angle)) * arena_radius
		
		var body = StaticBody2D.new()
		body.position = wall_pos
		body.rotation = angle + PI / 2.0  # 朝向圆心
		body.collision_layer = 4  # 墙壁层
		body.collision_mask = 0
		
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		# 弧形近似：计算每段的弧长作为宽度
		var segment_arc = (2.0 * PI * arena_radius) / arena_wall_count
		rect.size = Vector2(segment_arc, arena_wall_thickness)
		col.shape = rect
		body.add_child(col)
		
		# 可视化阻挡物（红色半透明方块）
		var visual = ColorRect.new()
		visual.color = Color(0.6, 0.1, 0.1, 0.7)
		visual.size = rect.size
		visual.position = -rect.size / 2.0
		visual.z_index = -5
		body.add_child(visual)
		
		add_child(body)
		_arena_walls.append(body)

func clear_boss_arena():
	for wall in _arena_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	_arena_walls.clear()

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
