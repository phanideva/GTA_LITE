extends Node3D
# Main Game Scene — Advanced GTA 3D

var player: CharacterBody3D
var mission_system: Node
var economy: Node
var save_system: Node
var world: Node3D
var intro_music_player: AudioStreamPlayer = null

# Perf overlay (F3)
var _perf_overlay: CanvasLayer = null
var _perf_label: Label = null
var _f3_was_down: bool = false
var _perf_accum: float = 0.0
var _perf_visible: bool = false

func _ready():
	await get_tree().process_frame
	player = $Player
	world  = $World
	world.add_to_group("world_environment")
	Globals.player = player

	mission_system = Node.new()
	mission_system.name = "MissionSystem"
	mission_system.set_script(load("res://scripts/systems/story_missions.gd"))
	add_child(mission_system)

	economy = Node.new()
	economy.name = "Economy"
	economy.set_script(load("res://scripts/systems/economy.gd"))
	add_child(economy)

	save_system = Node.new()
	save_system.name = "SaveSystem"
	save_system.set_script(load("res://scripts/systems/save_load.gd"))
	add_child(save_system)

	spawn_npcs()
	spawn_police()
	spawn_gangsters()
	spawn_traffic()
	spawn_vehicles()
	spawn_motorcycles()
	spawn_animals()
	spawn_weapon_pickups()

	print("=== Gangster Town Adventures — Ready ===")
	print("WASD: Move | Mouse: Look | LMB: Shoot | F: Melee | E: Enter Vehicle")
	print("1/2/3/4: Switch Weapon | Space: Jump | Shift: Sprint")
	print("M: Start Next Mission | Alt+S: Save | Alt+L: Load")

	mission_system.connect("mission_started", _on_mission_started)
	mission_system.connect("mission_completed", _on_mission_completed)

	Globals.game_state = "playing"

	# Vice City-style cinematic intro
	_show_game_intro()

	await get_tree().create_timer(1.0).timeout
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("update_mission"):
			hud.update_mission(mission_system.story_missions[0]["title"])

var intro_overlay: Control = null
var intro_camera: Camera3D = null

