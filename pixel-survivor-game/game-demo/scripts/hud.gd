extends CanvasLayer

var hp_bar: ProgressBar
var hp_label: Label
var exp_bar: ProgressBar
var exp_label: Label
var time_label: Label
var level_label: Label
var kill_label: Label
var coin_label: Label
var weapon_icons: HBoxContainer
var boss_countdown_label: Label
var portrait_texture: TextureRect
var buff_container: VBoxContainer
var _last_buff_hash: int = 0
var _last_boss_countdown_second: int = -1

func _ready():
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	
	# Main vertical layout: status bar on top, buff list below
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_child(top_hbox)
	
	# --- Character portrait (top-left corner) ---
	portrait_texture = TextureRect.new()
	portrait_texture.custom_minimum_size = Vector2(48, 48)
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_texture.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Load character sprite
	var char_id = GameManager.selected_character_id
	if char_id != "" and Database.characters.has(char_id):
		var sprite_path = Database.characters[char_id].get("sprite", "")
		if sprite_path != "" and ResourceLoader.exists(sprite_path):
			portrait_texture.texture = load(sprite_path)
	# Add border style
	var portrait_bg = PanelContainer.new()
	portrait_bg.custom_minimum_size = Vector2(52, 52)
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	portrait_style.border_color = Color(0.5, 0.7, 1.0)
	portrait_style.set_border_width_all(2)
	portrait_style.set_corner_radius_all(4)
	portrait_style.set_content_margin_all(2)
	portrait_bg.add_theme_stylebox_override("panel", portrait_style)
	portrait_bg.add_child(portrait_texture)
	top_hbox.add_child(portrait_bg)
	
	# --- Left panel: compact semi-transparent info card ---
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	top_hbox.add_child(panel)
	
	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 3)
	panel.add_child(panel_vbox)
	
	# HP Bar with value label
	var hp_container = _create_bar_with_label("HP", Color(0.8, 0.15, 0.15), Color(0.4, 0.05, 0.05))
	hp_bar = hp_container[0]
	hp_label = hp_container[1]
	panel_vbox.add_child(hp_container[2])
	
	# EXP Bar with value label
	var exp_container = _create_bar_with_label("EXP", Color(0.2, 0.5, 1.0), Color(0.05, 0.15, 0.4))
	exp_bar = exp_container[0]
	exp_label = exp_container[1]
	panel_vbox.add_child(exp_container[2])
	
	# Info row: Level, Time, Kills, Coins - compact single column
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 8)
	info_grid.add_theme_constant_override("v_separation", 1)
	panel_vbox.add_child(info_grid)
	
	level_label = Label.new()
	level_label.text = "Lv.1"
	level_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(level_label)
	
	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(time_label)
	
	kill_label = Label.new()
	kill_label.text = "击杀: 0"
	kill_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(kill_label)
	
	coin_label = Label.new()
	coin_label.text = "💰 0"
	coin_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(coin_label)
	
	# Weapon icons
	weapon_icons = HBoxContainer.new()
	weapon_icons.add_theme_constant_override("separation", 3)
	panel_vbox.add_child(weapon_icons)
	
	# --- Buff list (below status panel, left-aligned) ---
	buff_container = VBoxContainer.new()
	buff_container.add_theme_constant_override("separation", 2)
	buff_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	buff_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_child(buff_container)
	
	# --- Center: boss countdown label (hidden by default) ---
	boss_countdown_label = Label.new()
	boss_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	boss_countdown_label.add_theme_font_size_override("font_size", 22)
	boss_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	boss_countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	boss_countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_countdown_label.add_theme_constant_override("shadow_offset_y", 2)
	boss_countdown_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_countdown_label.visible = false
	add_child(boss_countdown_label)
	
	GameManager.player_damaged.connect(_on_player_damaged)
	GameManager.player_healed.connect(_on_player_healed)
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.enemy_killed.connect(_on_enemy_killed)

func _create_bar_with_label(bar_name: String, fg_color: Color, bg_color: Color) -> Array:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	var name_label = Label.new()
	name_label.text = bar_name
	name_label.custom_minimum_size = Vector2(26, 0)
	name_label.add_theme_font_size_override("font_size", 11)
	container.add_child(name_label)
	
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(80, 10)
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	
	# Style the bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fg_color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", fill_style)
	
	container.add_child(bar)
	
	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.text = "100/100"
	container.add_child(value_label)
	
	return [bar, value_label, container]

