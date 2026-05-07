extends Control
## Login/Register UI - handles user authentication

var is_login_mode: bool = true
var username_input: LineEdit
var password_input: LineEdit
var nickname_input: LineEdit
var message_label: Label
var title_label: Label
var switch_btn: Button
var submit_btn: Button
var nickname_container: HBoxContainer

func _ready():
	_build_ui()
	_connect_signals()

func _build_ui():
	# 半透明背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	add_child(bg)
	
	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# 主面板
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 350)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# 标题
	title_label = Label.new()
	title_label.text = "用户登录"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	vbox.add_child(title_label)
	
	# 用户名
	var username_hbox = HBoxContainer.new()
	vbox.add_child(username_hbox)
	var username_label = Label.new()
	username_label.text = "用户名:"
	username_label.custom_minimum_size = Vector2(80, 0)
	username_hbox.add_child(username_label)
	username_input = LineEdit.new()
	username_input.placeholder_text = "请输入用户名"
	username_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	username_hbox.add_child(username_input)
	
	# 密码
	var password_hbox = HBoxContainer.new()
	vbox.add_child(password_hbox)
	var password_label = Label.new()
	password_label.text = "密码:"
	password_label.custom_minimum_size = Vector2(80, 0)
	password_hbox.add_child(password_label)
	password_input = LineEdit.new()
	password_input.placeholder_text = "请输入密码"
	password_input.secret = true
	password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	password_hbox.add_child(password_input)
	
	# 昵称（注册模式显示）
	nickname_container = HBoxContainer.new()
	nickname_container.visible = false
	vbox.add_child(nickname_container)
	var nickname_label = Label.new()
	nickname_label.text = "昵称:"
	nickname_label.custom_minimum_size = Vector2(80, 0)
	nickname_container.add_child(nickname_label)
	nickname_input = LineEdit.new()
	nickname_input.placeholder_text = "请输入昵称（可选）"
	nickname_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nickname_container.add_child(nickname_input)
	
	# 消息提示
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(message_label)
	
	# 按钮区域
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	submit_btn = Button.new()
	submit_btn.text = "登录"
	submit_btn.custom_minimum_size = Vector2(120, 40)
	submit_btn.pressed.connect(_on_submit)
	btn_hbox.add_child(submit_btn)
	
	switch_btn = Button.new()
	switch_btn.text = "切换到注册"
	switch_btn.custom_minimum_size = Vector2(120, 40)
	switch_btn.pressed.connect(_on_switch_mode)
	btn_hbox.add_child(switch_btn)
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "返回主菜单"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

func _connect_signals():
	NetworkManager.login_success.connect(_on_login_success)
	NetworkManager.login_failed.connect(_on_login_failed)
	NetworkManager.register_success.connect(_on_register_success)
	NetworkManager.register_failed.connect(_on_register_failed)

func _on_submit():
	var user = username_input.text.strip_edges()
	var pwd = password_input.text.strip_edges()
	
	if user == "" or pwd == "":
		_show_message("用户名和密码不能为空")
		return
	
	if is_login_mode:
		NetworkManager.login(user, pwd)
	else:
		var nick = nickname_input.text.strip_edges()
		NetworkManager.register(user, pwd, nick)

func _on_switch_mode():
	is_login_mode = !is_login_mode
	if is_login_mode:
		title_label.text = "用户登录"
		submit_btn.text = "登录"
		switch_btn.text = "切换到注册"
		nickname_container.visible = false
	else:
		title_label.text = "用户注册"
		submit_btn.text = "注册"
		switch_btn.text = "切换到登录"
		nickname_container.visible = true
	_clear_message()

func _on_back():
	queue_free()

func _on_login_success(_data: Dictionary):
	_show_message("登录成功！", Color(0.3, 1.0, 0.3))
	# 延迟关闭界面
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_login_failed(error: String):
	_show_message("登录失败: " + error)

func _on_register_success(_data: Dictionary):
	_show_message("注册成功！请登录", Color(0.3, 1.0, 0.3))
	# 自动切换到登录模式
	await get_tree().create_timer(1.0).timeout
	is_login_mode = true
	title_label.text = "用户登录"
	submit_btn.text = "登录"
	switch_btn.text = "切换到注册"
	nickname_container.visible = false
	_clear_message()

func _on_register_failed(error: String):
	_show_message("注册失败: " + error)

func _show_message(text: String, color: Color = Color(1.0, 0.3, 0.3)):
	if message_label:
		message_label.text = text
		message_label.add_theme_color_override("font_color", color)

func _clear_message():
	if message_label:
		message_label.text = ""