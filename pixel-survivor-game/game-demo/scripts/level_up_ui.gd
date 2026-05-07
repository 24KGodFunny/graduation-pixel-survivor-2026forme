extends CanvasLayer

var choice_container: VBoxContainer
var is_showing: bool = false

func _ready():
	layer = 10
	visible = false
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(panel)
	
	var title = Label.new()
	title.text = "LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	choice_container = VBoxContainer.new()
	panel.add_child(choice_container)
	
	GameManager.player_leveled_up.connect(_on_level_up)

func _on_level_up(_new_level):
	if GameManager.current_state == GameManager.GameState.LEVEL_UP:
		_show_choices()

func _show_choices():
	# Clear old choices
	for c in choice_container.get_children():
		c.queue_free()
	
	var choices = GameManager.get_level_up_choices()
	for choice in choices:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(350, 50)
		match choice["type"]:
			"weapon":
				var wdata = Database.weapons[choice["id"]]
				if choice["is_new"]:
					btn.text = "[NEW] " + wdata["name"] + " - " + wdata["description"]
				else:
					btn.text = wdata["name"] + " Lv.UP"
			"passive":
				var pdata = Database.passive_items[choice["id"]]
				if choice["is_new"]:
					btn.text = "[NEW] " + pdata["name"] + " - " + pdata["description"]
				else:
					btn.text = pdata["name"] + " Lv.UP"
			"heal":
				btn.text = "恢复 25% 生命值"
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(btn)
	
	visible = true
	is_showing = true

func _on_choice_selected(choice: Dictionary):
	visible = false
	is_showing = false
	GameManager.apply_level_up_choice(choice)
