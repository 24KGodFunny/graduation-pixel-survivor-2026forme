extends Control
## Boss Health Bar - displayed at top of screen during boss fights

var boss_name: String = ""
var current_hp: float = 0.0
var max_hp: float = 1.0
var hp_bar_width: float = 400.0
var hp_bar_height: float = 16.0
var bar_visible: bool = false
var target_hp_ratio: float = 1.0
var display_hp_ratio: float = 1.0
var flash_timer: float = 0.0
var phase: int = 1
var max_phases: int = 1

func _ready():
	visible = false
	# Cover full screen so _draw() coordinates match viewport coordinates
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	if not bar_visible:
		return
	# Smooth HP bar
	target_hp_ratio = current_hp / max_hp if max_hp > 0 else 0.0
	display_hp_ratio = lerpf(display_hp_ratio, target_hp_ratio, delta * 5.0)
	# Flash on damage
	if flash_timer > 0:
		flash_timer -= delta
	queue_redraw()

func show_boss(p_name: String, p_max_hp: float, p_phases: int = 1):
	boss_name = p_name
	max_hp = p_max_hp
	current_hp = p_max_hp
	max_phases = p_phases
	phase = 1
	display_hp_ratio = 1.0
	bar_visible = true
	visible = true

func update_hp(hp: float):
	if hp < current_hp:
		flash_timer = 0.15
	current_hp = hp

func hide_bar():
	bar_visible = false
	visible = false

func _draw():
	if not bar_visible:
		return
	var vp_size = get_viewport_rect().size
	var bar_x = (vp_size.x - hp_bar_width) / 2.0
	var bar_y = 15.0
	
	# Background
	draw_rect(Rect2(bar_x - 2, bar_y - 2, hp_bar_width + 4, hp_bar_height + 4), Color(0.0, 0.0, 0.0, 0.8))
	
	# HP bar background
	draw_rect(Rect2(bar_x, bar_y, hp_bar_width, hp_bar_height), Color(0.2, 0.1, 0.1))
	
	# HP bar (smooth)
	var bar_color = Color(0.8, 0.1, 0.1)
	if flash_timer > 0:
		bar_color = Color(1.0, 0.8, 0.8)
	draw_rect(Rect2(bar_x, bar_y, hp_bar_width * display_hp_ratio, hp_bar_height), bar_color)
	
	# Current HP (instant)
	var instant_color = Color(0.6, 0.05, 0.05, 0.5)
	draw_rect(Rect2(bar_x, bar_y, hp_bar_width * target_hp_ratio, hp_bar_height), instant_color)
	
	# Border
	draw_rect(Rect2(bar_x - 2, bar_y - 2, hp_bar_width + 4, hp_bar_height + 4), Color(0.8, 0.3, 0.3, 0.6), false, 2.0)
	
	# Boss name
	draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 6), boss_name, HORIZONTAL_ALIGNMENT_CENTER, hp_bar_width, 14, Color(1.0, 0.8, 0.8))
	
	# Phase indicator
	if max_phases > 1:
		var phase_text = "Phase %d / %d" % [phase, max_phases]
		draw_string(ThemeDB.fallback_font, Vector2(bar_x + hp_bar_width - 80, bar_y - 6), phase_text, HORIZONTAL_ALIGNMENT_RIGHT, 80, 11, Color(0.7, 0.7, 0.7))
	
	# HP text
	var hp_text = "%d / %d" % [int(current_hp), int(max_hp)]
	draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y + 12), hp_text, HORIZONTAL_ALIGNMENT_CENTER, hp_bar_width, 12, Color.WHITE)