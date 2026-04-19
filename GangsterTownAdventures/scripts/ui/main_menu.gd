extends Control
# Main Menu — GTA-style cinematic intro with music and animated title

var buttons: Array = []
var intro_phase = 0
var intro_timer = 0.0
var intro_elements: Array = []
var skip_intro = false
var menu_built = false
var intro_music: AudioStreamPlayer = null
var menu_music: AudioStreamPlayer = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_start_intro()

func _process(delta):
	if not menu_built:
		intro_timer += delta
		_update_intro(delta)

func _input(event):
	if not menu_built and event is InputEventKey and event.pressed:
		skip_intro = true

func _start_intro():
	# Full black background
	var bg = ColorRect.new()
	bg.name = "IntroBG"
	bg.color = Color(0.0, 0.0, 0.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Play intro music
	intro_music = AudioStreamPlayer.new()
	intro_music.name = "IntroMusic"
	intro_music.bus = "Master"
	intro_music.volume_db = -6.0
	add_child(intro_music)
	var music_stream = SFX.generate_intro_music()
	if music_stream:
		intro_music.stream = music_stream
		intro_music.play()

	# Phase 0: Studio/Creator credit (0-3s)
	var studio = Label.new()
	studio.name = "StudioLabel"
	studio.text = "PHANTOM DEV STUDIOS"
	studio.add_theme_font_size_override("font_size", 38)
	studio.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 0.0))
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	studio.set_anchors_preset(PRESET_CENTER)
	studio.position = Vector2(-300, -50)
	studio.size = Vector2(600, 50)
	add_child(studio)
	intro_elements.append(studio)

	var creator = Label.new()
	creator.name = "CreatorLabel"
	creator.text = "A Game by Phaneendra D"
	creator.add_theme_font_size_override("font_size", 22)
	creator.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.0))
	creator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creator.set_anchors_preset(PRESET_CENTER)
	creator.position = Vector2(-300, 10)
	creator.size = Vector2(600, 30)
	add_child(creator)
	intro_elements.append(creator)

	# Decorative line under studio name
	var line1 = ColorRect.new()
	line1.name = "StudioLine"
	line1.color = Color(0.95, 0.7, 0.1, 0.0)
	line1.set_anchors_preset(PRESET_CENTER)
	line1.position = Vector2(-100, 45)
	line1.size = Vector2(200, 2)
	add_child(line1)
	intro_elements.append(line1)

	# Phase 1: Engine credit (3-5.5s)
	var engine = Label.new()
	engine.name = "EngineLabel"
	engine.text = "Powered by Godot Engine 4"
	engine.add_theme_font_size_override("font_size", 24)
	engine.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 0.0))
	engine.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	engine.set_anchors_preset(PRESET_CENTER)
	engine.position = Vector2(-300, -15)
	engine.size = Vector2(600, 35)
	add_child(engine)
	intro_elements.append(engine)

	# Phase 2: Title reveal (5.5-12s) — GTA style big title with color bars
	var title_bar_top = ColorRect.new()
	title_bar_top.name = "TitleBarTop"
	title_bar_top.color = Color(0.95, 0.7, 0.1, 0.0)
	title_bar_top.set_anchors_preset(PRESET_CENTER)
	title_bar_top.position = Vector2(-350, -110)
	title_bar_top.size = Vector2(700, 4)
	add_child(title_bar_top)
	intro_elements.append(title_bar_top)

	var title1 = Label.new()
	title1.name = "Title1"
	title1.text = "GANGSTER  TOWN"
	title1.add_theme_font_size_override("font_size", 96)
	title1.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1, 0.0))
	title1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title1.set_anchors_preset(PRESET_CENTER)
	title1.position = Vector2(-450, -100)
	title1.size = Vector2(900, 110)
	add_child(title1)
	intro_elements.append(title1)

	var title2 = Label.new()
	title2.name = "Title2"
	title2.text = "A  D  V  E  N  T  U  R  E  S"
	title2.add_theme_font_size_override("font_size", 36)
	title2.add_theme_color_override("font_color", Color(0.9, 0.35, 0.1, 0.0))
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.set_anchors_preset(PRESET_CENTER)
	title2.position = Vector2(-450, 20)
	title2.size = Vector2(900, 45)
	add_child(title2)
	intro_elements.append(title2)

	var title_bar_bot = ColorRect.new()
	title_bar_bot.name = "TitleBarBot"
	title_bar_bot.color = Color(0.9, 0.35, 0.1, 0.0)
	title_bar_bot.set_anchors_preset(PRESET_CENTER)
	title_bar_bot.position = Vector2(-350, 70)
	title_bar_bot.size = Vector2(700, 3)
	add_child(title_bar_bot)
	intro_elements.append(title_bar_bot)

	var tagline = Label.new()
	tagline.name = "Tagline"
	tagline.text = "The streets are yours."
	tagline.add_theme_font_size_override("font_size", 22)
	tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.0))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.set_anchors_preset(PRESET_CENTER)
	tagline.position = Vector2(-450, 85)
	tagline.size = Vector2(900, 30)
	add_child(tagline)
	intro_elements.append(tagline)

	# "Press any key" prompt
	var press = Label.new()
	press.name = "PressLabel"
	press.text = "Press  Start  Game  to  begin"
	press.add_theme_font_size_override("font_size", 18)
	press.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.0))
	press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press.set_anchors_preset(PRESET_CENTER)
	press.position = Vector2(-300, 140)
	press.size = Vector2(600, 25)
	add_child(press)
	intro_elements.append(press)

	# Skip prompt
	var skip_lbl = Label.new()
	skip_lbl.name = "SkipLabel"
	skip_lbl.text = "Press any key to skip"
	skip_lbl.add_theme_font_size_override("font_size", 14)
	skip_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_lbl.set_anchors_preset(PRESET_BOTTOM_WIDE)
	skip_lbl.position.y = -40
	add_child(skip_lbl)
	intro_elements.append(skip_lbl)

