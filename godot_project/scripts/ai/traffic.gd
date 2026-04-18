extends RigidBody3D
# Traffic AI — NPC cars that drive along city roads with visible drivers

@export var speed = 12.0
@export var max_speed = 25.0
var road_axis = "ns"  # "ns" = north-south, "ew" = east-west

var current_speed = 0.0
var direction = Vector3.ZERO
var waypoint_index = 0
var waypoints: Array = []
var stopping = false
var stop_timer = 0.0
var is_player_driving = false
var player: Node3D = null
var turn_speed = 3.0

func _ready():
	add_to_group("traffic")
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	freeze = true
	# Remove old box mesh
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_car_model()
	_add_npc_driver()
	speed = randf_range(10.0, 20.0)
	generate_road_path()

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mat.metallic = 0.4
	return mat

func _build_car_model():
	var colors = [
		Color(0.7, 0.15, 0.15), Color(0.15, 0.15, 0.7), Color(0.85, 0.85, 0.85),
		Color(0.12, 0.12, 0.12), Color(0.15, 0.55, 0.15), Color(0.8, 0.65, 0.1),
		Color(0.6, 0.3, 0.1), Color(0.4, 0.1, 0.5), Color(0.9, 0.9, 0.9),
		Color(0.05, 0.25, 0.5), Color(0.6, 0.0, 0.0), Color(0.3, 0.3, 0.35),
	]
	var car_color = colors[randi() % colors.size()]

	# Body
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.0, 0.7, 4.0)
	bm.material = _make_mat(car_color)
	body.mesh = bm
	body.position = Vector3(0, 0.55, 0)
	add_child(body)

	# Cabin
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(1.8, 0.5, 2.0)
	cm.material = _make_mat(car_color.darkened(0.1))
	cabin.mesh = cm
	cabin.position = Vector3(0, 1.1, -0.2)
	add_child(cabin)

	# Windshield
	var windshield = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = Vector3(1.7, 0.4, 0.05)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.5, 0.65, 0.85, 0.4)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	wm.material = glass_mat
	windshield.mesh = wm
	windshield.position = Vector3(0, 1.1, 0.8)
	windshield.rotation.x = -0.2
	add_child(windshield)

	# Rear window
	var rear_w = MeshInstance3D.new()
	rear_w.mesh = wm
	rear_w.position = Vector3(0, 1.1, -1.2)
	rear_w.rotation.x = 0.2
	add_child(rear_w)

	# Headlights
	for side in [-1, 1]:
		var hl = MeshInstance3D.new()
		var hlm = SphereMesh.new()
		hlm.radius = 0.1
		var hl_mat = StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 1.0, 0.9)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 1.0, 0.8)
		hl_mat.emission_energy_multiplier = 0.3
		hlm.material = hl_mat
		hl.mesh = hlm
		hl.position = Vector3(side * 0.7, 0.5, 2.0)
		add_child(hl)

	# Taillights
	for side in [-1, 1]:
		var tl = MeshInstance3D.new()
		var tlm = BoxMesh.new()
		tlm.size = Vector3(0.18, 0.08, 0.04)
		var tl_mat = StandardMaterial3D.new()
		tl_mat.albedo_color = Color(0.8, 0.05, 0.05)
		tl_mat.emission_enabled = true
		tl_mat.emission = Color(0.7, 0.0, 0.0)
		tl_mat.emission_energy_multiplier = 0.3
		tlm.material = tl_mat
		tl.mesh = tlm
		tl.position = Vector3(side * 0.7, 0.5, -2.0)
		add_child(tl)

	# Wheels
	for x in [-0.95, 0.95]:
		for z in [-1.2, 1.2]:
			var wheel = MeshInstance3D.new()
			var whl = CylinderMesh.new()
			whl.top_radius = 0.25
			whl.bottom_radius = 0.25
			whl.height = 0.15
			whl.material = _make_mat(Color(0.1, 0.1, 0.1))
			wheel.mesh = whl
			wheel.position = Vector3(x, 0.2, z)
			wheel.rotation.z = PI / 2
			add_child(wheel)

func _add_npc_driver():
	# Visible NPC sitting in the driver seat
	var CharModel = load("res://scripts/utils/character_model.gd")
	var driver = Node3D.new()
	driver.name = "Driver"
	var model = Node3D.new()
	model.set_script(CharModel)
	# Randomize driver appearance
	var skins = [Color(0.95, 0.82, 0.68), Color(0.87, 0.72, 0.55), Color(0.72, 0.55, 0.40), Color(0.55, 0.38, 0.26)]
	var shirts = [Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.8), Color(0.3, 0.7, 0.3), Color(0.9, 0.9, 0.3), Color(0.5, 0.5, 0.5)]
	model.skin_color = skins[randi() % skins.size()]
	model.shirt_color = shirts[randi() % shirts.size()]
	model.pants_color = Color(0.15, 0.15, 0.2)
	model.shoe_color = Color(0.15, 0.1, 0.05)
	model.hair_color = [Color(0.1, 0.07, 0.03), Color(0.6, 0.4, 0.15), Color(0.2, 0.1, 0.05)][randi() % 3]
	driver.add_child(model)
	model.build()
	# Position driver inside cabin (left seat)
	driver.position = Vector3(-0.35, 0.65, 0.0)
	driver.scale = Vector3(0.5, 0.5, 0.5)  # Slightly smaller to fit in car
	add_child(driver)

