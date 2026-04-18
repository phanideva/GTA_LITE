# main_new.gd
# Main Game Scene — Modern GTA-style Open World
# Integrates all new systems: Player, Vehicles, AI, World, Missions
extends Node3D

# Core references
var player: CharacterBody3D
var world: Node3D

# New system references
var city_generator: Node3D
var time_weather: Node
var traffic_manager: Node
var mission_manager: Node
var game_manager: Node
var event_bus: Node

# Legacy system references (for compatibility)
var economy: Node
var save_system: Node

# Spawned entities
var npcs: Array[Node3D] = []
var vehicles: Array[Node3D] = []

func _ready() -> void:
	await get_tree().process_frame
	
	_setup_autoloads()
	_setup_world()
	_setup_player()
	_setup_systems()
	_spawn_entities()
	_connect_signals()
	
	_show_game_intro()
	
	print("=== Gangster Town Adventures — Modern Edition Ready ===")
	print("WASD: Move | Mouse: Look | LMB: Shoot | RMB: Aim")
	print("E: Enter Vehicle | F: Interact | Space: Jump | Shift: Sprint")
	print("Tab: Mission Log | M: Map | P: Pause")

func _setup_autoloads() -> void:
	# Check for existing autoloads or create them
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = Node.new()
		game_manager.name = "GameManager"
		var script = load("res://scripts/core/game_manager.gd")
		if script:
			game_manager.set_script(script)
		get_tree().root.add_child(game_manager)
	
	event_bus = get_node_or_null("/root/EventBus")
	if not event_bus:
		event_bus = Node.new()
		event_bus.name = "EventBus"
		var script = load("res://scripts/core/event_bus.gd")
		if script:
			event_bus.set_script(script)
		get_tree().root.add_child(event_bus)

func _setup_world() -> void:
	# Create world container
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	
	# City generator
	city_generator = Node3D.new()
	city_generator.name = "CityGenerator"
	var city_script = load("res://scripts/world/city_generator.gd")
	if city_script:
		city_generator.set_script(city_script)
	world.add_child(city_generator)
	
	# Time and weather
	time_weather = Node.new()
	time_weather.name = "TimeWeather"
	var weather_script = load("res://scripts/world/time_weather.gd")
	if weather_script:
		time_weather.set_script(weather_script)
	world.add_child(time_weather)
	
	# Generate city (or use existing world environment)
	if city_generator.has_method("generate_city"):
		city_generator.call("generate_city")
	else:
		_create_fallback_world()

func _create_fallback_world() -> void:
	# Create basic world if city generator not available
	print("Using fallback world generation...")
	
	# Ground plane
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(500, 500)
	ground.mesh = ground_mesh
	
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.2, 0.25, 0.2)
	ground.material_override = ground_mat
	
	var ground_collision = StaticBody3D.new()
	var ground_shape = CollisionShape3D.new()
	var ground_box = BoxShape3D.new()
	ground_box.size = Vector3(500, 0.1, 500)
	ground_shape.shape = ground_box
	ground_collision.add_child(ground_shape)
	ground.add_child(ground_collision)
	
	world.add_child(ground)
	
	# Basic lighting
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	world.add_child(sun)
	
	# Environment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.sky = sky
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env_node.environment = env
	world.add_child(env_node)
	
	# Some basic buildings
	for i in range(-4, 5):
		for j in range(-4, 5):
			if randf() < 0.5:
				_create_basic_building(Vector3(i * 50, 0, j * 50))