func _update_intro(_delta):
	if skip_intro or intro_timer > 13.0:
		_finish_intro()
		return

	var t = intro_timer
	# Phase 0: Studio name + creator + decorative line (0-3.5s)
	var studio = get_node_or_null("StudioLabel")
	var creator = get_node_or_null("CreatorLabel")
	var sline = get_node_or_null("StudioLine")
	if studio:
		if t < 0.8:
			var a = t / 0.8
			studio.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, a))
			creator.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, a))
			if sline: sline.color = Color(0.95, 0.7, 0.1, a)
		elif t < 2.5:
			studio.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1.0))
			creator.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1.0))
			if sline: sline.color = Color(0.95, 0.7, 0.1, 1.0)
		elif t < 3.5:
			var fade = 1.0 - (t - 2.5) / 1.0
			studio.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, fade))
			creator.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, fade))
			if sline: sline.color = Color(0.95, 0.7, 0.1, fade)
		else:
			studio.visible = false
			creator.visible = false
			if sline: sline.visible = false

	# Phase 1: Engine credit (3.5-5.5s)
	var engine = get_node_or_null("EngineLabel")
	if engine:
		if t < 3.5:
			engine.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 0.0))
		elif t < 4.2:
			engine.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, (t - 3.5) / 0.7))
		elif t < 5.0:
			engine.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 1.0))
		elif t < 5.8:
			engine.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 1.0 - (t - 5.0) / 0.8))
		else:
			engine.visible = false

	# Phase 2: GTA-style title reveal (6-13s)
	var tbar_top = get_node_or_null("TitleBarTop")
	var t1 = get_node_or_null("Title1")
	var t2 = get_node_or_null("Title2")
	var tbar_bot = get_node_or_null("TitleBarBot")
	var tag = get_node_or_null("Tagline")
	var press = get_node_or_null("PressLabel")

	if tbar_top and t >= 6.0:
		var a = clamp((t - 6.0) / 0.3, 0.0, 1.0)
		tbar_top.color = Color(0.95, 0.7, 0.1, a)
	if t1 and t >= 6.2:
		var a = clamp((t - 6.2) / 0.8, 0.0, 1.0)
		t1.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1, a))
	if t2 and t >= 7.2:
		var a = clamp((t - 7.2) / 0.6, 0.0, 1.0)
		t2.add_theme_color_override("font_color", Color(0.9, 0.35, 0.1, a))
	if tbar_bot and t >= 7.5:
		var a = clamp((t - 7.5) / 0.3, 0.0, 1.0)
		tbar_bot.color = Color(0.9, 0.35, 0.1, a)
	if tag and t >= 8.2:
		var a = clamp((t - 8.2) / 0.6, 0.0, 1.0)
		tag.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
	if press and t >= 9.5:
		# Pulsing "Press Start" text
		var pulse = 0.4 + 0.6 * abs(sin((t - 9.5) * 1.5))
		press.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, pulse))

func _finish_intro():
	menu_built = true
	# Stop intro music
	if intro_music:
		intro_music.stop()
		intro_music.queue_free()
		intro_music = null
	# Remove all intro elements
	for el in intro_elements:
		if is_instance_valid(el):
			el.queue_free()
	intro_elements.clear()

	# No menu music — user requested music only in intro
	_build_menu()