func _show_game_intro():
	_play_intro_music()

	# Disable player input during intro
	if player:
		player.intro_mode = true
		player.visible = false

	# Create flyover camera (separate from player camera)
	intro_camera = Camera3D.new()
	intro_camera.fov = 60.0
	intro_camera.current = true
	add_child(intro_camera)

	# Vice City-style letterbox bars + title overlays
	intro_overlay = Control.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.z_index = 100
	add_child(intro_overlay)

	var top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 80)
	top_bar.size = Vector2(1920, 80)
	intro_overlay.add_child(top_bar)

	var bottom_bar = ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.offset_top = -80
	bottom_bar.size = Vector2(1920, 80)
	intro_overlay.add_child(bottom_bar)

	# --- Camera flyover waypoints (Vice City style: beach → pier → downtown → Hollywood → player) ---
	# [position, look_at_target, duration, label_text, "Speaker: line"]
	var waypoints = [
		[Vector3(20, 40, 170), Vector3(0, 0, 155), 3.0, "SANTA MONICA BEACH",
			"NARRATOR:  Los Santos.  A city built on dreams... and bullets."],
		[Vector3(-60, 25, 140), Vector3(-30, 0, 155), 2.5, "VENICE BOARDWALK",
			"TOMMY:  Twenty years I waited to come back.  This town owes me."],
		[Vector3(50, 60, 50), Vector3(0, 0, 0), 3.0, "DOWNTOWN LOS SANTOS",
			"DON MARCO:  The streets are run by gangs now, Tommy.  Pick your side."],
		[Vector3(-180, 50, -180), Vector3(-200, 20, -200), 2.5, "HOLLYWOOD HILLS",
			"TOMMY:  I don't pick sides, Marco.  I take what's mine."],
		[Vector3(-130, 35, -130), Vector3(-150, 15, -150), 2.0, "GRIFFITH OBSERVATORY",
			"NARRATOR:  Welcome to the rise of a new kingpin..."],
		[Vector3(30, 15, 30), Vector3(22, 1, 22), 2.5, "",
			"TOMMY:  Time to make some noise."],
	]

	# Location label (bottom area, above letterbox)
	var loc_label = Label.new()
	loc_label.add_theme_font_size_override("font_size", 28)
	loc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.0))
	loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	loc_label.offset_top = -120
	loc_label.size = Vector2(400, 40)
	intro_overlay.add_child(loc_label)

	# Dialogue caption (above bottom letterbox bar)
	var dlg_label = Label.new()
	dlg_label.add_theme_font_size_override("font_size", 22)
	dlg_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 0.0))
	dlg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	dlg_label.add_theme_constant_override("outline_size", 6)
	dlg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg_label.offset_top = -75
	dlg_label.offset_left = 100
	dlg_label.offset_right = -100
	dlg_label.size = Vector2(0, 50)
	intro_overlay.add_child(dlg_label)

	# Start the camera at first waypoint
	intro_camera.global_position = waypoints[0][0]
	intro_camera.look_at(waypoints[0][1], Vector3.UP)

	# Animate through waypoints
	var tween = create_tween()
	for wi in range(waypoints.size()):
		var wp = waypoints[wi]
		var pos = wp[0]
		var look = wp[1]
		var dur = wp[2]
		var lbl = wp[3]
		var dlg = wp[4] if wp.size() > 4 else ""

		# Show location label
		if lbl != "":
			tween.tween_callback(func():
				loc_label.text = lbl
				loc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.0))
				var fade_in = create_tween()
				fade_in.tween_method(func(a):
					loc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, a))
				, 0.0, 1.0, 0.4)
				fade_in.tween_interval(dur - 0.8)
				fade_in.tween_method(func(a):
					loc_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, a))
				, 1.0, 0.0, 0.4)
			)

		# Show dialogue caption for this waypoint
		if dlg != "":
			tween.tween_callback(func():
				dlg_label.text = dlg
				dlg_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 0.0))
				var dfade = create_tween()
				dfade.tween_method(func(a):
					dlg_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, a))
				, 0.0, 1.0, 0.35)
				dfade.tween_interval(max(0.3, dur - 0.9))
				dfade.tween_method(func(a):
					dlg_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, a))
				, 1.0, 0.0, 0.45)
			)

		# Smooth camera move with look-at tracking
		tween.tween_method(func(t_val):
			if intro_camera and is_instance_valid(intro_camera):
				intro_camera.global_position = intro_camera.global_position.lerp(pos, t_val)
				intro_camera.look_at(look, Vector3.UP)
		, 0.0, 1.0, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	# Show game title after flyover
	tween.tween_callback(func():
		_show_title_card()
	)
	tween.tween_interval(5.0)

	# End intro — restore player camera
	tween.tween_callback(func():
		_end_intro()
	)

func _show_title_card():
	if not intro_overlay or not is_instance_valid(intro_overlay):
		return

	# Vice City-style title card
	var title_bg = ColorRect.new()
	title_bg.color = Color(0, 0, 0, 0.5)
	title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bg.modulate.a = 0.0
	intro_overlay.add_child(title_bg)

	var title = Label.new()
	title.text = "GANGSTER TOWN"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-400, -80)
	title.size = Vector2(800, 100)
	intro_overlay.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "A D V E N T U R E S"
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-400, 30)
	subtitle.size = Vector2(800, 50)
	intro_overlay.add_child(subtitle)

	var tagline = Label.new()
	tagline.text = "Welcome to Los Santos..."
	tagline.add_theme_font_size_override("font_size", 22)
	tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.0))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.set_anchors_preset(Control.PRESET_CENTER)
	tagline.position = Vector2(-400, 80)
	tagline.size = Vector2(800, 40)
	intro_overlay.add_child(tagline)

	var t = create_tween()
	t.tween_property(title_bg, "modulate:a", 1.0, 0.5)
	t.tween_method(func(a):
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
	, 0.0, 1.0, 1.0)
	t.tween_method(func(a):
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
	, 0.0, 1.0, 0.6)
	t.tween_method(func(a):
		tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
	, 0.0, 1.0, 0.5)
	t.tween_interval(2.5)
	# Fade out everything
	t.tween_method(func(a):
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
		tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
		title_bg.modulate.a = a
	, 1.0, 0.0, 1.0)

func _end_intro():
	# Clean up intro elements
	if intro_camera and is_instance_valid(intro_camera):
		intro_camera.current = false
		intro_camera.queue_free()
		intro_camera = null
	if intro_overlay and is_instance_valid(intro_overlay):
		intro_overlay.queue_free()
		intro_overlay = null
	# Restore player — use activate_player_camera which handles reparented pivot
	if player:
		if player.has_method("activate_player_camera"):
			player.activate_player_camera()
		else:
			player.intro_mode = false
			player.visible = true
			# Fallback: find camera via the reparented pivot
			if player.camera_pivot:
				var cam = player.camera_pivot.get_node_or_null("SpringArm3D/Camera3D")
				if cam:
					cam.current = true
	_fade_out_intro_music()
	# Auto-start the first story mission so the player isn't told to "press M"
	if mission_system and mission_system.has_method("start_mission"):
		await get_tree().create_timer(1.5).timeout
		mission_system.start_mission(0)

