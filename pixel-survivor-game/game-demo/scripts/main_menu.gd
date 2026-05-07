extends Control
## Main menu - character select and settings

@onready var char_list: ItemList = %CharacterList
@onready var char_detail: VBoxContainer = %CharDetail
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton
@onready var gold_label: Label = %GoldLabel
@onready var diamond_label: Label = %DiamondLabel
@onready var login_btn: Button = %LoginButton
@onready var sync_upload_btn: Button = %SyncUploadButton
@onready var sync_download_btn: Button = %SyncDownloadButton

var selected_char_id: String = ""

func _ready():
	_populate_characters()
	_update_gold_display()
	_update_diamond_display()
	_update_login_display()
	_update_sync_buttons()
	# 尝试自动登录
	NetworkManager.auto_login()
	# 连接登录成功信号
	if not NetworkManager.login_success.is_connected(_on_login_success):
		NetworkManager.login_success.connect(_on_login_success)
	# 连接同步信号
	if not NetworkManager.sync_upload_success.is_connected(_on_sync_upload_success):
		NetworkManager.sync_upload_success.connect(_on_sync_upload_success)
	if not NetworkManager.sync_upload_failed.is_connected(_on_sync_upload_failed):
		NetworkManager.sync_upload_failed.connect(_on_sync_upload_failed)
	if not NetworkManager.sync_download_success.is_connected(_on_sync_download_success):
		NetworkManager.sync_download_success.connect(_on_sync_download_success)
	if not NetworkManager.sync_download_failed.is_connected(_on_sync_download_failed):
		NetworkManager.sync_download_failed.connect(_on_sync_download_failed)
	if char_list.item_count > 0:
		char_list.select(0)
		_on_character_list_item_selected(0)

func _populate_characters():
	char_list.clear()
	var char_list_data = Database.get_character_list()
	for c in char_list_data:
		var idx = char_list.add_item(c["name"])
		char_list.set_item_metadata(idx, c["id"])
		if not SaveManager.is_character_unlocked(c["id"]):
			char_list.set_item_text(idx, c["name"] + " 🔒")

func _on_character_list_item_selected(index: int):
	selected_char_id = char_list.get_item_metadata(index)
	_update_char_detail()

