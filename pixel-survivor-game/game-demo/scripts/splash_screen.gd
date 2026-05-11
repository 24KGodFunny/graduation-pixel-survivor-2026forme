extends Control
## Splash screen - title page with "click to enter" prompt

var _time: float = 0.0

func _ready():
	# Background image
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://assets/images/ui/splash_bg.png"):
		bg_tex.texture = load("res://assets/images/ui/splash_bg.png")
		add_child(bg_tex)
	else:
		# Fallback: solid dark color
		var bg = ColorRect.new()
		bg.color = Color(0.08, 0.06, 0.15)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		bg.owner = self
	
	# Title label
	var title = Label.new()
	title.text = "像 素 幸 存 者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-200, -80)
	title.size = Vector2(400, 80)
	add_child(title)
	title.owner = self
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "PIXEL SURVIVOR"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-150, -10)
	subtitle.size = Vector2(300, 30)
	add_child(subtitle)
	subtitle.owner = self
	
	# Click prompt
	var prompt = Label.new()
	prompt.name = "ClickPrompt"
	prompt.text = "点击进入游戏"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.position = Vector2(-100, 100)
	prompt.size = Vector2(200, 30)
	add_child(prompt)
	prompt.owner = self
	
	# Version
	var version = Label.new()
	version.text = "v0.1 Demo"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-120, -30)
	version.size = Vector2(100, 20)
	add_child(version)
	version.owner = self

func _process(delta):
	_time += delta
	# Breathing animation for click prompt
	var prompt_node = get_node_or_null("ClickPrompt")
	if prompt_node:
		var alpha = 0.4 + 0.6 * abs(sin(_time * 2.0))
		prompt_node.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, alpha))

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	elif event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
