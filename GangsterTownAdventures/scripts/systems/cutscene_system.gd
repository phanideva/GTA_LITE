extends CanvasLayer
# Cinematic Cutscene System — GTA-style dialogue bars + typewriter text

signal cutscene_finished

const TYPEWRITER_SPEED = 42.0  # chars per second

var _active        := false
var _lines         := []
var _line_idx      := 0
var _char_timer    := 0.0
var _full_text     := ""
var _displayed     := ""
var _skip_pressed  := false

# UI nodes built in _ready
var _top_bar       : ColorRect
var _bot_bar       : ColorRect
var _speaker_label : Label
var _text_label    : Label
var _skip_hint     : Label
var _mission_title : Label   # big GTA-style mission card
var _title_timer   := 0.0

func is_active() -> bool:
	return _active or _title_timer > 0.0

func _ready():
	layer = 20
	_build_ui()
	hide()

func _build_ui():
	# ── Cinematic black bars ──
	_top_bar = ColorRect.new()
	_top_bar.color = Color(0, 0, 0, 0.88)
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.custom_minimum_size = Vector2(0, 90)
	add_child(_top_bar)

	_bot_bar = ColorRect.new()
	_bot_bar.color = Color(0, 0, 0, 0.88)
	_bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bot_bar.custom_minimum_size = Vector2(0, 130)
	add_child(_bot_bar)

	# ── Speaker name ──
	_speaker_label = Label.new()
	_speaker_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_speaker_label.position = Vector2(40, -126)
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(_speaker_label)

	# ── Dialogue text ──
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_text_label.position = Vector2(40, -98)
	_text_label.offset_left = 40
	_text_label.offset_right = -40
	_text_label.offset_bottom = -18
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text_label)

	# ── Skip hint ──
	_skip_hint = Label.new()
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.position = Vector2(-260, -22)
	_skip_hint.text = "[ ENTER ] Next"
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(_skip_hint)

	# ── Mission title card (big GTA center-screen flash) ──
	_mission_title = Label.new()
	_mission_title.set_anchors_preset(Control.PRESET_CENTER)
	_mission_title.offset_left = -400
	_mission_title.offset_right = 400
	_mission_title.offset_top = -60
	_mission_title.offset_bottom = 60
	_mission_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_title.add_theme_font_size_override("font_size", 52)
	_mission_title.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_mission_title.text = ""
	add_child(_mission_title)

# ─────────────────────────────────────────────────────
## Play a list of dialogue lines. Each line: {speaker, text}
func play(lines: Array):
	if lines.is_empty():
		return
	_lines    = lines
	_line_idx = 0
	_active   = true
	show()
	_show_line(_lines[0])
	# Pause gameplay
	if Globals.has_method("set_game_state"):
		Globals.set_game_state("cutscene")
	else:
		Globals.game_state = "cutscene"

## Flash a big mission title card (GTA style)
func show_mission_title(title: String, chapter: String = ""):
	show()
	_mission_title.text = (chapter + "\n" if chapter else "") + title
	_mission_title.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_title_timer = 4.0
	# Animate via tween
	var tw = create_tween()
	tw.tween_method(_set_title_alpha, 0.0, 1.0, 0.5)
	tw.tween_interval(2.2)
	tw.tween_method(_set_title_alpha, 1.0, 0.0, 0.8)
	tw.tween_callback(_on_title_done)

func _set_title_alpha(a: float):
	_mission_title.add_theme_color_override("font_color", Color(1, 0.9, 0.3, a))

func _on_title_done():
	_mission_title.text = ""
	if not _active:
		hide()

# ─────────────────────────────────────────────────────
func _show_line(line: Dictionary):
	_speaker_label.text = line.get("speaker", "")
	_full_text    = line.get("text", "")
	_displayed    = ""
	_char_timer   = 0.0
	_text_label.text = ""
	_skip_pressed = false

	# Colour-code known speakers
	var spk = _speaker_label.text.to_lower()
	if "rico" in spk:
		_speaker_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	elif "marco" in spk:
		_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	elif "police" in spk or "officer" in spk or "cop" in spk:
		_speaker_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	elif "don" in spk or "castellano" in spk:
		_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

func _process(delta):
	if not _active:
		# Title card fading
		return

	# Typewriter effect
	if _displayed.length() < _full_text.length():
		_char_timer += delta * TYPEWRITER_SPEED
		var chars = int(_char_timer)
		_char_timer -= chars
		_displayed = _full_text.substr(0, min(_displayed.length() + chars, _full_text.length()))
		_text_label.text = _displayed
		return

	# Line fully shown — wait for input
	_text_label.text = _full_text
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
		_advance()

func _advance():
	_line_idx += 1
	if _line_idx >= _lines.size():
		_finish()
	else:
		_show_line(_lines[_line_idx])

func _finish():
	_active = false
	hide()
	Globals.game_state = "playing"
	emit_signal("cutscene_finished")

func _input(event):
	# Allow ESC to skip entire cutscene
	if _active and event.is_action_pressed("ui_cancel"):
		_finish()
