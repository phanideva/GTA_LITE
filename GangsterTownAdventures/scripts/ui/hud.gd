extends CanvasLayer
# HUD — Vice City style overlay with health, money, weapons, minimap

var health_label: Label
var health_bar: ColorRect
var health_bg: ColorRect
var armor_bar: ColorRect
var armor_bg: ColorRect
var money_label: Label
var wanted_label: Label
var mission_label: Label
var mission_desc_label: Label
var mission_timer_label: Label
var waypoint_arrow: Control
var fps_label: Label
var ammo_label: Label
var weapon_label: Label
var weapon_icon: ColorRect
var time_label: Label
var chapter_label: Label
var death_overlay: ColorRect
var death_label: Label
var interact_label: Label
var objective_label: Label
var pause_panel: Control = null
var is_paused = false
var vignette: ColorRect = null
var vignette_alpha: float = 0.0
var mission_popup: Control = null
var radio_label: Label = null
var radio_fade_timer: float = 0.0
var _last_radio_station: String = "OFF"

const WEAPON_NAMES = {0: "FISTS", 1: "PISTOL", 2: "RIFLE", 3: "SHOTGUN"}
# Vice City colors
const VC_PINK = Color(0.92, 0.32, 0.58)
const VC_TEAL = Color(0.25, 0.85, 0.82)
const VC_GOLD = Color(0.95, 0.8, 0.2)
const VC_GREEN = Color(0.2, 0.9, 0.3)

func _ready():
	add_to_group("hud")

	# ── Top-right info block (Vice City style) ──
	# Time (top right)
	time_label = _make_label("", Vector2(1680, 12), 22, VC_TEAL)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.size = Vector2(200, 30)

	# Money (below time)
	money_label = _make_label("", Vector2(1680, 38), 22, VC_GREEN)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label.size = Vector2(200, 30)

	# Health icon + bar (top right area)
	var heart_icon = _make_label("♥", Vector2(1688, 68), 18, VC_PINK)
	health_bg = ColorRect.new()
	health_bg.color = Color(0.3, 0.05, 0.1, 0.5)
	health_bg.position = Vector2(1710, 70)
	health_bg.size = Vector2(170, 16)
	add_child(health_bg)
	health_bar = ColorRect.new()
	health_bar.color = VC_PINK
	health_bar.position = Vector2(1710, 70)
	health_bar.size = Vector2(170, 16)
	add_child(health_bar)
	health_label = _make_label("", Vector2(1715, 68), 14, Color.WHITE)

	# Armor bar
	armor_bg = ColorRect.new()
	armor_bg.color = Color(0.05, 0.1, 0.3, 0.5)
	armor_bg.position = Vector2(1710, 90)
	armor_bg.size = Vector2(170, 10)
	add_child(armor_bg)
	armor_bar = ColorRect.new()
	armor_bar.color = VC_TEAL
	armor_bar.position = Vector2(1710, 90)
	armor_bar.size = Vector2(0, 10)
	add_child(armor_bar)

	# Wanted stars (below armor)
	wanted_label = _make_label("", Vector2(1688, 104), 20, VC_GOLD)
	wanted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wanted_label.size = Vector2(200, 25)

	# FPS
	fps_label = _make_label("", Vector2(1820, 130), 12, Color(0.5, 0.5, 0.5, 0.6))

	# ── Mission info (top left) ──
	mission_label = _make_label("", Vector2(20, 12), 20, VC_GOLD)
	mission_label.size = Vector2(600, 28)
	mission_desc_label = _make_label("", Vector2(20, 38), 14, Color(0.85, 0.85, 0.9, 0.8))
	mission_desc_label.size = Vector2(500, 22)
	chapter_label = _make_label("", Vector2(20, 58), 12, Color(0.6, 0.6, 0.7, 0.6))
	chapter_label.size = Vector2(300, 18)
	mission_timer_label = _make_label("", Vector2(20, 78), 18, Color(1.0, 0.4, 0.3))
	mission_timer_label.visible = false

	# ── Objective hint (center screen, below crosshair) ──
	objective_label = _make_label("", Vector2(660, 600), 16, Color(1.0, 1.0, 0.8, 0.9))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.size = Vector2(600, 24)
	objective_label.visible = false

	# Weapon info (bottom right)
	var weapon_bg = ColorRect.new()
	weapon_bg.color = Color(0.0, 0.0, 0.0, 0.45)
	weapon_bg.position = Vector2(1700, 940)
	weapon_bg.size = Vector2(200, 75)
	add_child(weapon_bg)
	# Weapon icon colored box
	weapon_icon = ColorRect.new()
	weapon_icon.color = VC_PINK
	weapon_icon.position = Vector2(1710, 952)
	weapon_icon.size = Vector2(30, 30)
	add_child(weapon_icon)
	weapon_label = _make_label("", Vector2(1748, 950), 16, Color(0.85, 0.85, 0.9))
	ammo_label = _make_label("", Vector2(1748, 972), 26, Color.WHITE)

	# Death overlay
	death_overlay = ColorRect.new()
	death_overlay.color = Color(0.6, 0.0, 0.0, 0.0)
	death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.visible = false
	add_child(death_overlay)
	death_label = _make_label("WASTED", Vector2(720, 480), 80, Color(0.9, 0.1, 0.1))
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.size = Vector2(480, 100)
	death_label.visible = false

	# Vehicle interaction prompt
	interact_label = _make_label("", Vector2(760, 850), 20, VC_GOLD)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.size = Vector2(400, 28)
	interact_label.visible = false

	# Crosshair (thin + style)
	var crosshair_v = ColorRect.new()
	crosshair_v.color = Color(1, 1, 1, 0.5)
	crosshair_v.size = Vector2(1, 14)
	crosshair_v.position = Vector2(960, 533)
	add_child(crosshair_v)
	var crosshair_h = ColorRect.new()
	crosshair_h.color = Color(1, 1, 1, 0.5)
	crosshair_h.size = Vector2(14, 1)
	crosshair_h.position = Vector2(953, 540)
	add_child(crosshair_h)

	# ── Damage vignette (red border flash) ──
	vignette = ColorRect.new()
	vignette.color = Color(0.75, 0.0, 0.0, 0.0)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# ── Radio station label (slides in on R press) ──
	radio_label = _make_label("", Vector2(20, 880), 18, Color(0.4, 0.9, 1.0))
	radio_label.visible = false

