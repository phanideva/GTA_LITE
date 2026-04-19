extends Node3D
# Main Game Scene — Advanced GTA 3D

var player: CharacterBody3D
var mission_system: Node
var economy: Node
var save_system: Node
var world: Node3D
var intro_music_player: AudioStreamPlayer = null

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

	await get_tree().create_timer(1.0).timeout
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("update_mission"):
			hud.update_mission("Press M to start: " + mission_system.story_missions[0]["title"])

var intro_overlay: Control = null

func _show_game_intro():
	_play_intro_music()
	intro_overlay = Control.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.z_index = 100
	add_child(intro_overlay)

	var top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1920, 120)
	intro_overlay.add_child(top_bar)

	var bottom_bar = ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.position = Vector2(0, 960)
	bottom_bar.size = Vector2(1920, 120)
	intro_overlay.add_child(bottom_bar)

	var logo_container = Control.new()
	logo_container.set_anchors_preset(Control.PRESET_CENTER)
	logo_container.position = Vector2(-350, -180)
	logo_container.size = Vector2(700, 300)
	intro_overlay.add_child(logo_container)

	var title_shadow = Label.new()
	title_shadow.text = "GANGSTER TOWN"
	title_shadow.add_theme_font_size_override("font_size", 72)
	title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
	title_shadow.position = Vector2(4, 4)
	title_shadow.size = Vector2(700, 100)
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_container.add_child(title_shadow)

	var title = Label.new()
	title.text = "GANGSTER TOWN"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, 0.0))
	title.position = Vector2(0, 0)
	title.size = Vector2(700, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_container.add_child(title)

	var subtitle_shadow = Label.new()
	subtitle_shadow.text = "ADVENTURES"
	subtitle_shadow.add_theme_font_size_override("font_size", 36)
	subtitle_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
	subtitle_shadow.position = Vector2(4, 84)
	subtitle_shadow.size = Vector2(700, 50)
	subtitle_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_container.add_child(subtitle_shadow)

	var subtitle = Label.new()
	subtitle.text = "ADVENTURES"
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.0))
	subtitle.position = Vector2(0, 80)
	subtitle.size = Vector2(700, 50)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_container.add_child(subtitle)

	var location = Label.new()
	location.text = "Liberty District"
	location.add_theme_font_size_override("font_size", 28)
	location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.0))
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location.set_anchors_preset(Control.PRESET_CENTER)
	location.position = Vector2(-200, 180)
	location.size = Vector2(400, 40)
	intro_overlay.add_child(location)

	var tagline = Label.new()
	tagline.text = "Welcome to the streets..."
	tagline.add_theme_font_size_override("font_size", 20)
	tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.0))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.set_anchors_preset(Control.PRESET_CENTER)
	tagline.position = Vector2(-200, 220)
	tagline.size = Vector2(400, 30)
	intro_overlay.add_child(tagline)

	var tween = create_tween()
	tween.tween_method(func(a):
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
		title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.6))
	, 0.0, 1.0, 1.5)
	tween.tween_method(func(a):
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
		subtitle_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.5))
	, 0.0, 1.0, 0.8)
	tween.tween_interval(0.5)
	tween.tween_method(func(a):
		location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, a))
	, 0.0, 1.0, 0.6)
	tween.tween_method(func(a):
		tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
	, 0.0, 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_method(func(a):
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
		title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.6))
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
		subtitle_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.5))
		location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, a))
		tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
		top_bar.color.a = a
		bottom_bar.color.a = a
	, 1.0, 0.0, 1.5)
	tween.tween_callback(func():
		intro_overlay.queue_free()
		_fade_out_intro_music()
	)

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

func _process(_delta):
	if Input.is_action_just_pressed("start_mission"):
		if not mission_system.start_mission(0):
			print("Mission already active or story complete!")
	if Input.is_action_just_pressed("save"):
		save_system.save_game()
		print("Saved!")
	if Input.is_action_just_pressed("load"):
		save_system.load_game()
		print("Loaded!")

func _on_mission_started(mtitle: String):
	if Cutscene:
		Cutscene.show_mission_title(mtitle)

func _on_mission_completed(mtitle: String, reward: int):
	SFX.play_sfx("mission_complete")
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("show_mission_complete"):
			hud.show_mission_complete(mtitle, reward)

