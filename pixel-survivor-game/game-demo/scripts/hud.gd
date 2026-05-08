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

func _ready():
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(top_hbox)
	
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
		hp_bar.value = float(GameManager.player_hp) / float(GameManager.player_max_hp)
		hp_label.text = "%d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
		
		var exp_needed = Database.get_exp_for_level(GameManager.player_level)
		exp_bar.value = float(GameManager.player_exp) / float(exp_needed)
		exp_label.text = "%d/%d" % [GameManager.player_exp, exp_needed]
		
		coin_label.text = "💰 " + str(GameManager.player_coins)
		
		# Update boss countdown - always visible during normal phase
		if not GameManager.boss_phase:
			var remaining = GameManager.normal_phase_duration - GameManager.game_time
			if remaining > 0:
				boss_countdown_label.visible = true
				if remaining <= 10:
					boss_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
					boss_countdown_label.add_theme_font_size_override("font_size", 26)
					boss_countdown_label.text = "⚠ 警告：高危险目标即将出现 %d秒 ⚠" % int(ceil(remaining))
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