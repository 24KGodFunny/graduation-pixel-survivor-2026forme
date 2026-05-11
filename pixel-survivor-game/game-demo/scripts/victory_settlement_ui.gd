extends CanvasLayer
## Victory settlement UI - shows battle statistics after defeating the boss

var bg_panel: PanelContainer
var title_label: Label
var stats_container: VBoxContainer
var buttons_container: HBoxContainer
var animation_done: bool = false
var stats_revealed: int = 0
var reveal_timer: float = 0.0
var stat_items: Array[Dictionary] = []
var tween: Tween

func _ready():
	layer = 100
	# 播放胜利BGM
	if AudioManager:
		AudioManager.play_bgm("res://assets/audio/bgm_victory.wav")
	_build_ui()
	_populate_stats()
	_start_reveal_animation()

func _build_ui():
	# Dark overlay background
	bg_panel = PanelContainer.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	bg_panel.add_theme_stylebox_override("panel", style)
	add_child(bg_panel)
	
	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_child(center)
	
	# Main panel
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(500, 450)
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.08, 0.08, 0.15, 0.95)
	main_style.border_color = Color(0.9, 0.75, 0.2, 1.0)
	main_style.border_width_left = 3
	main_style.border_width_right = 3
	main_style.border_width_top = 3
	main_style.border_width_bottom = 3
	main_style.corner_radius_top_left = 12
	main_style.corner_radius_top_right = 12
	main_style.corner_radius_bottom_left = 12
	main_style.corner_radius_bottom_right = 12
	main_style.content_margin_left = 30
	main_style.content_margin_right = 30
	main_style.content_margin_top = 20
	main_style.content_margin_bottom = 20
	main_panel.add_theme_stylebox_override("panel", main_style)
	center.add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)
	
	# Title - VICTORY
	title_label = Label.new()
	title_label.text = "✦ 战 斗 胜 利 ✦"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Boss已被击败！"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(subtitle)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	vbox.add_child(sep)
	
	# Stats container
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Buttons
	buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	buttons_container.visible = false
	vbox.add_child(buttons_container)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "确认"
	confirm_btn.custom_minimum_size = Vector2(180, 45)
	confirm_btn.pressed.connect(_on_return_menu)
	buttons_container.add_child(confirm_btn)

func _add_stat_row(label_text: String, value_text: String, color: Color = Color.WHITE) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 18)
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val)
	
	hbox.visible = false
	stats_container.add_child(hbox)
	return hbox

func _populate_stats():
	var time_str = GameManager.get_game_time_string()
	var char_data = Database.characters[GameManager.selected_character_id]
	var map_data = Database.maps[GameManager.selected_map_id]
	
	# Build stat rows (hidden initially, revealed one by one)
	_add_stat_row("通关地图", map_data["name"], Color(0.6, 0.85, 1.0))
	_add_stat_row("使用角色", char_data["name"], Color(1.0, 0.7, 0.9))
	_add_stat_row("通关时间", time_str, Color(0.7, 1.0, 0.7))
	_add_stat_row("角色等级", "Lv." + str(GameManager.player_level), Color(1.0, 0.9, 0.5))
	_add_stat_row("击杀数", str(GameManager.kill_count), Color(1.0, 0.6, 0.6))
	_add_stat_row("造成伤害", _format_number(GameManager.total_damage_dealt), Color(1.0, 0.5, 0.3))
	_add_stat_row("承受伤害", _format_number(GameManager.damage_taken), Color(0.8, 0.4, 0.4))
	_add_stat_row("获得金币", str(GameManager.coins_collected), Color(1.0, 0.85, 0.3))
	_add_stat_row("装备武器", _get_weapon_list_str(), Color(0.7, 0.9, 1.0))
	
	# Rating
	var rating = _calculate_rating()
	_add_stat_row("评价", rating["text"], rating["color"])

func _format_number(n) -> String:
	if n is float:
		if n >= 10000:
			return "%.1fK" % (n / 1000.0)
		return "%.0f" % n
	if n >= 10000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)

func _get_weapon_list_str() -> String:
	var names := []
	for w in GameManager.equipped_weapons:
		if Database.weapons.has(w["id"]):
			names.append(Database.weapons[w["id"]]["name"] + " Lv." + str(w["level"] + 1))
	if names.is_empty():
		return "无"
	return ", ".join(names)

func _calculate_rating() -> Dictionary:
	var score = 0
	# Time bonus (faster = better)
	var time_ratio = GameManager.game_time / GameManager.game_time_limit
	if time_ratio < 0.5:
		score += 3
	elif time_ratio < 0.7:
		score += 2
	else:
		score += 1
	# Kill bonus
	if GameManager.kill_count >= 500:
		score += 3
	elif GameManager.kill_count >= 200:
		score += 2
	else:
		score += 1
	# Level bonus
	if GameManager.player_level >= 30:
		score += 3
	elif GameManager.player_level >= 15:
		score += 2
	else:
		score += 1
	# Damage taken (less = better)
	if GameManager.damage_taken < 100:
		score += 3
	elif GameManager.damage_taken < 300:
		score += 2
	else:
		score += 1
	
	if score >= 11:
		return {"text": "S 传说级", "color": Color(1.0, 0.85, 0.0)}
	elif score >= 9:
		return {"text": "A 卓越", "color": Color(1.0, 0.5, 0.2)}
	elif score >= 7:
		return {"text": "B 优秀", "color": Color(0.4, 0.8, 1.0)}
	elif score >= 5:
		return {"text": "C 良好", "color": Color(0.5, 1.0, 0.5)}
	else:
		return {"text": "D 合格", "color": Color(0.7, 0.7, 0.7)}

func _start_reveal_animation():
	# Reveal stats one by one with a timer
	reveal_timer = 0.3

func _process(delta):
	if animation_done:
		return
	
	reveal_timer -= delta
	if reveal_timer <= 0:
		var children = stats_container.get_children()
		if stats_revealed < children.size():
			children[stats_revealed].visible = true
			stats_revealed += 1
			reveal_timer = 0.25
		else:
			animation_done = true
			buttons_container.visible = true

func _on_return_menu():
	# === 通关结算：保存进度到存档 ===
	var map_id = GameManager.selected_map_id
	
	# 1. 添加本局获得的金币
	if GameManager.coins_collected > 0:
		SaveManager.add_coins(GameManager.coins_collected)
	
	# 2. 标记当前地图为已通关
	if not SaveManager.is_map_completed(map_id):
		SaveManager.complete_map(map_id)
	
	# 3. 检查是否有新地图需要解锁（当前地图是某个地图的前置条件）
	for m_id in Database.maps:
		var m_data = Database.maps[m_id]
		if m_data.get("unlock_prerequisite", "") == map_id:
			if not SaveManager.is_map_unlocked(m_id):
				SaveManager.unlock_map(m_id)
	
	# 4. 检查是否有角色需要解锁（通关条件与当前地图相关）
	var map_name = Database.maps[map_id]["name"] if Database.maps.has(map_id) else ""
	for char_id in Database.characters:
		var char_data = Database.characters[char_id]
		var cond = char_data.get("unlock_condition", "")
		# 条件格式示例: "通关「公路」后解锁"
		if cond != "" and map_name != "" and cond.contains(map_name):
			if not SaveManager.is_character_unlocked(char_id):
				SaveManager.unlock_character(char_id)
	
	# 5. 通关结算时自动上传存档
	if NetworkManager.is_logged_in:
		NetworkManager.sync_upload()
	
	queue_free()
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
