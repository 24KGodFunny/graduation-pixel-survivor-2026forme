extends Node
## DialogueManager autoload - handles dialogue display with typewriter effect

signal dialogue_started(dialogue_key: String)
signal dialogue_finished(dialogue_key: String)
signal dialogue_line_started(speaker: String, text: String)
signal dialogue_line_finished(speaker: String, text: String)

var is_active: bool = false
var current_key: String = ""
var current_lines: Array = []
var current_line_index: int = 0
var current_text: String = ""
var displayed_chars: int = 0
var typewriter_speed: float = 0.03  # seconds per character
var typewriter_timer: float = 0.0
var is_typing: bool = false
var skip_requested: bool = false

# UI references (set by dialogue_ui.gd)
var ui_node: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if not is_active or not is_typing:
		return
	
	typewriter_timer += delta
	if skip_requested:
		displayed_chars = current_text.length()
		is_typing = false
		skip_requested = false
		if ui_node:
			ui_node.update_text(current_text)
		dialogue_line_finished.emit(current_lines[current_line_index]["speaker"], current_text)
		return
	
	if typewriter_timer >= typewriter_speed:
		typewriter_timer = 0.0
		displayed_chars += 1
		if ui_node:
			ui_node.update_text(current_text.substr(0, displayed_chars))
		if displayed_chars >= current_text.length():
			is_typing = false
			dialogue_line_finished.emit(current_lines[current_line_index]["speaker"], current_text)

func start_dialogue(dialogue_key: String):
	if not Database.story_dialogues.has(dialogue_key):
		return
	
	current_key = dialogue_key
	current_lines = Database.story_dialogues[dialogue_key]
	current_line_index = 0
	is_active = true
	
	GameManager.current_state = GameManager.GameState.DIALOGUE
	dialogue_started.emit(dialogue_key)
	_show_current_line()

func _show_current_line():
	if current_line_index >= current_lines.size():
		_end_dialogue()
		return
	
	var line = current_lines[current_line_index]
	current_text = line["text"]
	displayed_chars = 0
	is_typing = true
	typewriter_timer = 0.0
	
	if ui_node:
		ui_node.show_dialogue(line["speaker"], current_text)
	dialogue_line_started.emit(line["speaker"], current_text)

func advance():
	if not is_active:
		return
	
	if is_typing:
		# Skip to end of current line
		skip_requested = true
	else:
		# Move to next line
		current_line_index += 1
		_show_current_line()

func _end_dialogue():
	is_active = false
	current_key = ""
	if ui_node:
		ui_node.hide_dialogue()
	dialogue_finished.emit(current_key)
	GameManager.current_state = GameManager.GameState.PLAYING

func skip_all():
	_end_dialogue()