func _play_intro_music():
	intro_music_player = AudioStreamPlayer.new()
	intro_music_player.bus = "Master"
	intro_music_player.volume_db = -8.0
	add_child(intro_music_player)
	var stream = SFX.generate_intro_music()
	if stream:
		intro_music_player.stream = stream
		intro_music_player.play()

func _fade_out_intro_music():
	if intro_music_player and is_instance_valid(intro_music_player):
		var tween = create_tween()
		tween.tween_property(intro_music_player, "volume_db", -40.0, 2.0)
		tween.tween_callback(func():
			if intro_music_player:
				intro_music_player.stop()
				intro_music_player.queue_free()
		)

func _process(delta):
	if Input.is_action_just_pressed("start_mission"):
		if not mission_system.start_mission(0):
			print("Mission already active or story complete!")
	if Input.is_action_just_pressed("save"):
		save_system.save_game()
		print("Saved!")
	if Input.is_action_just_pressed("load"):
		save_system.load_game()
		print("Loaded!")

	# F3 toggles perf overlay
	if Input.is_key_pressed(KEY_F3) and not _f3_was_down:
		_toggle_perf_overlay()
	_f3_was_down = Input.is_key_pressed(KEY_F3)
	_update_perf_overlay()

	# Save point proximity check
	_check_save_point_proximity()
	if Globals.near_save_point and Input.is_action_just_pressed("quick_save"):
		save_system.save_game()
		Globals.save_feedback_timer = 2.5
		print("Game saved at save point!")
	
	# Save feedback timer
	if Globals.save_feedback_timer > 0:
		Globals.save_feedback_timer -= delta

func _on_mission_started(mtitle: String):
	if Cutscene:
		Cutscene.show_mission_title(mtitle)

func _on_mission_completed(mtitle: String, reward: int):
	SFX.play_sfx("mission_complete")
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("show_mission_complete"):
			hud.show_mission_complete(mtitle, reward)

# ======= SAVE POINT PROXIMITY =======
const SAVE_POINT_POSITIONS = [
	Vector3(-120, 0, 50),   # Starlight Motel
	Vector3(22, 0, 22),     # Safe House (player start)
	Vector3(120, 0, -50),   # Mel's Diner
]

func _check_save_point_proximity():
	if not Globals.player:
		Globals.near_save_point = false
		return
	var pp = Vector2(Globals.player.global_position.x, Globals.player.global_position.z)
	for sp in SAVE_POINT_POSITIONS:
		if pp.distance_to(Vector2(sp.x, sp.z)) < 8.0:
			Globals.near_save_point = true
			return
	Globals.near_save_point = false

# ======= SPAWN FUNCTIONS =======

func spawn_npcs():
	print("[SPAWN] Starting NPC spawn...")
	var scene = load("res://scenes/ai/pedestrian.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load pedestrian.tscn!")
		return
	var sidewalk_spots = []
	for i in range(-11, 12):
		for j in range(-11, 12):
			sidewalk_spots.append(Vector3(i * 50 + 6, 0.5, j * 50 + 6))
			sidewalk_spots.append(Vector3(i * 50 - 6, 0.5, j * 50 - 6))
	sidewalk_spots.shuffle()
	var count = mini(140, sidewalk_spots.size())
	var spawned_n = 0
	for i in range(sidewalk_spots.size()):
		if spawned_n >= count:
			break
		var pos = sidewalk_spots[i]
		if world and world.has_method("_is_zone_free") and not world._is_zone_free(pos.x, pos.z, 2, 2):
			continue
		var npc = scene.instantiate()
		add_child(npc)
		npc.global_position = pos
		spawned_n += 1
	print("[SPAWN] Spawned %d pedestrians" % spawned_n)

func spawn_police():
	print("[SPAWN] Starting police spawn...")
	var scene = load("res://scenes/ai/police.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load police.tscn!")
		return
	var placed_p = 0
	var tries_p = 0
	while placed_p < 30 and tries_p < 400:
		tries_p += 1
		var x = randf_range(20, 500) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(20, 500) * (1 if randi() % 2 == 0 else -1)
		if world and world.has_method("_is_zone_free") and not world._is_zone_free(x, z, 2, 2):
			continue
		var cop = scene.instantiate()
		add_child(cop)
		cop.global_position = Vector3(x, 0.5, z)
		placed_p += 1
	print("[SPAWN] Spawned %d police" % placed_p)

