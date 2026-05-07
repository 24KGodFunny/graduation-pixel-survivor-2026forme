extends CanvasLayer
## Dialogue UI - displays dialogue boxes with typewriter effect

var panel: PanelContainer
var speaker_label: Label
var text_label: Label
var continue_label: Label
var is_displaying: bool = false

func _ready():
	visible = false
	# Use scene-defined nodes
	panel = $Panel
	speaker_label = $Panel/VBox/SpeakerLabel
	text_label = $Panel/VBox/TextLabel
	continue_label = $Panel/VBox/ContinueLabel
	if continue_label:
		continue_label.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.dialogue_line_started.connect(_on_dialogue_line_started)
	DialogueManager.ui_node = self

func _input(event):
	if not is_displaying:
		return
	if event.is_action_pressed("dialogue_advance") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		DialogueManager.advance()

func show_dialogue(speaker: String, text: String):
	visible = true
	is_displaying = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if continue_label:
		continue_label.visible = false

func update_text(text: String):
	if text_label:
		text_label.text = text

func hide_dialogue():
	visible = false
	is_displaying = false

func _on_dialogue_started(_dialogue_key: String):
	visible = true
	is_displaying = true

func _on_dialogue_finished(_dialogue_key: String):
	visible = false
	is_displaying = false

func _on_dialogue_line_started(speaker: String, text: String):
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if continue_label:
		continue_label.visible = false

func _on_dialogue_line_finished(_speaker: String, _text: String):
	if continue_label:
		continue_label.visible = true