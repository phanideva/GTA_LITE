extends Node3D
# Main Game Scene — Advanced GTA 3D

var player: CharacterBody3D
var mission_system: Node
var economy: Node
var save_system: Node
var world: Node3D

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
	
	# Start ambient sounds
	SFX.start_ambient()

	# Wire the cutscene system to the mission system dialogue calls
	mission_system.connect("mission_started", _on_mission_started)
	mission_system.connect("mission_completed", _on_mission_completed)

	# Cinematic game start overlay
	_show_game_intro()

	# Show initial mission prompt on HUD after a short delay
	await get_tree().create_timer(4.5).timeout
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("update_mission"):
			hud.update_mission("Press M to start: " + mission_system.story_missions[0]["title"])

var bird_timer = 0.0
var intro_overlay: Control = null
var intro_music_player: AudioStreamPlayer = null

func _show_game_intro():
	# Play intro music
	_play_intro_music()
	
	# Cinematic overlay when entering the game world
	intro_overlay = Control.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.z_index = 100
	add_child(intro_overlay)

	# Letterbox bars (cinematic)
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

	# GTA-style logo/title
	var logo_container = Control.new()
	logo_container.set_anchors_preset(Control.PRESET_CENTER)
	logo_container.position = Vector2(-350, -180)
	logo_container.size = Vector2(700, 300)
	intro_overlay.add_child(logo_container)
	
	# Title text - stylized
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
	
	# Subtitle - "ADVENTURES"
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

	# Location text (GTA-style)
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

	# Animation sequence
	var tween = create_tween()
	
	# Fade in title with shadow
	tween.tween_method(func(a): 
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
		title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.6))
	, 0.0, 1.0, 1.5)
	
	# Fade in subtitle
	tween.tween_method(func(a): 
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
		subtitle_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, a * 0.5))
	, 0.0, 1.0, 0.8)
	
	# Show location
	tween.tween_interval(0.5)
	tween.tween_method(func(a): 
		location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, a))
	, 0.0, 1.0, 0.6)
	tween.tween_method(func(a): 
		tagline.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, a))
	, 0.0, 1.0, 0.5)
	
	# Hold for dramatic effect
	tween.tween_interval(3.0)
	
	# Fade out everything
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
	# Ambient bird chirps at random intervals
	bird_timer -= _delta
	if bird_timer <= 0:
		SFX.play_ambient_bird()
		bird_timer = randf_range(8.0, 25.0)

	if Input.is_action_just_pressed("start_mission"):
		# Start the next story mission (sequential)
		if not mission_system.start_mission(0):
			print("Mission already active or story complete!")

	if Input.is_action_just_pressed("save"):
		save_system.save_game()
		print("Saved!")

	if Input.is_action_just_pressed("load"):
		save_system.load_game()
		print("Loaded!")

func _on_mission_started(title: String):
	# Use new cutscene system for mission intro title card
	if Cutscene:
		Cutscene.show_mission_title(title)

func _on_mission_completed(title: String, reward: int):
	SFX.play_sfx("mission_complete")
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("show_mission_complete"):
			hud.show_mission_complete(title, reward)

func spawn_npcs():
	var scene = load("res://scenes/ai/pedestrian.tscn")
	# Spawn pedestrians on sidewalks along roads
	var sidewalk_spots = []
	for i in range(-3, 4):
		for j in range(-3, 4):
			# Place near road intersections on the sidewalk (offset from road center)
			# Y=0.5 to let them fall gently to ground
			sidewalk_spots.append(Vector3(i * 22 + 4, 0.5, j * 22 + 4))
			sidewalk_spots.append(Vector3(i * 22 - 4, 0.5, j * 22 - 4))
	sidewalk_spots.shuffle()
	for i in range(min(20, sidewalk_spots.size())):
		var npc = scene.instantiate()
		add_child(npc)
		npc.global_position = sidewalk_spots[i]

func spawn_police():
	var scene = load("res://scenes/ai/police.tscn")
	for i in range(3):
		var cop = scene.instantiate()
		add_child(cop)
		var x = randf_range(20, 70) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(20, 70) * (1 if randi() % 2 == 0 else -1)
		cop.global_position = Vector3(x, 0.5, z)

func spawn_gangsters():
	var scene = load("res://scenes/ai/gangster.tscn")
	for i in range(5):
		var g = scene.instantiate()
		add_child(g)
		# Place gangsters far from player spawn (avoid near origin)
		var x = randf_range(30, 80) * (1 if randi() % 2 == 0 else -1)
		var z = randf_range(30, 80) * (1 if randi() % 2 == 0 else -1)
		g.global_position = Vector3(x, 0.5, z)
		g.connect("tree_exited", _on_enemy_killed)

