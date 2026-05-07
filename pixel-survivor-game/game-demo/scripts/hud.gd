extends CanvasLayer

var hp_bar: ProgressBar
var exp_bar: ProgressBar
var time_label: Label
var level_label: Label
var kill_label: Label
var coin_label: Label
var weapon_icons: HBoxContainer

func _ready():
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 16)
	hp_bar.max_value = 1.0
	hp_bar.value = 1.0
	vbox.add_child(hp_bar)
	
	# EXP Bar
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(200, 8)
	exp_bar.max_value = 1.0
	exp_bar.value = 0.0
	vbox.add_child(exp_bar)
	
	# Info labels
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	level_label = Label.new()
	level_label.text = "Lv.1"
	hbox.add_child(level_label)
	
	time_label = Label.new()
	time_label.text = "00:00"
	hbox.add_child(time_label)
	
	kill_label = Label.new()
	kill_label.text = "Kills: 0"
	hbox.add_child(kill_label)
	
	coin_label = Label.new()
	coin_label.text = "💰 0"
	hbox.add_child(coin_label)
	
	# Weapon icons
	weapon_icons = HBoxContainer.new()
	weapon_icons.position = Vector2(0, 50)
	vbox.add_child(weapon_icons)
	
	GameManager.player_damaged.connect(_on_player_damaged)
	GameManager.player_healed.connect(_on_player_healed)
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.enemy_killed.connect(_on_enemy_killed)

func _process(_delta):
	if GameManager.current_state == GameManager.GameState.PLAYING:
		hp_bar.value = float(GameManager.player_hp) / float(GameManager.player_max_hp)
		var exp_needed = Database.get_exp_for_level(GameManager.player_level)
		exp_bar.value = float(GameManager.player_exp) / float(exp_needed)
		coin_label.text = "💰 " + str(GameManager.player_coins)

func _on_player_damaged(hp, max_hp):
	hp_bar.value = float(hp) / float(max_hp)

func _on_player_healed(_amount):
	hp_bar.value = float(GameManager.player_hp) / float(GameManager.player_max_hp)

func _on_level_up(new_level):
	level_label.text = "Lv." + str(new_level)

func _on_time_updated(_seconds):
	time_label.text = GameManager.get_game_time_string()

func _on_enemy_killed(_pos, _exp_amount):
	kill_label.text = "Kills: " + str(GameManager.kill_count)
	coin_label.text = "💰 " + str(GameManager.player_coins)