func _process(_delta):
	if GameManager.current_state == GameManager.GameState.PLAYING:
		# 优化：buff显示只在数据变化时更新，不在每帧重建
		_update_buff_display_if_changed()
		hp_bar.value = float(GameManager.player_hp) / float(GameManager.player_max_hp)
		hp_label.text = "%d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
		
		var exp_needed = Database.get_exp_for_level(GameManager.player_level)
		exp_bar.value = float(GameManager.player_exp) / float(exp_needed)
		exp_label.text = "%d/%d" % [GameManager.player_exp, exp_needed]
		
		coin_label.text = "💰 " + str(GameManager.player_coins)
		
		# 优化：boss倒计时按秒更新，不在每帧更新
		if not GameManager.boss_phase:
			var remaining = GameManager.normal_phase_duration - GameManager.game_time
			var current_second = int(ceil(remaining))
			if remaining > 0:
				boss_countdown_label.visible = true
				if current_second != _last_boss_countdown_second:
					_last_boss_countdown_second = current_second
					if remaining <= 10:
						boss_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
						boss_countdown_label.add_theme_font_size_override("font_size", 26)
						boss_countdown_label.text = "⚠ 警告：高危险目标即将出现 %d秒 ⚠" % current_second
					else:
						boss_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
						boss_countdown_label.add_theme_font_size_override("font_size", 20)
						var mins = int(remaining / 60)
						var secs = int(remaining) % 60
						boss_countdown_label.text = "Boss降临: %02d:%02d" % [mins, secs]
			else:
				boss_countdown_label.visible = false
		else:
			boss_countdown_label.visible = false

func _on_player_damaged(hp, max_hp):
	hp_bar.value = float(hp) / float(max_hp)
	hp_label.text = "%d/%d" % [hp, max_hp]

func _on_player_healed(_amount):
	hp_bar.value = float(GameManager.player_hp) / float(GameManager.player_max_hp)
	hp_label.text = "%d/%d" % [GameManager.player_hp, GameManager.player_max_hp]

func _on_level_up(new_level):
	level_label.text = "Lv." + str(new_level)

func _on_time_updated(_seconds):
	time_label.text = GameManager.get_game_time_string()

func _on_enemy_killed(_pos, _exp_amount):
	kill_label.text = "击杀: " + str(GameManager.kill_count)
	coin_label.text = "💰 " + str(GameManager.player_coins)

func _update_buff_display_if_changed():
	# 计算当前 buff 数据的哈希值，只在变化时重建
	var current_hash = hash([GameManager.equipped_weapons, GameManager.equipped_passives])
	if current_hash == _last_buff_hash:
		return
	_last_buff_hash = current_hash
	_rebuild_buff_display()

func _rebuild_buff_display():
	# 清除旧的 buff 显示
	for child in buff_container.get_children():
		child.queue_free()
	
	# 显示已装备的武器（带图标）
	for w in GameManager.equipped_weapons:
		var weapon_id = w["id"]
		var w_level = w["level"]
		if Database.weapons.has(weapon_id):
			var w_data = Database.weapons[weapon_id]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			buff_container.add_child(row)
			# 图标
			var icon = _create_buff_icon(w_data, Color(0.4, 0.7, 1.0))
			row.add_child(icon)
			# 名称+等级
			var lbl = Label.new()
			lbl.text = "%s Lv.%d" % [w_data["name"], w_level + 1]
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
			row.add_child(lbl)
	
	# 显示已装备的被动道具（带图标）
	for p in GameManager.equipped_passives:
		var passive_id = p["id"]
		var p_level = p["level"]
		if Database.passive_items.has(passive_id):
			var p_data = Database.passive_items[passive_id]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			buff_container.add_child(row)
			# 图标
			var icon = _create_buff_icon(p_data, Color(1.0, 0.7, 0.3))
			row.add_child(icon)
			# 名称+等级
			var lbl = Label.new()
			lbl.text = "%s Lv.%d" % [p_data["name"], p_level + 1]
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
			row.add_child(lbl)

func _create_buff_icon(item_data: Dictionary, fallback_color: Color) -> Control:
	var icon_size = Vector2(18, 18)
	# 尝试加载图标纹理
	var icon_path = item_data.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.custom_minimum_size = icon_size
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return tex_rect
	# 无图标时用彩色方块占位
	var color_rect = ColorRect.new()
	color_rect.color = fallback_color
	color_rect.custom_minimum_size = icon_size
	color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return color_rect
