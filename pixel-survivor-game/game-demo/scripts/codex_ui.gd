extends Control
## 图鉴系统 - 展示武器和被动道具的详细信息

enum TabType { WEAPONS, PASSIVES }

var current_tab: TabType = TabType.WEAPONS
var selected_item_id: String = ""

var tab_container: TabContainer
var weapon_list: ItemList
var passive_list: ItemList
var detail_panel: VBoxContainer

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# 标题栏
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "📖 图鉴"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	header.add_child(title)
	
	# 占位
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "✕ 返回"
	back_btn.custom_minimum_size = Vector2(100, 36)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)
	
	# 分隔线
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# 主内容区：左侧列表 + 右侧详情
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(content_hbox)
	
	# --- 左侧：标签页 + 列表 ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(280, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	left_style.border_color = Color(0.3, 0.3, 0.5)
	left_style.set_border_width_all(1)
	left_style.set_corner_radius_all(4)
	left_style.set_content_margin_all(8)
	left_panel.add_theme_stylebox_override("panel", left_style)
	content_hbox.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)
	
	# 标签切换按钮
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 4)
	left_vbox.add_child(tab_hbox)
	
	var weapon_tab_btn = Button.new()
	weapon_tab_btn.text = "⚔ 武器"
	weapon_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_tab_btn.custom_minimum_size = Vector2(0, 32)
	weapon_tab_btn.pressed.connect(_on_weapon_tab_pressed)
	tab_hbox.add_child(weapon_tab_btn)
	
	var passive_tab_btn = Button.new()
	passive_tab_btn.text = "🛡 被动"
	passive_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	passive_tab_btn.custom_minimum_size = Vector2(0, 32)
	passive_tab_btn.pressed.connect(_on_passive_tab_pressed)
	tab_hbox.add_child(passive_tab_btn)
	
	# 武器列表
	weapon_list = ItemList.new()
	weapon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_list.custom_minimum_size = Vector2(250, 0)
	weapon_list.icon_mode = ItemList.ICON_MODE_TOP
	weapon_list.max_columns = 1
	weapon_list.fixed_column_width = 240
	weapon_list.fixed_icon_size = Vector2i(48, 48)
	weapon_list.item_selected.connect(_on_weapon_selected)
	left_vbox.add_child(weapon_list)
	
	# 被动列表（初始隐藏）
	passive_list = ItemList.new()
	passive_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	passive_list.custom_minimum_size = Vector2(250, 0)
	passive_list.icon_mode = ItemList.ICON_MODE_TOP
	passive_list.max_columns = 1
	passive_list.fixed_column_width = 240
	passive_list.fixed_icon_size = Vector2i(48, 48)
	passive_list.visible = false
	passive_list.item_selected.connect(_on_passive_selected)
	left_vbox.add_child(passive_list)
	
	# --- 右侧：详情面板 ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.08, 0.08, 0.12, 0.8)
	right_style.border_color = Color(0.3, 0.3, 0.5)
	right_style.set_border_width_all(1)
	right_style.set_corner_radius_all(4)
	right_style.set_content_margin_all(12)
	right_panel.add_theme_stylebox_override("panel", right_style)
	content_hbox.add_child(right_panel)
	
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_scroll)
	
	detail_panel = VBoxContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_constant_override("separation", 6)
	right_scroll.add_child(detail_panel)
	
	# 填充列表
	_populate_weapon_list()
	_populate_passive_list()
	
	# 默认选中第一个武器
	if weapon_list.item_count > 0:
		weapon_list.select(0)
		_on_weapon_selected(0)

func _on_back_pressed():
	queue_free()

func _on_weapon_tab_pressed():
	current_tab = TabType.WEAPONS
	weapon_list.visible = true
	passive_list.visible = false
	if weapon_list.item_count > 0:
		weapon_list.select(0)
		_on_weapon_selected(0)

func _on_passive_tab_pressed():
	current_tab = TabType.PASSIVES
	weapon_list.visible = false
	passive_list.visible = true
	if passive_list.item_count > 0:
		passive_list.select(0)
		_on_passive_selected(0)

