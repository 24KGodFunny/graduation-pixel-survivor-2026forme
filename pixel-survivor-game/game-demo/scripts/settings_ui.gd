extends Control
## 设置界面 —— 音量调节、显示方式、按键映射

signal back_pressed

# ── 音量 ──────────────────────────────────────────────
var master_slider: HSlider
var bgm_slider: HSlider
var sfx_slider: HSlider
var master_label: Label
var bgm_label: Label
var sfx_label: Label

# ── 显示 ──────────────────────────────────────────────
var fullscreen_check: CheckButton

# ── 按键映射 ──────────────────────────────────────────
## 需要允许玩家自定义的动作列表
var _rebindable_actions: Array[String] = [
	"move_up", "move_down", "move_left", "move_right",
]
## 动作的中文显示名
var _action_display_names: Dictionary = {
	"move_up": "上移",
	"move_down": "下移",
	"move_left": "左移",
	"move_right": "右移",
}
## 当前正在等待按键绑定的动作（空字符串 = 无）
var _waiting_action: String = ""
## 按键绑定按钮引用 { action_name: Button }
var _rebind_buttons: Dictionary = {}
## 等待提示标签
var _waiting_label: Label

func _ready():
	# 允许在暂停时处理输入
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_settings()

func _build_ui():
	# ── 背景 ──
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── 居中容器 ──
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# ── 主容器 ──
	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(520, 500)
	main_vbox.add_theme_constant_override("separation", 12)
	center.add_child(main_vbox)

	# ── 标题 ──
	var title = Label.new()
	title.text = "设 置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(title)

	# ── 分隔线 ──
	var sep1 = HSeparator.new()
	main_vbox.add_child(sep1)

	# ── 音量标题 ──
	var vol_title = Label.new()
	vol_title.text = "音量设置"
	vol_title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(vol_title)

	# 主音量
	var master_row = _create_slider_row("主音量", 0.0, 1.0, 0.01)
	master_slider = master_row[1]
	master_label = master_row[2]
	main_vbox.add_child(master_row[0])

	# BGM
	var bgm_row = _create_slider_row("背景音乐", 0.0, 1.0, 0.01)
	bgm_slider = bgm_row[1]
	bgm_label = bgm_row[2]
	main_vbox.add_child(bgm_row[0])

	# SFX
	var sfx_row = _create_slider_row("音效", 0.0, 1.0, 0.01)
	sfx_slider = sfx_row[1]
	sfx_label = sfx_row[2]
	main_vbox.add_child(sfx_row[0])

	# ── 分隔线 ──
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)

	# ── 显示设置标题 ──
	var display_title = Label.new()
	display_title.text = "显示设置"
	display_title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(display_title)

	# 全屏
	var fs_row = HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 12)
	var fs_label = Label.new()
	fs_label.text = "全屏模式"
	fs_label.custom_minimum_size = Vector2(120, 0)
	fullscreen_check = CheckButton.new()
	fullscreen_check.custom_minimum_size = Vector2(160, 0)
	fullscreen_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fullscreen_check.text = "关闭"
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(fs_label)
	fs_row.add_child(fullscreen_check)
	main_vbox.add_child(fs_row)

	# ── 分隔线 ──
	var sep3 = HSeparator.new()
	main_vbox.add_child(sep3)

	# ── 按键映射标题 ──
	var keybind_title = Label.new()
	keybind_title.text = "按键映射"
	keybind_title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(keybind_title)

	# 等待提示
	_waiting_label = Label.new()
	_waiting_label.text = "请按下新的按键..."
	_waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_waiting_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	_waiting_label.visible = false
	main_vbox.add_child(_waiting_label)

	# 按键绑定行
	for action_name in _rebindable_actions:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl = Label.new()
		lbl.text = _action_display_names.get(action_name, action_name)
		lbl.custom_minimum_size = Vector2(120, 0)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_rebind_pressed.bind(action_name))
		_rebind_buttons[action_name] = btn
		row.add_child(lbl)
		row.add_child(btn)
		main_vbox.add_child(row)

	# 重置按键按钮
	var reset_btn = Button.new()
	reset_btn.text = "恢复默认按键"
	reset_btn.pressed.connect(_on_reset_keybindings)
	main_vbox.add_child(reset_btn)

	# ── 分隔线 ──
	var sep4 = HSeparator.new()
	main_vbox.add_child(sep4)

	# ── 返回按钮 ──
	var back_btn = Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	main_vbox.add_child(back_btn)

func _create_slider_row(label_text: String, min_val: float, max_val: float, step: float) -> Array:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 0)
	var val_label = Label.new()
	val_label.text = "100%"
	val_label.custom_minimum_size = Vector2(50, 0)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lbl)
	row.add_child(slider)
	row.add_child(val_label)
	return [row, slider, val_label]