func spawn_traffic():
	var scene = load("res://scenes/vehicles/traffic.tscn")
	# Spawn traffic on actual road grid (roads are at multiples of 22)
	var road_starts = [
		# North-South roads
		{"pos": Vector3(0, 0.5, -60), "axis": "ns"},
		{"pos": Vector3(22, 0.5, 60), "axis": "ns"},
		{"pos": Vector3(-22, 0.5, -40), "axis": "ns"},
		{"pos": Vector3(44, 0.5, 30), "axis": "ns"},
		{"pos": Vector3(-44, 0.5, -20), "axis": "ns"},
		# East-West roads
		{"pos": Vector3(-60, 0.5, 0), "axis": "ew"},
		{"pos": Vector3(50, 0.5, 22), "axis": "ew"},
		{"pos": Vector3(-40, 0.5, -22), "axis": "ew"},
		{"pos": Vector3(30, 0.5, 44), "axis": "ew"},
		{"pos": Vector3(-30, 0.5, -44), "axis": "ew"},
	]
	for rd in road_starts:
		var car = scene.instantiate()
		add_child(car)
		car.global_position = rd["pos"]
		car.road_axis = rd["axis"]

func spawn_vehicles():
	var scene = load("res://scenes/vehicles/vehicle.tscn")
	# Park vehicles near sidewalks/buildings with varied positions
	# First vehicle VERY close to player spawn (22, 1, 22) for easy testing
	var positions = [
		Vector3(26, 0.5, 22),   # Right next to player spawn!
		Vector3(25, 0.5, 18), Vector3(-18, 0.5, 25),
		Vector3(47, 0.5, -20), Vector3(-25, 0.5, -35),
		Vector3(50, 0.5, 45), Vector3(-50, 0.5, -18),
		Vector3(15, 0.5, 48), Vector3(-40, 0.5, 40),
		Vector3(65, 0.5, 10), Vector3(-65, 0.5, -10),
		Vector3(30, 0.5, -55), Vector3(-30, 0.5, 55),
	]
	for pos in positions:
		var car = scene.instantiate()
		add_child(car)
		car.global_position = pos
		car.rotation.y = [0, PI/2, PI, -PI/2][randi() % 4]
	print("[VEHICLES] Spawned %d vehicles - closest at (26, 0.5, 22)" % positions.size())

func spawn_motorcycles():
	var scene = load("res://scenes/vehicles/motorcycle.tscn")
	# Motorcycles — parked near buildings
	var moto_pos = [
		Vector3(20, 0.5, 26), Vector3(-26, 0.5, 20),
		Vector3(45, 0.5, -15), Vector3(-45, 0.5, 15),
		Vector3(68, 0.5, 30),
	]
	for pos in moto_pos:
		var bike = scene.instantiate()
		add_child(bike)
		bike.global_position = pos
		bike.rotation.y = randf_range(0, TAU)
	# Bicycles — near parks and sidewalks
	var bike_pos = [
		Vector3(8, 0.5, 10), Vector3(-10, 0.5, 8),
		Vector3(30, 0.5, 30), Vector3(-30, 0.5, -30),
		Vector3(55, 0.5, 50),
	]
	for pos in bike_pos:
		var bicycle = scene.instantiate()
		bicycle.is_bicycle = true
		add_child(bicycle)
		bicycle.global_position = pos
		bicycle.rotation.y = randf_range(0, TAU)

func spawn_animals():
	var scene = load("res://scenes/ai/animal.tscn")
	# Dogs
	for i in range(4):
		var dog = scene.instantiate()
		dog.animal_type = "dog"
		add_child(dog)
		dog.global_position = Vector3(randf_range(-55, 55), 0.5, randf_range(-55, 55))
	# Cats
	for i in range(3):
		var cat = scene.instantiate()
		cat.animal_type = "cat"
		add_child(cat)
		cat.global_position = Vector3(randf_range(-55, 55), 0.5, randf_range(-55, 55))

func spawn_weapon_pickups():
	var pickup_script = load("res://scripts/systems/weapon_pickup.gd")
	var pickup_positions = [
		[Vector3(15, 0.5, 15), 1, 30],   # Pistol
		[Vector3(-15, 0.5, 15), 2, 60],  # Rifle
		[Vector3(15, 0.5, -15), 3, 20],  # Shotgun
		[Vector3(-15, 0.5, -15), 1, 30], # Pistol
		[Vector3(35, 0.5, 35), 2, 60],   # Rifle
		[Vector3(-35, 0.5, -35), 3, 20], # Shotgun
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
