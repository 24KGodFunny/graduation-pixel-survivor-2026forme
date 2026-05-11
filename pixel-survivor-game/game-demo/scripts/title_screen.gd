extends Control
## Title screen - pixel-style main menu with Start / Settings / Exit

var _time: float = 0.0
var _buttons: Array[Button] = []
var _selected_index: int = 0

func _ready():
	# Play menu BGM
	if AudioManager:
		AudioManager.play_bgm("res://assets/audio/bgm_menu.wav")
	# Full-screen background image
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://assets/images/ui/panel_bg.png"):
		bg_tex.texture = load("res://assets/images/ui/panel_bg.png")
	else:
		# Fallback: dark color
		var bg = ColorRect.new()
		bg.color = Color(0.05, 0.03, 0.12)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		bg_tex = null
	if bg_tex:
		add_child(bg_tex)

	# Decorative pixel grid lines (subtle)
	for i in range(8):
		var line = ColorRect.new()
		line.color = Color(0.15, 0.12, 0.25, 0.3)
		line.position = Vector2(0, 90 * i)
		line.size = Vector2(1280, 1)
		add_child(line)

	# === Title area (center-top) ===
	var title_container = VBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_container.position = Vector2(0, 80)
	title_container.size = Vector2(600, 200)
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(title_container)

	# Main title with pixel shadow effect
	var title_shadow = Label.new()
	title_shadow.text = "像 素 幸 存 者"
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.add_theme_font_size_override("font_size", 58)
	title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.6))
	title_shadow.position = Vector2(3, 3)
	title_container.add_child(title_shadow)

	var title = Label.new()
	title.name = "Title"
	title.text = "像 素 幸 存 者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title_container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "PIXEL SURVIVOR"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.8))
	title_container.add_child(subtitle)

	# Decorative separator
	var sep = Label.new()
	sep.text = "══════════════════════"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", 14)
	sep.add_theme_color_override("font_color", Color(0.3, 0.25, 0.5, 0.6))
	title_container.add_child(sep)

	# === Buttons (bottom-left) ===
	var btn_container = VBoxContainer.new()
	btn_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn_container.position = Vector2(60, -260)
	btn_container.size = Vector2(300, 240)
	btn_container.add_theme_constant_override("separation", 12)
	add_child(btn_container)

	# Create pixel-style buttons
	var btn_data = [
		{"text": "▶ 开 始 游 戏", "callback": _on_start_pressed},
		{"text": "⚙ 设　　置", "callback": _on_settings_pressed},
		{"text": "✕ 退 出 游 戏", "callback": _on_exit_pressed},
	]

	for i in range(btn_data.size()):
		var btn = Button.new()
		btn.text = btn_data[i]["text"]
		btn.custom_minimum_size = Vector2(280, 52)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.3))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.7, 0.1))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Pixel-style button background
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.12, 0.1, 0.2, 0.85)
		normal_style.border_color = Color(0.4, 0.35, 0.6)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(0)  # Sharp pixel corners
		normal_style.content_margin_left = 20
		normal_style.content_margin_right = 20
		normal_style.content_margin_top = 8
		normal_style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", normal_style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.15, 0.35, 0.95)
		hover_style.border_color = Color(1.0, 0.85, 0.2)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(0)
		hover_style.content_margin_left = 20
		hover_style.content_margin_right = 20
		hover_style.content_margin_top = 8
		hover_style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.3, 0.2, 0.5, 1.0)
		pressed_style.border_color = Color(1.0, 0.7, 0.1)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(0)
		pressed_style.content_margin_left = 20
		pressed_style.content_margin_right = 20
		pressed_style.content_margin_top = 8
		pressed_style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.pressed.connect(_on_btn_click)
		btn.pressed.connect(btn_data[i]["callback"])
		btn.modulate.a = 0.0  # Start invisible for fade-in
		btn_container.add_child(btn)
		_buttons.append(btn)

	# === Version (bottom-right) ===
	var version = Label.new()
	version.text = "v0.1 Demo"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.35, 0.3, 0.5))
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-130, -30)
	version.size = Vector2(110, 20)
	add_child(version)

	# === Hint text (bottom-center) ===
	var hint = Label.new()
	hint.name = "Hint"
	hint.text = "↑↓ 选择  Enter 确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	hint.anchor_left = 0.5
	hint.anchor_top = 1.0
	hint.anchor_right = 0.5
	hint.anchor_bottom = 1.0
	hint.position = Vector2(-100, -30)
	hint.size = Vector2(200, 20)
	add_child(hint)

	# Start button fade-in animation
	_animate_buttons_in()

func _animate_buttons_in():
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		var tween = create_tween()
		tween.tween_interval(0.3 + i * 0.2)
		tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _process(delta):
	_time += delta

	# Title breathing glow
	var title_node = get_node_or_null("Title")
	if title_node:
		var glow = 0.85 + 0.15 * sin(_time * 1.5)
		title_node.add_theme_color_override("font_color", Color(1.0 * glow, 0.85 * glow, 0.2 * glow))

	# Subtitle subtle pulse
	var subtitle_node = get_node_or_null("Subtitle")
	if subtitle_node:
		var alpha = 0.5 + 0.2 * sin(_time * 1.2 + 1.0)
		subtitle_node.add_theme_color_override("font_color", Color(0.6, 0.55, 0.8, alpha))

	# Keyboard navigation highlight
	if _buttons.size() > 0:
		for i in range(_buttons.size()):
			if i == _selected_index:
				_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			else:
				_buttons[i].add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				_selected_index = (_selected_index - 1 + _buttons.size()) % _buttons.size()
			KEY_DOWN, KEY_S:
				_selected_index = (_selected_index + 1) % _buttons.size()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if _selected_index < _buttons.size():
					_buttons[_selected_index].emit_signal("pressed")

func _on_btn_click():
	AudioManager.play_sfx("res://assets/audio/sfx_click.wav")

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_settings_pressed():
	var settings_script = load("res://scripts/settings_ui.gd")
	var settings_ui = settings_script.new()
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_ui)
	settings_ui.back_pressed.connect(func():
		settings_ui.queue_free()
	)

func _on_exit_pressed():
	get_tree().quit()