func _populate_weapon_list():
	weapon_list.clear()
	for weapon_id in Database.weapons:
		var w = Database.weapons[weapon_id]
		var icon_path = "res://assets/images/ui/icons/weapons/icon_weapon_%s.png" % weapon_id
		var icon: Texture2D = null
		if ResourceLoader.exists(icon_path):
			icon = load(icon_path)
		var idx = weapon_list.add_item(w["name"], icon)
		weapon_list.set_item_metadata(idx, weapon_id)

func _populate_passive_list():
	passive_list.clear()
	for passive_id in Database.passive_items:
		var p = Database.passive_items[passive_id]
		var icon_path = "res://assets/images/ui/icons/passives/icon_passive_%s.png" % passive_id
		var icon: Texture2D = null
		if ResourceLoader.exists(icon_path):
			icon = load(icon_path)
		var idx = passive_list.add_item(p["name"], icon)
		passive_list.set_item_metadata(idx, passive_id)

func _on_weapon_selected(index: int):
	selected_item_id = weapon_list.get_item_metadata(index)
	_show_weapon_detail(selected_item_id)

func _on_passive_selected(index: int):
	selected_item_id = passive_list.get_item_metadata(index)
	_show_passive_detail(selected_item_id)

func _clear_detail():
	for child in detail_panel.get_children():
		child.queue_free()

