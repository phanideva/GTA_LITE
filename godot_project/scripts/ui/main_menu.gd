extends Control
# Main Menu — GTA-style start screen

var buttons: Array = []

func _ready():
	# Full screen dark background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "GTA LITE"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-200, 60)
	title.size = Vector2(400, 100)
	add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "CITY OF CRIME"
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(PRESET_CENTER_TOP)
	subtitle.position = Vector2(-200, 140)
	subtitle.size = Vector2(400, 40)
	add_child(subtitle)

	# Menu buttons
	var btn_container = VBoxContainer.new()
	btn_container.set_anchors_preset(PRESET_CENTER)
	btn_container.position = Vector2(-120, -60)
	btn_container.size = Vector2(240, 300)
	btn_container.add_theme_constant_override("separation", 12)
	add_child(btn_container)

	var btn_texts = ["START GAME", "LOAD GAME", "CONTROLS", "EXIT"]
	for i in range(btn_texts.size()):
		var btn = Button.new()
		btn.text = btn_texts[i]
		btn.custom_minimum_size = Vector2(240, 50)
		btn.add_theme_font_size_override("font_size", 22)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.18)
		style.border_color = Color(0.95, 0.7, 0.1)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.2, 0.08)
		hover_style.border_color = Color(0.95, 0.7, 0.1)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.4, 0.3, 0.05)
		pressed_style.border_color = Color(1.0, 0.8, 0.2)
		pressed_style.set_border_width_all(2)
		pressed_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4))

		btn_container.add_child(btn)
		buttons.append(btn)

	buttons[0].pressed.connect(_on_start)
	buttons[1].pressed.connect(_on_load)
	buttons[2].pressed.connect(_on_controls)
	buttons[3].pressed.connect(_on_exit)

	# Version label
	var ver = Label.new()
	ver.text = "v1.0 — Made with Godot 4"
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.set_anchors_preset(PRESET_BOTTOM_WIDE)
	ver.position.y = -30
	ver.size = Vector2(0, 20)
	add_child(ver)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_load():
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
