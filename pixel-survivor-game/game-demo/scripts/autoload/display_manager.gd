extends Node
## 显示管理器 —— 全屏/窗口切换、启动自动适配、F11快捷键

func _ready():
	# 启动时读取保存的全屏设置并应用
	var fs = GlobalSave.get_setting("fullscreen", false)
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# 窗口模式下居中窗口
		_center_window()

func _input(event: InputEvent):
	# F11 切换全屏
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			toggle_fullscreen()

## 切换全屏/窗口模式
func toggle_fullscreen():
	var was_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if was_fullscreen:
		set_windowed()
	else:
		set_fullscreen()

## 设置为全屏
func set_fullscreen():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GlobalSave.set_setting("fullscreen", true)

## 设置为窗口模式
func set_windowed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	GlobalSave.set_setting("fullscreen", false)
	# 切回窗口后居中
	_center_window()

## 将窗口居中到屏幕
func _center_window():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var pos = Vector2(screen_size - window_size) / 2.0
	DisplayServer.window_set_position(pos)

## 获取当前是否全屏
func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN