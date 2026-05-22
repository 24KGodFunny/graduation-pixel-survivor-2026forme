extends CanvasLayer
## Game Over UI - shows when player dies (defeat)

var bg_panel: PanelContainer
var stats_container: VBoxContainer
var buttons_container: HBoxContainer
var animation_done: bool = false
var stats_revealed: int = 0
var reveal_timer: float = 0.0

func _ready():
	layer = 100
	# 播放失败BGM
	if AudioManager:
		AudioManager.play_bgm("res://assets/audio/bgm_gameover.wav")
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
	main_panel.custom_minimum_size = Vector2(480, 400)
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.12, 0.05, 0.05, 0.95)
	main_style.border_color = Color(0.8, 0.2, 0.2, 1.0)
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
	
	# Title
	var title_label = Label.new()
	title_label.text = "✦ 战 斗 失 败 ✦"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "你已被击败..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	vbox.add_child(subtitle)
	
	# Separator
	var sep = HSeparator.new()
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
	
	var retry_btn = Button.new()
	retry_btn.text = "重新挑战"
	retry_btn.custom_minimum_size = Vector2(140, 40)
	retry_btn.pressed.connect(_on_retry)
	buttons_container.add_child(retry_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(140, 40)
	menu_btn.pressed.connect(_on_return_menu)
	buttons_container.add_child(menu_btn)

func _add_stat_row(label_text: String, value_text: String, color: Color = Color.WHITE) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5))
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
	
	_add_stat_row("地图", map_data["name"], Color(0.6, 0.7, 0.8))
	_add_stat_row("角色", char_data["name"], Color(0.8, 0.6, 0.7))
	_add_stat_row("存活时间", time_str, Color(0.7, 0.8, 0.7))
	_add_stat_row("角色等级", "Lv." + str(GameManager.player_level), Color(0.9, 0.8, 0.5))
	_add_stat_row("击杀数", str(GameManager.kill_count), Color(0.9, 0.5, 0.5))
	_add_stat_row("造成伤害", _format_number(GameManager.total_damage_dealt), Color(0.9, 0.6, 0.4))
	_add_stat_row("获得金币", str(GameManager.player_coins), Color(1.0, 0.85, 0.3))

func _format_number(n) -> String:
	if n is float:
		if n >= 10000:
			return "%.1fK" % (n / 1000.0)
		return "%.0f" % n
	if n >= 10000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)

func _start_reveal_animation():
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

func _on_retry():
	# 失败结算时自动上传存档
	if NetworkManager.is_logged_in:
		NetworkManager.sync_upload()
	queue_free()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_return_menu():
	# 失败结算时自动上传存档
	if NetworkManager.is_logged_in:
		NetworkManager.sync_upload()
	queue_free()
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