func _show_weapon_detail(weapon_id: String):
	_clear_detail()
	if not Database.weapons.has(weapon_id):
		return
	var w = Database.weapons[weapon_id]
	
	# 图标
	var icon_path = "res://assets/images/ui/icons/weapons/icon_weapon_%s.png" % weapon_id
	if ResourceLoader.exists(icon_path):
		var tex = TextureRect.new()
		tex.texture = load(icon_path)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(64, 64)
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		detail_panel.add_child(tex)
	
	# 名称
	var name_lbl = Label.new()
	name_lbl.text = w["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	detail_panel.add_child(name_lbl)
	
	# 描述
	var desc_lbl = Label.new()
	desc_lbl.text = w["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	detail_panel.add_child(desc_lbl)
	
	# 分隔线
	detail_panel.add_child(HSeparator.new())
	
	# 等级属性表格
	var table_title = Label.new()
	table_title.text = "── 各等级属性 ──"
	table_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_title.add_theme_font_size_override("font_size", 14)
	table_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	detail_panel.add_child(table_title)
	
	# 表头
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	detail_panel.add_child(header_row)
	
	for col_text in ["等级", "伤害", "数量", "穿透", "冷却", "范围"]:
		var col = Label.new()
		col.text = col_text
		col.custom_minimum_size = Vector2(50, 0)
		col.add_theme_font_size_override("font_size", 11)
		col.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_row.add_child(col)
	
	# 各等级数据
	var levels = w.get("levels", [])
	for i in range(levels.size()):
		var lv = levels[i]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		detail_panel.add_child(row)
		
		var lv_lbl = Label.new()
		lv_lbl.text = "Lv.%d" % (i + 1)
		lv_lbl.custom_minimum_size = Vector2(50, 0)
		lv_lbl.add_theme_font_size_override("font_size", 11)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == 0:
			lv_lbl.add_theme_color_override("font_color", Color.WHITE)
		elif i == levels.size() - 1:
			lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lv_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		row.add_child(lv_lbl)
		
		for val in [lv["damage"], lv["count"], lv["pierce"], lv["cooldown"], lv["area"]]:
			var val_lbl = Label.new()
			if val is float:
				val_lbl.text = str(val).pad_decimals(1)
			elif val == 999:
				val_lbl.text = "∞"
			else:
				val_lbl.text = str(val)
			val_lbl.custom_minimum_size = Vector2(50, 0)
			val_lbl.add_theme_font_size_override("font_size", 11)
			val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if i == levels.size() - 1:
				val_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			else:
				val_lbl.add_theme_color_override("font_color", Color.WHITE)
			row.add_child(val_lbl)

func _show_passive_detail(passive_id: String):
	_clear_detail()
	if not Database.passive_items.has(passive_id):
		return
	var p = Database.passive_items[passive_id]
	
	# 图标
	var icon_path = "res://assets/images/ui/icons/passives/icon_passive_%s.png" % passive_id
	if ResourceLoader.exists(icon_path):
		var tex = TextureRect.new()
		tex.texture = load(icon_path)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(64, 64)
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		detail_panel.add_child(tex)
	
	# 名称
	var name_lbl = Label.new()
	name_lbl.text = p["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	detail_panel.add_child(name_lbl)
	
	# 描述
	var desc_lbl = Label.new()
	desc_lbl.text = p["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	detail_panel.add_child(desc_lbl)
	
	# 分隔线
	detail_panel.add_child(HSeparator.new())
	
	# 等级属性表格
	var table_title = Label.new()
	table_title.text = "── 各等级效果 ──"
	table_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_title.add_theme_font_size_override("font_size", 14)
	table_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	detail_panel.add_child(table_title)
	
	var values = p.get("values", [])
	var stat_name = p.get("stat", "")
	
	# 表头
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	detail_panel.add_child(header_row)
	
	var lv_header = Label.new()
	lv_header.text = "等级"
	lv_header.custom_minimum_size = Vector2(60, 0)
	lv_header.add_theme_font_size_override("font_size", 12)
	lv_header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	lv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(lv_header)
	
	var val_header = Label.new()
	val_header.text = "效果值"
	val_header.custom_minimum_size = Vector2(80, 0)
	val_header.add_theme_font_size_override("font_size", 12)
	val_header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	val_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(val_header)
	
	var desc_header = Label.new()
	desc_header.text = "说明"
	desc_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_header.add_theme_font_size_override("font_size", 12)
	desc_header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	header_row.add_child(desc_header)
	
	# 各等级数据
	for i in range(values.size()):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		detail_panel.add_child(row)
		
		var lv_lbl = Label.new()
		lv_lbl.text = "Lv.%d" % (i + 1)
		lv_lbl.custom_minimum_size = Vector2(60, 0)
		lv_lbl.add_theme_font_size_override("font_size", 12)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == values.size() - 1:
			lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lv_lbl.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(lv_lbl)
		
		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(80, 0)
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == values.size() - 1:
			val_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			val_lbl.add_theme_color_override("font_color", Color.WHITE)
		
		# 根据属性类型格式化
		var v = values[i]
		match stat_name:
			"armor", "amount_bonus", "revival_count":
				val_lbl.text = "+%d" % int(v)
			"crit_chance":
				val_lbl.text = "+%d%%" % int(v * 100)
			"cooldown_mult":
				val_lbl.text = "x%.2f" % v
			"magnet_range":
				val_lbl.text = "%d" % int(v)
			_:
				if v is float:
					val_lbl.text = "x%.2f" % v
				else:
					val_lbl.text = str(v)
		row.add_child(val_lbl)
		
		var effect_lbl = Label.new()
		effect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effect_lbl.add_theme_font_size_override("font_size", 11)
		effect_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		effect_lbl.text = _get_passive_effect_desc(stat_name, v)
		row.add_child(effect_lbl)

func _get_passive_effect_desc(stat: String, value) -> String:
	match stat:
		"armor":
			return "减少 %d 点伤害" % int(value)
		"damage_mult":
			return "伤害提升 %d%%" % int((value - 1.0) * 100)
		"projectile_speed":
			return "弹速提升 %d%%" % int((value - 1.0) * 100)
		"cooldown_mult":
			return "冷却减少 %d%%" % int((1.0 - value) * 100)
		"crit_chance":
			return "暴击率 +%d%%" % int(value * 100)
		"magnet_range":
			return "拾取范围 %d" % int(value)
		"max_hp_mult":
			return "生命上限 +%d%%" % int((value - 1.0) * 100)
		"hp_regen":
			return "每秒恢复 %.1f HP" % value
		"luck":
			return "幸运 +%d%%" % int((value - 1.0) * 100)
		"speed_mult":
			return "移速提升 %d%%" % int((value - 1.0) * 100)
		"growth":
			return "经验获取 +%d%%" % int((value - 1.0) * 100)
		"greed":
			return "金币获取 +%d%%" % int((value - 1.0) * 100)
		"duration_mult":
			return "持续时间 +%d%%" % int((value - 1.0) * 100)
		"area_mult":
			return "攻击范围 +%d%%" % int((value - 1.0) * 100)
		"amount_bonus":
			return "弹射物数量 +%d" % int(value)
		"revival_count":
			return "复活次数 +%d" % int(value)
		_:
			return ""