func spawn_gangsters():
	print("[SPAWN] Starting gangster spawn...")
	var scene = load("res://scenes/ai/gangster.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load gangster.tscn!")
		return
	var placed_g = 0
	var tries_g = 0
	while placed_g < 40 and tries_g < 500:
		tries_g += 1
		var x = randf_range(30, 500) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(30, 500) * (1 if randi() % 2 == 0 else -1)
		if world and world.has_method("_is_zone_free") and not world._is_zone_free(x, z, 2, 2):
			continue
		var g = scene.instantiate()
		add_child(g)
		g.global_position = Vector3(x, 0.5, z)
		g.connect("tree_exited", _on_enemy_killed)
		placed_g += 1
	print("[SPAWN] Spawned %d gangsters" % placed_g)

func spawn_traffic():
	print("[SPAWN] Starting traffic spawn...")
	var scene = load("res://scenes/vehicles/traffic.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load traffic.tscn!")
		return
	var road_starts = []
	for road_x_idx in range(-10, 11, 2):
		var road_x = road_x_idx * 50
		var lane_offset = 2.0 if randi() % 2 == 0 else -2.0
		var start_z = randf_range(-500, 500)
		road_starts.append({"pos": Vector3(road_x + lane_offset, 0.2, start_z), "axis": "ns"})
	for road_z_idx in range(-10, 11, 2):
		var road_z = road_z_idx * 50
		var lane_offset = 2.0 if randi() % 2 == 0 else -2.0
		var start_x = randf_range(-500, 500)
		road_starts.append({"pos": Vector3(start_x, 0.2, road_z + lane_offset), "axis": "ew"})
	for rd in road_starts:
		var car = scene.instantiate()
		add_child(car)
		car.global_position = rd["pos"]
		car.road_axis = rd["axis"]
	print("[SPAWN] Spawned %d traffic vehicles" % road_starts.size())

func spawn_vehicles():
	print("[SPAWN] Starting vehicle spawn...")
	var scene = load("res://scenes/vehicles/vehicle.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load vehicle.tscn!")
		return
	var positions = []
	for road_idx in range(-11, 12):
		var road_x = road_idx * 50
		for offset_z in [-40, -15, 15, 40, 70, -70, 100, -100, 150, -150, 220, -220, 320, -320, 450, -450]:
			if randi() % 3 != 0:
				var side = 4.8 if randi() % 2 == 0 else -4.8
				positions.append(Vector3(road_x + side, 0.2, offset_z))
	for road_idx in range(-11, 12):
		var road_z = road_idx * 50
		for offset_x in [-40, -15, 15, 40, 70, -70, 100, -100, 150, -150, 220, -220, 320, -320, 450, -450]:
			if randi() % 3 != 0:
				var side = 4.8 if randi() % 2 == 0 else -4.8
				positions.append(Vector3(offset_x, 0.2, road_z + side))
	positions.shuffle()
	var count = mini(120, positions.size())
	var spawned = 0
	var placed_zones: Array = []  # Simple overlap check for vehicles
	for i in range(positions.size()):
		if spawned >= count:
			break
		var pos = positions[i]
		# Check overlap with other parked vehicles (min 6m apart)
		var too_close = false
		for pz in placed_zones:
			if pos.distance_to(pz) < 6.0:
				too_close = true
				break
		if too_close:
			continue
		# Check overlap with world zones (buildings, landmarks)
		if world and world.has_method("_is_zone_free") and not world._is_zone_free(pos.x, pos.z, 5, 5):
			continue
		var car = scene.instantiate()
		add_child(car)
		car.global_position = pos
		if abs(fmod(pos.x, 50.0)) < 8.0:
			car.rotation.y = 0
		else:
			car.rotation.y = PI / 2
		placed_zones.append(pos)
		spawned += 1
	print("[SPAWN] Spawned %d parked vehicles" % spawned)