func _create_basic_building(position: Vector3) -> void:
	var building = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var height = randf_range(10, 50)
	mesh.size = Vector3(randf_range(15, 30), height, randf_range(15, 30))
	building.mesh = mesh
	building.position = position + Vector3(0, height * 0.5, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(randf_range(0.4, 0.7), randf_range(0.4, 0.7), randf_range(0.4, 0.7))
	building.material_override = mat
	
	var collision = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = mesh.size
	col_shape.shape = box
	collision.add_child(col_shape)
	building.add_child(collision)
	
	world.add_child(building)

func _setup_player() -> void:
	# Try to use new player controller first
	var new_player_script = load("res://scripts/actors/player/player_controller.gd")
	
	if new_player_script:
		player = CharacterBody3D.new()
		player.name = "Player"
		player.set_script(new_player_script)
		player.collision_layer = 16
		player.collision_mask = 15
		player.global_position = Vector3(25, 1, 25)
		player.add_to_group("player")
		add_child(player)
	else:
		# Fall back to old player
		var old_player_scene = load("res://scenes/player/player.tscn")
		if old_player_scene:
			player = old_player_scene.instantiate()
			player.global_position = Vector3(25, 1, 25)
			add_child(player)
	
	# Set in globals
	if get_node_or_null("/root/Globals"):
		Globals.player = player

func _setup_systems() -> void:
	# Traffic manager
	traffic_manager = Node.new()
	traffic_manager.name = "TrafficManager"
	var traffic_script = load("res://scripts/vehicles/traffic_manager.gd")
	if traffic_script:
		traffic_manager.set_script(traffic_script)
	add_child(traffic_manager)
	
	# Mission manager
	mission_manager = Node.new()
	mission_manager.name = "MissionManager"
	var mission_script = load("res://scripts/systems/mission_manager.gd")
	if mission_script:
		mission_manager.set_script(mission_script)
	add_child(mission_manager)
	
	# Economy (legacy compatibility)
	economy = Node.new()
	economy.name = "Economy"
	var economy_script = load("res://scripts/systems/economy.gd")
	if economy_script:
		economy.set_script(economy_script)
	add_child(economy)
	
	# Save/Load system
	save_system = Node.new()
	save_system.name = "SaveSystem"
	var save_script = load("res://scripts/systems/save_load.gd")
	if save_script:
		save_system.set_script(save_script)
	add_child(save_system)

func _spawn_entities() -> void:
	_spawn_npcs()
	_spawn_vehicles()
	_spawn_weapon_pickups()

func _spawn_npcs() -> void:
	# Try new NPC system first
	var civilian_script = load("res://scripts/actors/npcs/civilian_ai.gd")
	var police_script = load("res://scripts/actors/npcs/police_ai.gd")
	var gang_script = load("res://scripts/actors/npcs/gang_ai.gd")
	
	var spawn_positions = _get_npc_spawn_positions()
	
	# Spawn civilians
	for i in range(min(15, spawn_positions.size())):
		var npc: CharacterBody3D
		
		if civilian_script:
			npc = CharacterBody3D.new()
			npc.set_script(civilian_script)
		else:
			var scene = load("res://scenes/ai/pedestrian.tscn")
			if scene:
				npc = scene.instantiate()
		
		if npc:
			npc.add_to_group("npcs")
			npc.add_to_group("civilians")
			add_child(npc)
			npc.global_position = spawn_positions[i]
			npcs.append(npc)
	
	# Spawn police
	for i in range(3):
		var police: CharacterBody3D
		
		if police_script:
			police = CharacterBody3D.new()
			police.set_script(police_script)
		else:
			var scene = load("res://scenes/ai/police.tscn")
			if scene:
				police = scene.instantiate()
		
		if police:
			police.add_to_group("npcs")
			police.add_to_group("police")
			add_child(police)
			police.global_position = Vector3(
				randf_range(30, 100) * (1 if randi() % 2 == 0 else -1),
				0.5,
				randf_range(30, 100) * (1 if randi() % 2 == 0 else -1)
			)
			npcs.append(police)
	
	# Spawn gang members
	for i in range(5):
		var gangster: CharacterBody3D
		
		if gang_script:
			gangster = CharacterBody3D.new()
			gangster.set_script(gang_script)
		else:
			var scene = load("res://scenes/ai/gangster.tscn")
			if scene:
				gangster = scene.instantiate()
		
		if gangster:
			gangster.add_to_group("npcs")
			gangster.add_to_group("gangsters")
			add_child(gangster)
			gangster.global_position = Vector3(
				randf_range(50, 120) * (1 if randi() % 2 == 0 else -1),
				0.5,
				randf_range(50, 120) * (1 if randi() % 2 == 0 else -1)
			)
			npcs.append(gangster)

func _get_npc_spawn_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	
	for i in range(-3, 4):
		for j in range(-3, 4):
			positions.append(Vector3(i * 30 + 5, 0.5, j * 30 + 5))
			positions.append(Vector3(i * 30 - 5, 0.5, j * 30 - 5))
	
	positions.shuffle()
	return positions

func _spawn_vehicles() -> void:
	# Try new vehicle system
	var vehicle_script = load("res://scripts/vehicles/vehicle_base.gd")
	
	var vehicle_positions = [
		Vector3(30, 0.5, 25),   # Near player
		Vector3(-20, 0.5, 30),
		Vector3(50, 0.5, -25),
		Vector3(-30, 0.5, -40),
		Vector3(60, 0.5, 50),
		Vector3(-60, 0.5, 20),
		Vector3(20, 0.5, 60),
		Vector3(-45, 0.5, 45),
	]
	
	for i in range(vehicle_positions.size()):
		var vehicle: Node3D
		
		if vehicle_script:
			vehicle = VehicleBody3D.new()
			vehicle.set_script(vehicle_script)
		else:
			var scene = load("res://scenes/vehicles/vehicle.tscn")
			if scene:
				vehicle = scene.instantiate()
		
		if vehicle:
			vehicle.add_to_group("vehicles")
			add_child(vehicle)
			vehicle.global_position = vehicle_positions[i]
			vehicle.rotation.y = [0, PI/2, PI, -PI/2][randi() % 4]
			vehicles.append(vehicle)

func _spawn_weapon_pickups() -> void:
	var pickup_script = load("res://scripts/systems/weapon_pickup.gd")
	if not pickup_script:
		return
	
	var pickup_data = [
		[Vector3(20, 0.5, 20), 1, 30],   # Pistol
		[Vector3(-20, 0.5, 20), 2, 60],  # Rifle
		[Vector3(20, 0.5, -20), 3, 20],  # Shotgun
		[Vector3(-20, 0.5, -20), 1, 30], # Pistol
		[Vector3(40, 0.5, 40), 2, 60],   # Rifle
	]
	
	for data in pickup_data:
		var pickup = Area3D.new()
		pickup.set_script(pickup_script)
		if pickup.has_method("set") or "weapon_type" in pickup:
			pickup.weapon_type = data[1]
			pickup.ammo_amount = data[2]
		add_child(pickup)
		pickup.global_position = data[0]

func _connect_signals() -> void:
	# Connect mission signals
	if mission_manager:
		if mission_manager.has_signal("mission_started"):
			mission_manager.connect("mission_started", _on_mission_started)
		if mission_manager.has_signal("mission_completed"):
			mission_manager.connect("mission_completed", _on_mission_completed)
		if mission_manager.has_signal("mission_failed"):
			mission_manager.connect("mission_failed", _on_mission_failed)
	
	# Connect event bus signals
	if event_bus:
		if event_bus.has_signal("player_died"):
			event_bus.connect("player_died", _on_player_died)

func _process(delta: float) -> void:
	_handle_input()

func _handle_input() -> void:
	# Start mission
	if Input.is_action_just_pressed("start_mission"):
		if mission_manager and mission_manager.has_method("get_available_missions"):
			var available = mission_manager.get_available_missions()
			if available.size() > 0:
				mission_manager.start_mission(available[0].id)
	
	# Save/Load
	if Input.is_action_just_pressed("save"):
		if save_system and save_system.has_method("save_game"):
			save_system.save_game()
			print("Game saved!")
	
	if Input.is_action_just_pressed("load"):
		if save_system and save_system.has_method("load_game"):
			save_system.load_game()
			print("Game loaded!")
	
	# Pause
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused

# ============= Callbacks =============

func _on_mission_started(mission) -> void:
	print("Mission started: ", mission.name if mission else "Unknown")
	
	# Show mission title
	var cutscene = get_node_or_null("/root/Cutscene")
	if cutscene and cutscene.has_method("show_mission_title"):
		cutscene.show_mission_title(mission.name)

func _on_mission_completed(mission) -> void:
	print("Mission completed: ", mission.name if mission else "Unknown")
	
	# Play sound
	var sfx = get_node_or_null("/root/SFX")
	if sfx and sfx.has_method("play_sfx"):
		sfx.play_sfx("mission_complete")

func _on_mission_failed(mission, reason: String) -> void:
	print("Mission failed: ", reason)

func _on_player_died() -> void:
	print("Player died!")
	# Respawn logic here

# ============= Intro Sequence =============

var intro_overlay: Control = null

func _show_game_intro() -> void:
	intro_overlay = Control.new()
	intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.z_index = 100
	add_child(intro_overlay)
	
	# Letterbox bars
	var top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 100
	intro_overlay.add_child(top_bar)
	
	var bottom_bar = ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.custom_minimum_size.y = 100
	intro_overlay.add_child(bottom_bar)
	
	# Title
	var title_container = CenterContainer.new()
	title_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(title_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	title_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "GANGSTER TOWN"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "ADVENTURES"
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	var location = Label.new()
	location.text = "Liberty District"
	location.add_theme_font_size_override("font_size", 24)
	location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0))
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(location)
	
	# Animate
	var tween = create_tween()
	
	tween.tween_method(func(a): title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a)), 0.0, 1.0, 1.0)
	tween.tween_method(func(a): subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a)), 0.0, 1.0, 0.5)
	tween.tween_method(func(a): location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, a)), 0.0, 1.0, 0.5)
	tween.tween_interval(3.0)
	
	tween.tween_method(func(a):
		title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, a))
		subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, a))
		location.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, a))
		top_bar.color.a = a
		bottom_bar.color.a = a
	, 1.0, 0.0, 1.0)
	
	tween.tween_callback(func(): intro_overlay.queue_free())