func _make_label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl

func _process(_delta):
	var player = Globals.player
	if not player:
		return

	# ── Damage vignette ──
	if player and not player.is_dead:
		var hp_ratio = float(player.health) / float(player.max_health)
		var target_alpha = clamp((1.0 - hp_ratio) * 0.55, 0.0, 0.55)
		vignette_alpha = lerp(vignette_alpha, target_alpha, _delta * 4.0)
		vignette.color.a = vignette_alpha
	else:
		vignette.color.a = 0.0

	# ── Radio station label ──
	var station = Globals.current_radio_station
	if station != "OFF" and radio_fade_timer > 0.0:
		radio_fade_timer -= _delta
		radio_label.visible = true
		radio_label.text = "RADIO: " + station
		radio_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, clamp(radio_fade_timer, 0, 1)))
	elif station == "OFF":
		radio_label.visible = false
	else:
		radio_label.visible = false

	# Trigger radio timer when station changes
	if station != _last_radio_station:
		_last_radio_station = station
		radio_fade_timer = 2.5

	# Health bar
	var hp_ratio = float(player.health) / float(player.max_health)
	health_bar.size.x = 170.0 * hp_ratio
	health_bar.color = VC_PINK if hp_ratio > 0.3 else Color(1.0, 0.1, 0.1)
	health_label.text = "%d" % player.health

	# Armor bar
	if player.get("armor") != null and player.armor > 0:
		armor_bar.size.x = 170.0 * (float(player.armor) / float(player.max_armor))
		armor_bg.visible = true
		armor_bar.visible = true
	else:
		armor_bg.visible = false
		armor_bar.visible = false

	# Money
	money_label.text = "$%d" % Globals.player_money

	# Wanted stars
	var stars = ""
	for i in range(6):
		stars += "★" if i < Globals.wanted_level else "☆"
	wanted_label.text = stars
	wanted_label.add_theme_color_override("font_color",
		Color.RED if Globals.wanted_level >= 4 else VC_GOLD)

	# Weapon / Ammo
	var wep = player.current_weapon
	weapon_label.text = WEAPON_NAMES.get(wep, "?")
	if wep == 0:
		ammo_label.text = "∞"
		weapon_icon.color = Color(0.5, 0.5, 0.5)
	else:
		ammo_label.text = "%d" % player.ammo.get(wep, 0)
		weapon_icon.color = VC_PINK

	# FPS
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	# ── Mission info + waypoint ──
	var ms = get_tree().get_first_node_in_group("mission_system")
	if ms and ms.is_mission_active:
		var m = ms.current_mission
		mission_label.text = "MISSION: %s" % m.get("title", "")
		mission_desc_label.text = m.get("description", "")
		mission_desc_label.visible = true

		# Timer
		if m.get("time_limit", 0) > 0:
			var t = ms.get_time_remaining()
			var mins = int(t) / 60
			var secs = int(t) % 60
			mission_timer_label.text = "%d:%02d" % [mins, secs]
			mission_timer_label.visible = true
			if t < 15:
				mission_timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			else:
				mission_timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		else:
			mission_timer_label.visible = false

		# Progress indicator
		if m.get("type") == "kill":
			objective_label.text = "Eliminate targets: %d / %d" % [ms.mission_progress, m["target_count"]]
			objective_label.visible = true
		elif m.get("type") == "reach_zone":
			var dist = player.global_position.distance_to(m["marker"])
			objective_label.text = "Go to marker — %dm" % int(dist)
			objective_label.visible = true
		elif m.get("type") == "vehicle_deliver":
			if player.is_in_vehicle:
				var dist = player.global_position.distance_to(m["marker"])
				objective_label.text = "Deliver vehicle — %dm" % int(dist)
			else:
				objective_label.text = "Steal a vehicle first!"
			objective_label.visible = true
		elif m.get("type") == "survive":
			var t = ms.get_time_remaining()
			objective_label.text = "Survive! %d seconds remaining" % int(t)
			objective_label.visible = true
		else:
			objective_label.visible = false

		# Distance to mission marker on mission label
		if m.has("marker"):
			var dist = player.global_position.distance_to(m["marker"])
			mission_label.text += "  [%dm]" % int(dist)
	else:
		mission_label.text = "Press M for next mission"
		mission_desc_label.text = ""
		mission_desc_label.visible = false
		mission_timer_label.visible = false
		objective_label.visible = false

	# Time
	var env = get_tree().get_first_node_in_group("world_environment")
	if env:
		var h = int(env.time_of_day)
		var m = int((env.time_of_day - h) * 60)
		var suffix = "AM" if h < 12 else "PM"
		var h12 = h if h <= 12 else h - 12
		if h12 == 0: h12 = 12
		time_label.text = "%d:%02d %s" % [h12, m, suffix]

	# Death
	if player.is_dead:
		death_overlay.visible = true
		death_label.visible = true
		death_overlay.color.a = 0.55
	else:
		death_overlay.visible = false
		death_label.visible = false

	# Vehicle proximity prompt
	if player and not player.is_in_vehicle and not player.is_dead:
		var near_vehicle = false
		var p_xz = Vector2(player.global_position.x, player.global_position.z)
		for v in get_tree().get_nodes_in_group("vehicle"):
			if not is_instance_valid(v):
				continue
			var v_xz = Vector2(v.global_position.x, v.global_position.z)
			if p_xz.distance_to(v_xz) < 8.0:
				near_vehicle = true
				break
		if not near_vehicle:
			for v in get_tree().get_nodes_in_group("traffic"):
				if not is_instance_valid(v):
					continue
				var v_xz = Vector2(v.global_position.x, v.global_position.z)
				if p_xz.distance_to(v_xz) < 8.0:
					near_vehicle = true
					break
		# Save point prompt overrides vehicle prompt
		if Globals.near_save_point:
			interact_label.visible = true
			if Globals.save_feedback_timer > 0:
				interact_label.text = "GAME SAVED!"
			else:
				interact_label.text = "Press [K] to Save Game"
		else:
			interact_label.visible = near_vehicle
			interact_label.text = "Press [E] to enter vehicle" if near_vehicle else ""
	elif player and player.is_in_vehicle:
		interact_label.visible = true
		if player.current_vehicle and player.current_vehicle.get("current_speed") != null:
			var spd = abs(player.current_vehicle.current_speed)
			var mph = int(spd * 2.2)
			interact_label.text = "%d MPH — [E] Exit" % mph
		else:
			interact_label.text = "[E] Exit vehicle"
	else:
		interact_label.visible = false

	# Chapter progress
	if ms and ms.has_method("get_story_progress_text"):
		chapter_label.text = ms.get_story_progress_text()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		_show_pause_menu()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if pause_panel:
			pause_panel.queue_free()
			pause_panel = null
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _show_pause_menu():
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(bg)

	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.7, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-150, 120)
	title.size = Vector2(300, 60)
	pause_panel.add_child(title)

	var btn_container = VBoxContainer.new()
	btn_container.set_anchors_preset(Control.PRESET_CENTER)
	btn_container.position = Vector2(-110, -40)
	btn_container.size = Vector2(220, 200)
	btn_container.add_theme_constant_override("separation", 12)
	btn_container.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.add_child(btn_container)

	var btn_data = [["RESUME", _on_resume], ["CONTROLS", _on_pause_controls], ["MAIN MENU", _on_main_menu], ["QUIT", _on_quit]]
	for bd in btn_data:
		var btn = Button.new()
		btn.text = bd[0]
		btn.custom_minimum_size = Vector2(220, 45)
		btn.add_theme_font_size_override("font_size", 20)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15)
		style.border_color = Color(0.95, 0.7, 0.1)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		btn.pressed.connect(bd[1])
		btn_container.add_child(btn)

	add_child(pause_panel)

