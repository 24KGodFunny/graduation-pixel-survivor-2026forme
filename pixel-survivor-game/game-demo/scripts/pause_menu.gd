extends CanvasLayer

var _settings_ui: Control = null

func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var resume_btn = Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.pressed.connect(_on_resume)
	resume_btn.pressed.connect(_click)
	vbox.add_child(resume_btn)
	
	var settings_btn = Button.new()
	settings_btn.text = "⚙ 设置"
	settings_btn.pressed.connect(_on_settings)
	settings_btn.pressed.connect(_click)
	vbox.add_child(settings_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "返回主菜单"
	quit_btn.pressed.connect(_on_quit)
	quit_btn.pressed.connect(_click)
	vbox.add_child(quit_btn)

func _click():
	AudioManager.play_sfx("res://assets/audio/sfx_click.wav")

func _input(event):
	if event.is_action_pressed("pause"):
		if _settings_ui != null and is_instance_valid(_settings_ui):
			# 设置界面打开时，按 ESC 关闭设置
			_on_settings_back()
			get_viewport().set_input_as_handled()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
			visible = true
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			_on_resume()

func _on_resume():
	visible = false
	GameManager.resume_game()

func _on_settings():
	var settings_scene = load("res://scripts/settings_ui.gd")
	_settings_ui = Control.new()
	_settings_ui.set_script(settings_scene)
	_settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_ui.back_pressed.connect(_on_settings_back)
	add_child(_settings_ui)

func _on_settings_back():
	if _settings_ui != null and is_instance_valid(_settings_ui):
		_settings_ui.queue_free()
		_settings_ui = null

func _on_quit():
	# 先设置状态为 MENU，防止场景切换过程中触发游戏逻辑
	GameManager.current_state = GameManager.GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
