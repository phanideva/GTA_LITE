extends CanvasLayer
# Dialogue System — GTA-style text boxes with character names and typewriter effect

class_name DialogueSystem

signal dialogue_finished

var dialogue_queue: Array = []
var current_line = 0
var is_active = false
var typewriter_timer = 0.0
var char_index = 0
var current_text = ""
var full_text = ""
var skip_typewriter = false

# UI elements
var panel: PanelContainer
var name_label: Label
var text_label: Label
var continue_label: Label
var portrait_bg: ColorRect

const TYPEWRITER_SPEED = 0.03  # Seconds per character

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()
	visible = false

func _build_ui():
	# Dark panel at bottom of screen
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -180
	panel.offset_bottom = -20
	panel.offset_left = 60
	panel.offset_right = -60
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.92)
	style.border_color = Color(0.95, 0.7, 0.1, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Character name
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1))
	vbox.add_child(name_label)
	
	# Dialogue text
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(text_label)
	
	# Continue prompt
	continue_label = Label.new()
	continue_label.text = "Press SPACE to continue..."
	continue_label.add_theme_font_size_override("font_size", 14)
	continue_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(continue_label)

func show_dialogue(lines: Array):
	# lines = [{"speaker": "Name", "text": "Line..."}, ...]
	dialogue_queue = lines
	current_line = 0
	is_active = true
	visible = true
	_show_current_line()

func _show_current_line():
	if current_line >= dialogue_queue.size():
		_end_dialogue()
		return
	
	var line = dialogue_queue[current_line]
	name_label.text = line.get("speaker", "")
	full_text = line.get("text", "")
	current_text = ""
	char_index = 0
	skip_typewriter = false
	text_label.text = ""
	typewriter_timer = 0.0
	
	# Color code speakers
	var speaker = line.get("speaker", "")
	if "Boss" in speaker or "Marco" in speaker:
		name_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.1))
	elif "Police" in speaker or "Chief" in speaker:
		name_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
	elif "Player" in speaker or "Rico" in speaker:
		name_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		name_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1))

func _process(delta):
	if not is_active:
		return
	
	# Typewriter effect
	if char_index < full_text.length():
		typewriter_timer += delta
		if skip_typewriter:
			current_text = full_text
			char_index = full_text.length()
			text_label.text = current_text
		elif typewriter_timer >= TYPEWRITER_SPEED:
			typewriter_timer = 0.0
			char_index += 1
			current_text = full_text.substr(0, char_index)
			text_label.text = current_text
		continue_label.text = "Press SPACE to skip..."
	else:
		continue_label.text = "Press SPACE to continue..."

func _input(event):
	if not is_active:
		return
	if event.is_action_pressed("jump"):  # Space
		if char_index < full_text.length():
			# Skip typewriter — show full text
			skip_typewriter = true
		else:
			# Advance to next line
			current_line += 1
			_show_current_line()
		get_viewport().set_input_as_handled()

func _end_dialogue():
	is_active = false
	visible = false
	dialogue_queue = []
	emit_signal("dialogue_finished")

func is_dialogue_active() -> bool:
	return is_active