func _on_resume():
	toggle_pause()

func _on_pause_controls():
	# Simple controls text
	var info = Label.new()
	info.text = "WASD=Move  Mouse=Look  LMB=Shoot  F=Melee\nE=Vehicle  1234=Weapons  Space=Jump  Shift=Sprint\nM=Mission  Alt+S=Save  Alt+L=Load  Esc=Pause"
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.set_anchors_preset(Control.PRESET_CENTER)
	info.position = Vector2(-300, 120)
	info.size = Vector2(600, 100)
	info.process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_panel:
		pause_panel.add_child(info)

func _on_main_menu():
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit():
	get_tree().quit()

func update_mission(text: String):
	mission_label.text = "MISSION: " + text

func show_mission_complete(title: String, reward: int):
	# Green "MISSION COMPLETE" popup that fades away
	if mission_popup:
		mission_popup.queue_free()
	mission_popup = Control.new()
	mission_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mission_popup.position = Vector2(-300, 200)
	mission_popup.size = Vector2(600, 100)
	add_child(mission_popup)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.size = Vector2(600, 100)
	mission_popup.add_child(bg)

	var lbl1 = Label.new()
	lbl1.text = "MISSION COMPLETE"
	lbl1.add_theme_font_size_override("font_size", 36)
	lbl1.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	lbl1.position = Vector2(60, 12)
	mission_popup.add_child(lbl1)

	var lbl2 = Label.new()
	lbl2.text = title + "  +$%d" % reward
	lbl2.add_theme_font_size_override("font_size", 20)
	lbl2.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	lbl2.position = Vector2(60, 58)
	mission_popup.add_child(lbl2)

	# Fade out after 3s
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(mission_popup):
		var tween = create_tween()
		tween.tween_property(mission_popup, "modulate:a", 0.0, 1.0)
		tween.tween_callback(mission_popup.queue_free)
		mission_popup = null

func show_wasted():
	death_overlay.visible = true
	death_label.visible = true
	death_overlay.color.a = 0.55

func hide_wasted():
	death_overlay.visible = false
	death_label.visible = false

func show_vehicle_prompt(show: bool):
	if interact_label:
		interact_label.visible = show
		if show:
			interact_label.text = "Press [E] to enter vehicle"