func spawn_motorcycles():
	print("[SPAWN] Starting motorcycle spawn...")
	var scene = load("res://scenes/vehicles/motorcycle.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load motorcycle.tscn!")
		return
	var moto_pos = [
		Vector3(25.5, 0.15, 5), Vector3(-25.5, 0.15, -5),
		Vector3(47.5, 0.15, -15), Vector3(-47.5, 0.15, 15),
		Vector3(69.5, 0.15, 25), Vector3(-69.5, 0.15, 40),
	]
	for pos in moto_pos:
		var bike = scene.instantiate()
		add_child(bike)
		bike.global_position = pos
		bike.rotation.y = randf_range(0, TAU)
	var bike_pos = [
		Vector3(8, 0.15, 12), Vector3(-10, 0.15, 8),
		Vector3(5, 0.15, -8), Vector3(-5, 0.15, 10),
	]
	for pos in bike_pos:
		var bicycle = scene.instantiate()
		bicycle.is_bicycle = true
		add_child(bicycle)
		bicycle.global_position = pos
		bicycle.rotation.y = randf_range(0, TAU)
	print("[SPAWN] Spawned %d motorcycles + %d bicycles" % [moto_pos.size(), bike_pos.size()])

func spawn_animals():
	print("[SPAWN] Starting animal spawn...")
	var scene = load("res://scenes/ai/animal.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load animal.tscn!")
		return
	for i in range(22):
		var dog = scene.instantiate()
		dog.animal_type = "dog"
		add_child(dog)
		dog.global_position = Vector3(randf_range(-400, 400), 0.5, randf_range(-400, 400))
	for i in range(16):
		var cat = scene.instantiate()
		cat.animal_type = "cat"
		add_child(cat)
		cat.global_position = Vector3(randf_range(-400, 400), 0.5, randf_range(-400, 400))
	print("[SPAWN] Spawned 22 dogs + 16 cats")

func spawn_weapon_pickups():
	print("[SPAWN] Starting weapon pickup spawn...")
	var pickup_script = load("res://scripts/systems/weapon_pickup.gd")
	if not pickup_script:
		push_error("[SPAWN] Failed to load weapon_pickup.gd!")
		return
	var pickup_positions = [
		[Vector3(15, 0.5, 15), 1, 30],
		[Vector3(-15, 0.5, 15), 2, 60],
		[Vector3(15, 0.5, -15), 3, 20],
		[Vector3(-15, 0.5, -15), 1, 30],
		[Vector3(35, 0.5, 35), 2, 60],
		[Vector3(-35, 0.5, -35), 3, 20],
		[Vector3(77, 0.5, 44), 2, 90],
		[Vector3(-77, 0.5, -44), 3, 40],
		[Vector3(100, 0.5, 66), 1, 50],
		[Vector3(-100, 0.5, -66), 2, 80],
		[Vector3(55, 0.5, -88), 3, 30],
		[Vector3(-55, 0.5, 88), 1, 40],
	]
	for p in pickup_positions:
		var pickup = Area3D.new()
		pickup.set_script(pickup_script)
		pickup.weapon_type = p[1]
		pickup.ammo_amount = p[2]
		add_child(pickup)
		pickup.global_position = p[0]

func _on_enemy_killed():
	if mission_system and mission_system.is_mission_active:
		mission_system.on_kill()

# ─────────────── F3 PERF OVERLAY ───────────────
func _toggle_perf_overlay():
	if _perf_overlay == null:
		_perf_overlay = CanvasLayer.new()
		_perf_overlay.layer = 100
		add_child(_perf_overlay)
		var bg = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.55)
		bg.position = Vector2(8, 8)
		bg.size = Vector2(280, 180)
		_perf_overlay.add_child(bg)
		_perf_label = Label.new()
		_perf_label.position = Vector2(16, 14)
		_perf_label.size = Vector2(270, 170)
		_perf_label.add_theme_font_size_override("font_size", 14)
		_perf_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.8))
		_perf_overlay.add_child(_perf_label)
	_perf_visible = not _perf_visible
	_perf_overlay.visible = _perf_visible

func _update_perf_overlay():
	if not _perf_visible or _perf_label == null:
		return
	_perf_accum += get_process_delta_time()
	if _perf_accum < 0.25:
		return
	_perf_accum = 0.0
	var fps = Engine.get_frames_per_second()
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var objs = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var nodes_n = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var mem_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var phys_step = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var process_step = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var npc_count = get_tree().get_nodes_in_group("npc").size()
	var veh_count = get_tree().get_nodes_in_group("vehicle").size()
	_perf_label.text = "PERF (F3)\nFPS: %d\nDraw calls: %d\nPrimitives: %d\nObjects: %d\nNodes: %d\nMemory: %.1f MB\nProcess: %.2f ms\nPhysics: %.2f ms\nNPCs: %d  Vehicles: %d" % [
		fps, draw_calls, prim, objs, nodes_n, mem_mb, process_step, phys_step, npc_count, veh_count
	]