func _build_menu():
	# Full screen dark background
	var bg = get_node_or_null("IntroBG")
	if not bg:
		bg = ColorRect.new()
		bg.set_anchors_preset(PRESET_FULL_RECT)
		add_child(bg)
	bg.color = Color(0.0, 0.0, 0.0)

	# City skyline silhouette (dark gradient strip)
	var skyline = ColorRect.new()
	skyline.color = Color(0.02, 0.04, 0.02)
	skyline.set_anchors_preset(PRESET_BOTTOM_WIDE)
	skyline.position.y = -200
	skyline.size = Vector2(0, 200)
	skyline.set_deferred("size", Vector2(1920, 200))
	add_child(skyline)

	# GTA V style — "GANGSTER TOWN" in large italic-look block letters
	var title = Label.new()
	title.text = "GANGSTER  TOWN"
	title.add_theme_font_size_override("font_size", 108)
	title.add_theme_color_override("font_color", Color(0.45, 0.75, 0.35))  # GTA V green
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-500, 50)
	title.size = Vector2(1000, 130)
	add_child(title)

	# Subtitle — smaller, white/silver
	var subtitle = Label.new()
	subtitle.text = "ADVENTURES"
	subtitle.add_theme_font_size_override("font_size", 42)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(PRESET_CENTER_TOP)
	subtitle.position = Vector2(-250, 170)
	subtitle.size = Vector2(500, 50)
	add_child(subtitle)

	# Thin green line under title
	var title_line = ColorRect.new()
	title_line.color = Color(0.45, 0.75, 0.35)
	title_line.set_anchors_preset(PRESET_CENTER_TOP)
	title_line.position = Vector2(-350, 162)
	title_line.size = Vector2(700, 3)
	add_child(title_line)

	# Menu buttons
	var btn_container = VBoxContainer.new()
	btn_container.set_anchors_preset(PRESET_CENTER)
	btn_container.position = Vector2(-130, -30)
	btn_container.size = Vector2(260, 320)
	btn_container.add_theme_constant_override("separation", 14)
	add_child(btn_container)

	var btn_texts = ["START GAME", "LOAD GAME", "CONTROLS", "EXIT"]
	for i in range(btn_texts.size()):
		var btn = Button.new()
		btn.text = btn_texts[i]
		btn.custom_minimum_size = Vector2(260, 54)
		btn.add_theme_font_size_override("font_size", 24)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.08, 0.05)
		style.border_color = Color(0.45, 0.75, 0.35)
		style.set_border_width_all(2)
		style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.15, 0.25, 0.1)
		hover_style.border_color = Color(0.55, 0.9, 0.4)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.25, 0.4, 0.15)
		pressed_style.border_color = Color(0.6, 1.0, 0.4)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		btn.add_theme_color_override("font_hover_color", Color(0.55, 0.9, 0.4))

		btn_container.add_child(btn)
		buttons.append(btn)

	buttons[0].pressed.connect(_on_start)
	buttons[1].pressed.connect(_on_load)
	buttons[2].pressed.connect(_on_controls)
	buttons[3].pressed.connect(_on_exit)

	# Version label
	var ver = Label.new()
	ver.text = "v1.0 — Gangster Town Adventures — By Phaneendra D — Made with Godot 4"
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.3, 0.45, 0.3))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.set_anchors_preset(PRESET_BOTTOM_WIDE)
	ver.position.y = -30
	ver.set_deferred("size", Vector2(0, 20))
	add_child(ver)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start():
	if menu_music:
		menu_music.stop()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_load():
	if menu_music:
		menu_music.stop()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_controls():
	var overlay = _create_controls_screen()
	add_child(overlay)

func _on_exit():
	get_tree().quit()

func _create_controls_screen() -> Control:
	var panel = Control.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.92)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	panel.add_child(bg)

	var title = Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-200, 30)
	title.size = Vector2(400, 60)
	panel.add_child(title)

	var controls_text = """
  MOVEMENT
    W / Up Arrow ............ Move Forward
    S / Down Arrow .......... Move Backward
    A / Left Arrow .......... Move Left
    D / Right Arrow ......... Move Right
    Space ................... Jump
    Shift ................... Sprint
    Mouse ................... Look Around

  COMBAT
    Left Click .............. Shoot / Attack
    F ....................... Melee Attack
    1 ....................... Fist
    2 ....................... Pistol
    3 ....................... Rifle
    4 ....................... Shotgun

  VEHICLES
    E ....................... Enter / Exit Vehicle
    W / S ................... Accelerate / Brake
    A / D ................... Steer Left / Right

  GAME
    M ....................... Start Random Mission
    Alt + S ................. Save Game
    Alt + L ................. Load Game
    Escape .................. Pause / Resume
"""

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.offset_top = 90
	scroll.offset_bottom = -60
	scroll.offset_left = 80
	scroll.offset_right = -80
	panel.add_child(scroll)

	var text_label = Label.new()
	text_label.text = controls_text
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.custom_minimum_size = Vector2(600, 0)
	scroll.add_child(text_label)

	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.set_anchors_preset(PRESET_CENTER_BOTTOM)
	back_btn.position = Vector2(-60, -50)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08)
	style.border_color = Color(0.95, 0.7, 0.1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	back_btn.add_theme_stylebox_override("normal", style)
	back_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))

	back_btn.pressed.connect(func(): panel.queue_free())
	panel.add_child(back_btn)

	return panel