func _update_char_detail():
	# Clear old content
	for child in char_detail.get_children():
		child.queue_free()
	
	if selected_char_id == "" or not Database.characters.has(selected_char_id):
		return
	
	var char_data = Database.characters[selected_char_id]
	var char_level = SaveManager.get_character_level(selected_char_id)
	var stats = Database.get_character_stats_at_level(selected_char_id, char_level)
	var is_unlocked = SaveManager.is_character_unlocked(selected_char_id)
	
	# === Top: Character name + level ===
	var header = Label.new()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	if is_unlocked:
		header.text = "%s  Lv.%d" % [char_data["name"], char_level]
	else:
		header.text = "%s  🔒" % char_data["name"]
	char_detail.add_child(header)
	
	# === Middle: HBoxContainer with stats panel (left) + portrait (right) ===
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_detail.add_child(hbox)
	
	# --- Left: Stats panel (vertical rectangle) ---
	var stats_panel = PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(220, 320)
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	stats_style.border_color = Color(0.4, 0.4, 0.6)
	stats_style.set_border_width_all(1)
	stats_style.set_corner_radius_all(4)
	stats_style.set_content_margin_all(10)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	hbox.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(stats_vbox)
	
	# Stats title
	var stats_title = Label.new()
	stats_title.text = "── 角色属性 ──"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 14)
	stats_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	stats_vbox.add_child(stats_title)
	
	# Stat rows
	var stat_items = [
		["生命上限", str(int(stats["max_hp"])), "+" + str(int(char_data["max_hp"]))],
		["移动速度", str(int(stats["speed"])), "+" + str(int(char_data["speed"]))],
		["护甲", str(stats["armor"]).pad_decimals(1), "+" + str(char_data["armor"])],
		["伤害倍率", str(stats["damage_mult"]).pad_decimals(2) + "x", "+" + str(char_data["damage_mult"])],
		["冷却倍率", str(stats["cooldown_mult"]).pad_decimals(2) + "x", "+" + str(char_data["cooldown_mult"])],
		["暴击率", str(int(stats["crit_chance"] * 100)) + "%", "+" + str(int(char_data["crit_chance"] * 100))],
		["暴击伤害", str(stats["crit_damage"]).pad_decimals(2) + "x", "+" + str(char_data["crit_damage"])],
		["幸运", str(stats["luck"]).pad_decimals(2), "+" + str(char_data["luck"])],
		["成长", str(stats["growth"]).pad_decimals(2), "+" + str(char_data["growth"])],
		["贪婪", str(stats["greed"]).pad_decimals(2), "+" + str(char_data["greed"])],
		["拾取范围", str(int(stats["magnet_range"])), "+" + str(int(char_data["magnet_range"]))],
	]
	
	for item in stat_items:
		var stat_name = item[0]
		var stat_val = item[1]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		stats_vbox.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = stat_name
		name_lbl.custom_minimum_size.x = 70
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = stat_val
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 13)
		# Highlight if upgraded
		if char_level > 1:
			val_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			val_lbl.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(val_lbl)
	
	# Description
	var desc_sep = HSeparator.new()
	desc_sep.add_theme_constant_override("separation", 6)
	stats_vbox.add_child(desc_sep)
	
	var desc_lbl = Label.new()
	desc_lbl.text = char_data["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_vbox.add_child(desc_lbl)
	
	# Starting weapon
	var weapon_lbl = Label.new()
	var weapon_id = char_data.get("starting_weapon", "")
	if weapon_id != "" and Database.weapons.has(weapon_id):
		weapon_lbl.text = "初始武器: %s" % Database.weapons[weapon_id]["name"]
	else:
		weapon_lbl.text = "初始武器: 无"
	weapon_lbl.add_theme_font_size_override("font_size", 11)
	weapon_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	stats_vbox.add_child(weapon_lbl)
	
	# Passive
	var passive_id = char_data.get("passive", "")
	if passive_id != "" and Database.passive_items.has(passive_id):
		var passive_lbl = Label.new()
		passive_lbl.text = "被动: %s" % Database.passive_items[passive_id]["name"]
		passive_lbl.add_theme_font_size_override("font_size", 11)
		passive_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		stats_vbox.add_child(passive_lbl)
	
	# --- Right: Portrait panel (vertical rectangle) ---
	var portrait_panel = PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(180, 320)
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.12, 0.1, 0.18, 0.8)
	portrait_style.border_color = Color(0.5, 0.3, 0.6)
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(4)
	portrait_style.set_content_margin_all(8)
	portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_panel)
	
	var portrait_vbox = VBoxContainer.new()
	portrait_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_panel.add_child(portrait_vbox)
	
	# Portrait title
	var portrait_title = Label.new()
	portrait_title.text = "── 角色立绘 ──"
	portrait_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_title.add_theme_font_size_override("font_size", 14)
	portrait_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	portrait_vbox.add_child(portrait_title)
	
	# Character sprite
	var sprite_rect = TextureRect.new()
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_rect.custom_minimum_size = Vector2(140, 200)
	sprite_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sprite_path = char_data.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		sprite_rect.texture = load(sprite_path)
	portrait_vbox.add_child(sprite_rect)
	
	# Character color indicator
	var color_bar = ColorRect.new()
	color_bar.custom_minimum_size = Vector2(120, 6)
	color_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_bar.color = char_data.get("color", Color.WHITE)
	portrait_vbox.add_child(color_bar)
	
	# === Upgrade section inside stats panel ===
	if is_unlocked:
		var upgrade_sep = HSeparator.new()
		upgrade_sep.add_theme_constant_override("separation", 6)
		stats_vbox.add_child(upgrade_sep)
		
		var upgrade_btn = Button.new()
		upgrade_btn.custom_minimum_size = Vector2(0, 32)
		
		if char_level >= Database.CHARACTER_MAX_LEVEL:
			upgrade_btn.text = "已满级 (Lv.%d)" % Database.CHARACTER_MAX_LEVEL
			upgrade_btn.disabled = true
			upgrade_btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.85, 0.2))
		else:
			var cost = Database.get_character_level_up_cost(char_level)
			upgrade_btn.text = "升级 (%d 金币)" % cost
			if SaveManager.gold >= cost:
				upgrade_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			else:
				upgrade_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			upgrade_btn.pressed.connect(_on_upgrade_pressed)
		stats_vbox.add_child(upgrade_btn)
		
		# Level info
		var level_info = Label.new()
		level_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_info.add_theme_font_size_override("font_size", 11)
		if char_level >= Database.CHARACTER_MAX_LEVEL:
			level_info.text = "等级已达上限"
			level_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			level_info.text = "下级: HP+%d 速度+%d 护甲+%.1f 伤害+%.2f" % [
				int(Database.LEVEL_BONUSES["max_hp"]),
				int(Database.LEVEL_BONUSES["speed"]),
				Database.LEVEL_BONUSES["armor"],
				Database.LEVEL_BONUSES["damage_mult"],
			]
			level_info.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		stats_vbox.add_child(level_info)
	
	# === Bottom: Start button / unlock info ===
	var btn_container = VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 6)
	char_detail.add_child(btn_container)
	
	if is_unlocked:
		start_btn.visible = true
		start_btn.text = "开始游戏 - %s" % char_data["name"]
		# Disconnect buy signal if previously connected
		if start_btn.pressed.is_connected(_on_buy_character_pressed):
			start_btn.pressed.disconnect(_on_buy_character_pressed)
		if not start_btn.pressed.is_connected(_on_start_button_pressed):
			start_btn.pressed.connect(_on_start_button_pressed)
	else:
		var cost = char_data.get("cost", 0)
		if cost > 0:
			start_btn.visible = true
			start_btn.text = "购买 (%d 金币)" % cost
			if SaveManager.gold >= cost:
				start_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			else:
				start_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			# Disconnect start signal if previously connected
			if start_btn.pressed.is_connected(_on_start_button_pressed):
				start_btn.pressed.disconnect(_on_start_button_pressed)
			if not start_btn.pressed.is_connected(_on_buy_character_pressed):
				start_btn.pressed.connect(_on_buy_character_pressed)
		else:
			start_btn.visible = false
			var unlock_info = Label.new()
			unlock_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unlock_info.add_theme_font_size_override("font_size", 14)
			unlock_info.text = "??? 隐藏角色 ???"
			unlock_info.add_theme_color_override("font_color", Color(0.8, 0.3, 0.8))
			btn_container.add_child(unlock_info)