# ======= SPAWN FUNCTIONS =======

func spawn_npcs():
	print("[SPAWN] Starting NPC spawn...")
	var scene = load("res://scenes/ai/pedestrian.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load pedestrian.tscn!")
		return
	var sidewalk_spots = []
	for i in range(-7, 8):
		for j in range(-7, 8):
			sidewalk_spots.append(Vector3(i * 50 + 6, 0.5, j * 50 + 6))
			sidewalk_spots.append(Vector3(i * 50 - 6, 0.5, j * 50 - 6))
	sidewalk_spots.shuffle()
	var count = mini(40, sidewalk_spots.size())
	for i in range(count):
		var npc = scene.instantiate()
		add_child(npc)
		npc.global_position = sidewalk_spots[i]
	print("[SPAWN] Spawned %d pedestrians" % count)

func spawn_police():
	print("[SPAWN] Starting police spawn...")
	var scene = load("res://scenes/ai/police.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load police.tscn!")
		return
	for i in range(10):
		var cop = scene.instantiate()
		add_child(cop)
		var x = randf_range(20, 200) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(20, 200) * (1 if randi() % 2 == 0 else -1)
		cop.global_position = Vector3(x, 0.5, z)
	print("[SPAWN] Spawned 100 police")

func spawn_gangsters():
	print("[SPAWN] Starting gangster spawn...")
	var scene = load("res://scenes/ai/gangster.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load gangster.tscn!")
		return
	for i in range(15):
		var g = scene.instantiate()
		add_child(g)
		var x = randf_range(30, 200) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(30, 200) * (1 if randi() % 2 == 0 else -1)
		g.global_position = Vector3(x, 0.5, z)
		g.connect("tree_exited", _on_enemy_killed)
	print("[SPAWN] Spawned 15 gangsters")

func spawn_traffic():
	print("[SPAWN] Starting traffic spawn...")
	var scene = load("res://scenes/vehicles/traffic.tscn")
	if not scene:
		push_error("[SPAWN] Failed to load traffic.tscn!")
		return
	var road_starts = []
	for road_x_idx in range(-6, 7, 2):
		var road_x = road_x_idx * 50
		var lane_offset = 2.0 if randi() % 2 == 0 else -2.0
		var start_z = randf_range(-250, 250)
		road_starts.append({"pos": Vector3(road_x + lane_offset, 0.2, start_z), "axis": "ns"})
	for road_z_idx in range(-6, 7, 2):
		var road_z = road_z_idx * 50
		var lane_offset = 2.0 if randi() % 2 == 0 else -2.0
		var start_x = randf_range(-250, 250)
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
	for road_idx in range(-7, 8):
		var road_x = road_idx * 50
		for offset_z in [-40, -15, 15, 40, 70, -70, 100, -100]:
			if randi() % 3 != 0:
				var side = 4.8 if randi() % 2 == 0 else -4.8
				positions.append(Vector3(road_x + side, 0.2, offset_z))
	for road_idx in range(-7, 8):
		var road_z = road_idx * 50
		for offset_x in [-40, -15, 15, 40, 70, -70, 100, -100]:
			if randi() % 3 != 0:
				var side = 4.8 if randi() % 2 == 0 else -4.8
				positions.append(Vector3(offset_x, 0.2, road_z + side))
	positions.shuffle()
	var count = mini(30, positions.size())
	for i in range(count):
		var pos = positions[i]
		var car = scene.instantiate()
		add_child(car)
		car.global_position = pos
		if abs(fmod(pos.x, 50.0)) < 8.0:
			car.rotation.y = 0
		else:
			car.rotation.y = PI / 2
	print("[SPAWN] Spawned %d parked vehicles" % count)

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
	for i in range(8):
		var dog = scene.instantiate()
		dog.animal_type = "dog"
		add_child(dog)
		dog.global_position = Vector3(randf_range(-150, 150), 0.5, randf_range(-150, 150))
	for i in range(6):
		var cat = scene.instantiate()
		cat.animal_type = "cat"
		add_child(cat)
		cat.global_position = Vector3(randf_range(-150, 150), 0.5, randf_range(-150, 150))
	print("[SPAWN] Spawned 8 dogs + 6 cats")

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
