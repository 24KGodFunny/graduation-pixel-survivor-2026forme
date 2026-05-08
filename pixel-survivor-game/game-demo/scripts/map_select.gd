extends Control
## Map selection scene - choose a map before entering the game

var map_buttons: Array[Button] = []
var selected_map_id: String = "endless_road"
var map_desc_label: Label
var map_preview: ColorRect
var boss_label: Label
var enemy_label: Label
var time_label: Label
var best_label: Label
var start_btn: Button
var unlock_label: Label

func _ready():
	_build_ui()
	# Default select first unlocked map
	var first_map = "tutorial"
	for mid in Database.maps:
		if SaveManager.is_map_unlocked(mid):
			first_map = mid
			break
	_on_map_selected(first_map)

func _build_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.owner = self
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	margin.owner = self
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# Top bar with back button
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 10)
	main_vbox.add_child(top_bar)
	
	var back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(100, 36)
	back_btn.pressed.connect(_on_back)
	top_bar.add_child(back_btn)
	
	var title = Label.new()
	title.text = "选择地图"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	top_bar.add_child(title)
	
	# Spacer for symmetry
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(100, 0)
	top_bar.add_child(spacer)
	
	main_vbox.add_child(HSeparator.new())
	
	# Content: left = map list, right = map details
	var content = HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content)
	
	# Left panel - Map list (scrollable, narrow)
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(200, 0)
	left_panel.add_theme_constant_override("separation", 8)
	content.add_child(left_panel)
	
	var list_label = Label.new()
	list_label.text = "◆ 地图列表"
	list_label.add_theme_font_size_override("font_size", 16)
	list_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	left_panel.add_child(list_label)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(scroll)
	
	var map_vbox = VBoxContainer.new()
	map_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(map_vbox)
	
	for mid in Database.maps:
		var m = Database.maps[mid]
		var btn = Button.new()
		var is_unlocked = SaveManager.is_map_unlocked(mid)
		var is_tutorial = m.get("is_tutorial", false)
		if is_unlocked:
			if is_tutorial:
				btn.text = "🎓 %s" % m["name"]
			else:
				btn.text = m["name"]
		else:
			btn.text = "%s 🔒" % m["name"]
			btn.modulate = Color(0.5, 0.5, 0.5)
		btn.custom_minimum_size = Vector2(180, 44)
		btn.pressed.connect(_on_map_selected.bind(mid))
		map_vbox.add_child(btn)
		map_buttons.append(btn)
	
	# Right panel - Map details
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 10)
	content.add_child(right_panel)
	
	var detail_label = Label.new()
	detail_label.text = "◆ 地图详情"
	detail_label.add_theme_font_size_override("font_size", 16)
	detail_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	right_panel.add_child(detail_label)
	
	# Map preview (color block placeholder, larger)
	map_preview = ColorRect.new()
	map_preview.custom_minimum_size = Vector2(400, 220)
	map_preview.color = Color(0.2, 0.3, 0.2)
	right_panel.add_child(map_preview)
	
	# Map name & description
	map_desc_label = Label.new()
	map_desc_label.text = ""
	map_desc_label.add_theme_font_size_override("font_size", 14)
	map_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	map_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(map_desc_label)
	
	# Unlock condition label
	unlock_label = Label.new()
	unlock_label.text = ""
	unlock_label.add_theme_font_size_override("font_size", 13)
	unlock_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(unlock_label)
	
	# Info panel
	var info_panel = PanelContainer.new()
	right_panel.add_child(info_panel)
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_panel.add_child(info_vbox)
	
	boss_label = Label.new()
	boss_label.add_theme_font_size_override("font_size", 13)
	boss_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	info_vbox.add_child(boss_label)
	
	enemy_label = Label.new()
	enemy_label.add_theme_font_size_override("font_size", 13)
	enemy_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	info_vbox.add_child(enemy_label)
	
	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 13)
	time_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	info_vbox.add_child(time_label)
	
	best_label = Label.new()
	best_label.add_theme_font_size_override("font_size", 13)
	best_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	info_vbox.add_child(best_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(spacer2)
	
	# Start button
	start_btn = Button.new()
	start_btn.text = "▶ 开始游戏"
	start_btn.custom_minimum_size = Vector2(200, 50)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.pressed.connect(_on_start)
	right_panel.add_child(start_btn)

func _on_map_selected(map_id: String):
	if not SaveManager.is_map_unlocked(map_id):
		# Show notification but still display info
		pass
	selected_map_id = map_id
	GameManager.selected_map_id = map_id
	
	# Update button highlights
	for i in range(map_buttons.size()):
		var keys = Database.maps.keys()
		if i < keys.size():
			if keys[i] == map_id:
				map_buttons[i].modulate = Color(0.5, 1.0, 0.8) if SaveManager.is_map_unlocked(keys[i]) else Color(0.5, 0.7, 0.6)
			else:
				if SaveManager.is_map_unlocked(keys[i]):
					map_buttons[i].modulate = Color.WHITE
				else:
					map_buttons[i].modulate = Color(0.5, 0.5, 0.5)
	
	# Update details
	var m = Database.maps[map_id]
	map_preview.color = m["bg_color"]
	map_desc_label.text = "%s\n%s" % [m["name"], m["description"]]
	
	var boss_name = Database.bosses[m["boss"]]["name"] if Database.bosses.has(m["boss"]) else "未知"
	boss_label.text = "👹 Boss: %s" % boss_name
	enemy_label.text = "👾 敌人: %s" % ", ".join(m["enemy_types"])
	time_label.text = "⏱ 时间限制: %d 秒" % m["time_limit"]
	
	# Best score
	var is_tutorial = m.get("is_tutorial", false)
	if is_tutorial:
		best_label.text = "📝 教学关卡（不计成绩）"
	else:
		var best = SaveManager.get_best_score(map_id)
		if best > 0:
			best_label.text = "🏆 最佳成绩: %d" % best
		else:
			best_label.text = "🏆 最佳成绩: 暂无"
	
	# Update unlock condition display
	var is_unlocked = SaveManager.is_map_unlocked(map_id)
	var unlock_cond = m.get("unlock_condition", "")
	if is_unlocked:
		if SaveManager.is_map_completed(map_id):
			unlock_label.text = "✅ 状态：已通关"
			unlock_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			unlock_label.text = "🔓 状态：已解锁"
			unlock_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	else:
		unlock_label.text = "🔒 解锁条件：%s" % unlock_cond
		unlock_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	
	# Update start button state
	if is_unlocked:
		start_btn.text = "▶ 开始游戏"
		start_btn.disabled = false
		start_btn.modulate = Color.WHITE
	else:
		start_btn.text = "🔒 未解锁"
		start_btn.disabled = true
		start_btn.modulate = Color(0.5, 0.5, 0.5)

func _on_start():
	if not SaveManager.is_map_unlocked(selected_map_id):
		return
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")