func _on_upgrade_pressed():
	if selected_char_id == "":
		return
	if SaveManager.upgrade_character(selected_char_id):
		_update_gold_display()
		_update_char_detail()
		# Refresh list in case of visual update

func _on_buy_character_pressed():
	if selected_char_id == "" or not Database.characters.has(selected_char_id):
		return
	var char_data = Database.characters[selected_char_id]
	var cost = char_data.get("cost", 0)
	if cost <= 0:
		return
	if SaveManager.gold < cost:
		# Show insufficient gold dialog
		var dialog = AcceptDialog.new()
		dialog.title = "金币不足"
		dialog.dialog_text = "需要 %d 金币解锁 %s\n当前金币: %d" % [cost, char_data["name"], SaveManager.gold]
		dialog.ok_button_text = "确定"
		add_child(dialog)
		dialog.popup_centered(Vector2i(300, 120))
		dialog.confirmed.connect(func(): dialog.queue_free())
		return
	# Sufficient gold - unlock character
	SaveManager.spend_gold(cost)
	SaveManager.unlock_character(selected_char_id)
	_populate_characters()
	_update_gold_display()
	# Re-select the now-unlocked character
	for i in range(char_list.item_count):
		if char_list.get_item_metadata(i) == selected_char_id:
			char_list.select(i)
			break
	_update_char_detail()

func _update_gold_display():
	if gold_label:
		gold_label.text = "💰 %d" % SaveManager.gold

func _on_start_button_pressed():
	if selected_char_id == "":
		return
	GameManager.selected_character_id = selected_char_id
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")

func _update_diamond_display():
	if diamond_label:
		diamond_label.text = "💎 0"

func _update_login_display():
	if login_btn:
		if NetworkManager.is_logged_in:
			var display_name = NetworkManager.nickname if NetworkManager.nickname != "" else NetworkManager.username
			login_btn.text = display_name
		else:
			login_btn.text = "登录"

