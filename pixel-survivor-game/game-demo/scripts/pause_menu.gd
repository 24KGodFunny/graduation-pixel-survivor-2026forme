extends CanvasLayer

func _ready():
	layer = 10
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
	vbox.add_child(resume_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "返回主菜单"
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

func _input(event):
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
			visible = true
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			_on_resume()

func _on_resume():
	visible = false
	GameManager.resume_game()

func _on_quit():
	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