func is_npc_driving() -> bool:
	return not is_player_driving

func _physics_process(delta):
	if is_player_driving and player:
		_handle_player_driving(delta)
		return
	if waypoints.is_empty():
		return

	# Occasional stop at intersections
	if stopping:
		stop_timer -= delta
		if stop_timer <= 0:
			stopping = false
		return

	var target_waypoint = waypoints[waypoint_index]
	var to_target = target_waypoint - global_position
	to_target.y = 0
	var distance = to_target.length()

	if distance < 3.0:
		waypoint_index = (waypoint_index + 1) % waypoints.size()
		# Random chance to stop at waypoints (simulate traffic lights)
		if randf() < 0.15:
			stopping = true
			stop_timer = randf_range(2.0, 5.0)
		return

	direction = to_target.normalized()
	current_speed = speed

	# Avoid player (brake if close)
	if Globals.player:
		var dist_to_player = global_position.distance_to(Globals.player.global_position)
		if dist_to_player < 8.0:
			current_speed *= 0.3
		if dist_to_player < 4.0:
			current_speed = 0.0

	# Move vehicle along road
	position += direction * current_speed * delta
	# Face movement direction
	rotation.y = atan2(direction.x, direction.z)

func generate_road_path():
	# Generate waypoints along actual road grid (roads at multiples of 22)
	waypoints.clear()
	var start = global_position

	if road_axis == "ns":
		# Drive north-south along current X road
		var x = start.x
		# Drive forward, turn at intersection, come back
		var road_points = []
		for z in range(-3, 4):
			road_points.append(Vector3(x, 0.5, z * 22.0))
		# Add turns onto cross streets
		var turn_x = x + (22.0 if randf() > 0.5 else -22.0)
		road_points.append(Vector3(turn_x, 0.5, 3 * 22.0))
		for z in range(3, -4, -1):
			road_points.append(Vector3(turn_x, 0.5, z * 22.0))
		road_points.append(Vector3(x, 0.5, -3 * 22.0))
		waypoints = road_points
	else:
		# Drive east-west along current Z road
		var z = start.z
		var road_points = []
		for x in range(-3, 4):
			road_points.append(Vector3(x * 22.0, 0.5, z))
		var turn_z = z + (22.0 if randf() > 0.5 else -22.0)
		road_points.append(Vector3(3 * 22.0, 0.5, turn_z))
		for x in range(3, -4, -1):
			road_points.append(Vector3(x * 22.0, 0.5, turn_z))
		road_points.append(Vector3(-3 * 22.0, 0.5, z))
		waypoints = road_points

func player_entered(p: Node3D):
	player = p
	is_player_driving = true
	p.global_position = global_position + Vector3(0, 1.5, 0)
	p.is_in_vehicle = true
	if p.model_root:
		p.model_root.visible = false
	# Remove NPC driver (carjacked!)
	var driver_node = get_node_or_null("Driver")
	if driver_node:
		driver_node.queue_free()
	Globals.vehicles_stolen += 1

func exit_vehicle():
	if player:
		player.is_in_vehicle = false
		player.current_vehicle = null
		var exit_dir = global_transform.basis.x.normalized()
		player.global_position = global_position + exit_dir * 3.0 + Vector3(0, 1, 0)
		if player.model_root:
			player.model_root.visible = true
		is_player_driving = false
		player = null
		current_speed = 0.0

func _handle_player_driving(delta):
	var accel_input = 0.0
	if Input.is_action_pressed("ui_up"):
		accel_input = -1.0
	if Input.is_action_pressed("ui_down"):
		accel_input = 1.0
	if Input.is_action_pressed("ui_left"):
		rotation.y += turn_speed * delta * clamp(abs(current_speed) / max_speed, 0.15, 1.0)
	if Input.is_action_pressed("ui_right"):
		rotation.y -= turn_speed * delta * clamp(abs(current_speed) / max_speed, 0.15, 1.0)

	if accel_input != 0:
		current_speed = move_toward(current_speed, accel_input * max_speed, 2.5)
	else:
		current_speed = move_toward(current_speed, 0, 3.0)

	var forward = -global_transform.basis.z
	position += forward * current_speed * delta

	if Input.is_action_just_pressed("interact"):
		exit_vehicle()