func _update_sync_buttons():
	var logged_in = NetworkManager.is_logged_in
	if sync_upload_btn:
		sync_upload_btn.visible = logged_in
	if sync_download_btn:
		sync_download_btn.visible = logged_in

func _on_sync_upload_button_pressed():
	if not NetworkManager.is_logged_in:
		var dialog = AcceptDialog.new()
		dialog.title = "提示"
		dialog.dialog_text = "请先登录后再上传存档"
		dialog.ok_button_text = "确定"
		add_child(dialog)
		dialog.popup_centered(Vector2i(280, 100))
		dialog.confirmed.connect(func(): dialog.queue_free())
		return
	var data = SaveManager.prepare_upload_data()
	NetworkManager.sync_upload(data)
	sync_upload_btn.disabled = true
	sync_upload_btn.text = "上传中..."

func _on_sync_download_button_pressed():
	if not NetworkManager.is_logged_in:
		var dialog = AcceptDialog.new()
		dialog.title = "提示"
		dialog.dialog_text = "请先登录后再下载存档"
		dialog.ok_button_text = "确定"
		add_child(dialog)
		dialog.popup_centered(Vector2i(280, 100))
		dialog.confirmed.connect(func(): dialog.queue_free())
		return
	# 确认覆盖
	var dialog = ConfirmationDialog.new()
	dialog.title = "下载存档"
	dialog.dialog_text = "下载服务器存档将与本地数据合并（取并集/最大值），是否继续？"
	dialog.ok_button_text = "确认下载"
	dialog.cancel_button_text = "取消"
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 130))
	dialog.confirmed.connect(func():
		NetworkManager.sync_download()
		sync_download_btn.disabled = true
		sync_download_btn.text = "下载中..."
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_sync_upload_success():
	sync_upload_btn.disabled = false
	sync_upload_btn.text = "上传存档"
	var dialog = AcceptDialog.new()
	dialog.title = "上传成功"
	dialog.dialog_text = "本地存档已成功上传到服务器！"
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered(Vector2i(280, 100))
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_sync_upload_failed(error: String):
	sync_upload_btn.disabled = false
	sync_upload_btn.text = "上传存档"
	sync_download_btn.disabled = false
	sync_download_btn.text = "下载存档"
	var dialog = AcceptDialog.new()
	dialog.title = "同步失败"
	dialog.dialog_text = "错误: %s" % error
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 100))
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_sync_download_success(data: Dictionary):
	sync_download_btn.disabled = false
	sync_download_btn.text = "下载存档"
	SaveManager.apply_download_data(data)
	_populate_characters()
	_update_gold_display()
	_update_diamond_display()
	if selected_char_id != "":
		_update_char_detail()
	var dialog = AcceptDialog.new()
	dialog.title = "下载成功"
	dialog.dialog_text = "服务器存档已合并到本地！\n金币: %d\n钻石: %d" % [SaveManager.gold, SaveManager.diamond]
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 120))
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_sync_download_failed(error: String):
	sync_download_btn.disabled = false
	sync_download_btn.text = "下载存档"
	var dialog = AcceptDialog.new()
	dialog.title = "同步失败"
	dialog.dialog_text = "错误: %s" % error
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 100))
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_login_button_pressed():
	if NetworkManager.is_logged_in:
		# 已登录，弹出退出确认
		var dialog = ConfirmationDialog.new()
		dialog.title = "用户信息"
		var display_name = NetworkManager.nickname if NetworkManager.nickname != "" else NetworkManager.username
		dialog.dialog_text = "当前用户: %s\n是否退出登录？" % display_name
		dialog.ok_button_text = "退出登录"
		dialog.cancel_button_text = "取消"
		add_child(dialog)
		dialog.popup_centered(Vector2i(300, 150))
		dialog.confirmed.connect(func():
			NetworkManager.logout()
			_update_login_display()
			_update_sync_buttons()
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
	else:
		# 未登录，弹出登录界面
		var login_scene = load("res://scripts/login_ui.gd")
		var login_ui = Control.new()
		login_ui.set_script(login_scene)
		login_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(login_ui)

func _on_login_success(_data: Dictionary):
	_update_login_display()
	_update_sync_buttons()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")