func _load_settings():
	# 音量
	var master_vol = GlobalSave.get_setting("master_volume", 1.0)
	var bgm_vol = GlobalSave.get_setting("bgm_volume", 0.8)
	var sfx_vol = GlobalSave.get_setting("sfx_volume", 0.8)
	master_slider.value = master_vol
	bgm_slider.value = bgm_vol
	sfx_slider.value = sfx_vol
	_update_volume_label(master_label, master_vol)
	_update_volume_label(bgm_label, bgm_vol)
	_update_volume_label(sfx_label, sfx_vol)
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# 全屏
	var fs = GlobalSave.get_setting("fullscreen", false)
	fullscreen_check.button_pressed = fs
	fullscreen_check.text = "开启" if fs else "关闭"

	# 按键绑定
	_refresh_keybind_buttons()
	
	# 初始化时将已保存的音量应用到 AudioManager
	if AudioManager:
		AudioManager.set_master_volume(master_vol)
		AudioManager.set_bgm_volume(bgm_vol)
		AudioManager.set_sfx_volume(sfx_vol)

func _refresh_keybind_buttons():
	for action_name in _rebindable_actions:
		var btn = _rebind_buttons[action_name] as Button
		var saved_keycode = GlobalSave.get_key_binding(action_name)
		if saved_keycode != 0:
			btn.text = OS.get_keycode_string(saved_keycode as Key)
		else:
			# 显示默认按键
			btn.text = _get_default_key_name(action_name)

func _get_default_key_name(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0 and events[0] is InputEventKey:
		return OS.get_keycode_string(events[0].physical_keycode)
	return "未绑定"

func _update_volume_label(label: Label, value: float):
	label.text = "%d%%" % int(value * 100)

func _on_master_volume_changed(value: float):
	GlobalSave.set_setting("master_volume", value)
	_update_volume_label(master_label, value)
	if AudioManager:
		AudioManager.set_master_volume(value)

func _on_bgm_volume_changed(value: float):
	GlobalSave.set_setting("bgm_volume", value)
	_update_volume_label(bgm_label, value)
	if AudioManager:
		AudioManager.set_bgm_volume(value)

func _on_sfx_volume_changed(value: float):
	GlobalSave.set_setting("sfx_volume", value)
	_update_volume_label(sfx_label, value)
	if AudioManager:
		AudioManager.set_sfx_volume(value)

func _on_fullscreen_toggled(pressed: bool):
	fullscreen_check.text = "开启" if pressed else "关闭"
	if pressed:
		DisplayManager.set_fullscreen()
	else:
		DisplayManager.set_windowed()

# ── 按键绑定 ──────────────────────────────────────────

func _on_rebind_pressed(action_name: String):
	_waiting_action = action_name
	_waiting_label.visible = true
	# 高亮当前按钮
	for key in _rebind_buttons:
		_rebind_buttons[key].disabled = (key != action_name)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.physical_keycode
		if keycode == KEY_ESCAPE:
			if _waiting_action != "":
				# ESC 取消按键绑定
				_cancel_rebind()
			else:
				# ESC 关闭设置界面
				_on_back_pressed()
			get_viewport().set_input_as_handled()
			return
	if _waiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# 获取物理按键码
		var keycode = event.physical_keycode
		# 检查是否与已有绑定冲突
		var conflict_action = _find_key_conflict(keycode, _waiting_action)
		if conflict_action != "":
			# 交换：将冲突方设为当前动作的旧键
			var old_key = GlobalSave.get_key_binding(_waiting_action)
			GlobalSave.set_key_binding(conflict_action, old_key)
		# 设置新绑定
		GlobalSave.set_key_binding(_waiting_action, keycode)
		GlobalSave.apply_key_bindings()
		_waiting_action = ""
		_waiting_label.visible = false
		_refresh_keybind_buttons()
		# 恢复所有按钮
		for key in _rebind_buttons:
			_rebind_buttons[key].disabled = false
		get_viewport().set_input_as_handled()

func _find_key_conflict(keycode: int, exclude_action: String) -> String:
	for action_name in _rebindable_actions:
		if action_name == exclude_action:
			continue
		var saved = GlobalSave.get_key_binding(action_name)
		if saved == keycode:
			return action_name
	return ""

func _cancel_rebind():
	_waiting_action = ""
	_waiting_label.visible = false
	for key in _rebind_buttons:
		_rebind_buttons[key].disabled = false

func _on_reset_keybindings():
	GlobalSave.reset_key_bindings()
	# 重置 InputMap 为默认
	for action_name in _rebindable_actions:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
			# 重新添加默认事件
			match action_name:
				"move_up":
					var ev = InputEventKey.new(); ev.physical_keycode = KEY_W; ev.pressed = true
					InputMap.action_add_event(action_name, ev)
				"move_down":
					var ev = InputEventKey.new(); ev.physical_keycode = KEY_S; ev.pressed = true
					InputMap.action_add_event(action_name, ev)
				"move_left":
					var ev = InputEventKey.new(); ev.physical_keycode = KEY_A; ev.pressed = true
					InputMap.action_add_event(action_name, ev)
				"move_right":
					var ev = InputEventKey.new(); ev.physical_keycode = KEY_D; ev.pressed = true
					InputMap.action_add_event(action_name, ev)
	_refresh_keybind_buttons()

func _on_back_pressed():
	back_pressed.emit()