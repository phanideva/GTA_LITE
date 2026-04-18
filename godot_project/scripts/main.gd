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
	mission_system.set_script(load("res://scripts/systems/mission_system.gd"))
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

	print("=== GTA Advanced 3D — Ready ===")
	print("WASD: Move | Mouse: Look | LMB: Shoot | F: Melee | E: Enter Vehicle")
	print("1/2/3/4: Switch Weapon | Space: Jump | Shift: Sprint")
	print("M: Start Random Mission | Alt+S: Save | Alt+L: Load")

func _process(_delta):
	if Input.is_action_just_pressed("start_mission"):
		var idx = randi() % mission_system.missions.size()
		mission_system.start_mission(idx)

	if Input.is_action_just_pressed("save"):
		save_system.save_game()
		print("Saved!")

	if Input.is_action_just_pressed("load"):
		save_system.load_game()
		print("Loaded!")

func spawn_npcs():
	var scene = load("res://scenes/ai/pedestrian.tscn")
	for i in range(8):
		var npc = scene.instantiate()
		add_child(npc)
		npc.global_position = Vector3(randf_range(-60, 60), 1, randf_range(-60, 60))

func spawn_police():
	var scene = load("res://scenes/ai/police.tscn")
	for i in range(3):
		var cop = scene.instantiate()
		add_child(cop)
		cop.global_position = Vector3(randf_range(-60, 60), 1, randf_range(-60, 60))

func spawn_gangsters():
	var scene = load("res://scenes/ai/gangster.tscn")
	for i in range(5):
		var g = scene.instantiate()
		add_child(g)
		g.global_position = Vector3(randf_range(-60, 60), 1, randf_range(-60, 60))
		# Hook gangster death to mission system
		g.connect("tree_exited", _on_enemy_killed)

func spawn_traffic():
	var scene = load("res://scenes/vehicles/traffic.tscn")
	for i in range(4):
		var car = scene.instantiate()
		add_child(car)
		car.global_position = Vector3(randf_range(-40, 40), 0.5, randf_range(-40, 40))

func spawn_vehicles():
	var scene = load("res://scenes/vehicles/vehicle.tscn")
	var positions = [
		Vector3(10, 0.5, 0), Vector3(-20, 0.5, 15),
		Vector3(30, 0.5, -25), Vector3(-10, 0.5, -30),
		Vector3(45, 0.5, 10), Vector3(-45, 0.5, -20),
	]
	for pos in positions:
		var car = scene.instantiate()
		add_child(car)
		car.global_position = pos

func spawn_motorcycles():
	var scene = load("res://scenes/vehicles/motorcycle.tscn")
	# Motorcycles
	for i in range(3):
		var bike = scene.instantiate()
		add_child(bike)
		bike.global_position = Vector3(randf_range(-50, 50), 0.5, randf_range(-50, 50))
	# Bicycles
	for i in range(3):
		var bicycle = scene.instantiate()
		bicycle.is_bicycle = true
		add_child(bicycle)
		bicycle.global_position = Vector3(randf_range(-50, 50), 0.5, randf_range(-50, 50))

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
