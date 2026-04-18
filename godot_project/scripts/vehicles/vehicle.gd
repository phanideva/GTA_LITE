extends RigidBody3D
# Vehicle — realistic car with body, wheels, windows

@export var max_speed = 50.0
@export var acceleration = 2.0
@export var brake_force = 3.0
@export var turn_speed = 3.0
@export var vehicle_type: String = "sedan"  # sedan, suv, sports

var current_speed = 0.0
var is_player_driving = false
var player: Node3D = null
var engine_running = false
var health = 200
var wheel_nodes: Array = []

func _ready():
	add_to_group("vehicle")
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	freeze = true
	# Remove old box mesh
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_car_model()

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.3
	mat.metallic = 0.5
	return mat

func _build_car_model():
	var colors = [
		Color(0.85, 0.1, 0.1), Color(0.1, 0.3, 0.85), Color(0.9, 0.9, 0.9),
		Color(0.08, 0.08, 0.08), Color(0.1, 0.6, 0.15), Color(0.9, 0.7, 0.0),
		Color(0.5, 0.0, 0.5), Color(0.8, 0.4, 0.1),
	]
	var car_color = colors[randi() % colors.size()]

	var body_w = 2.2
	var body_h = 0.8
	var body_l = 4.5

	# Lower body (main chassis)
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(body_w, body_h, body_l)
	bm.material = _make_mat(car_color)
	body.mesh = bm
	body.position = Vector3(0, 0.6, 0)
	add_child(body)

	# Cabin / upper body
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(body_w - 0.2, 0.6, body_l * 0.5)
	cm.material = _make_mat(car_color.darkened(0.1))
	cabin.mesh = cm
	cabin.position = Vector3(0, 1.2, -0.2)
	add_child(cabin)

	# Windshield (front)
	var windshield = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = Vector3(body_w - 0.3, 0.5, 0.05)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.6, 0.75, 0.9, 0.5)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.3
	wm.material = glass_mat
	windshield.mesh = wm
	windshield.position = Vector3(0, 1.15, 0.9)
	windshield.rotation.x = -0.25
	add_child(windshield)

	# Rear window
	var rear_w = MeshInstance3D.new()
	rear_w.mesh = wm
	rear_w.position = Vector3(0, 1.15, -1.3)
	rear_w.rotation.x = 0.25
	add_child(rear_w)

	# Headlights
	for side in [-1, 1]:
		var hl = MeshInstance3D.new()
		var hlm = SphereMesh.new()
		hlm.radius = 0.12
		hlm.height = 0.15
		var hl_mat = StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 1.0, 0.9)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 1.0, 0.8)
		hl_mat.emission_energy_multiplier = 0.5
		hlm.material = hl_mat
		hl.mesh = hlm
		hl.position = Vector3(side * 0.7, 0.55, body_l / 2.0)
		add_child(hl)

	# Taillights (red)
	for side in [-1, 1]:
		var tl = MeshInstance3D.new()
		var tlm = BoxMesh.new()
		tlm.size = Vector3(0.2, 0.1, 0.05)
		var tl_mat = StandardMaterial3D.new()
		tl_mat.albedo_color = Color(0.9, 0.1, 0.1)
		tl_mat.emission_enabled = true
		tl_mat.emission = Color(0.8, 0.0, 0.0)
		tl_mat.emission_energy_multiplier = 0.4
		tlm.material = tl_mat
		tl.mesh = tlm
		tl.position = Vector3(side * 0.8, 0.55, -body_l / 2.0)
		add_child(tl)

	# Wheels (4)
	var wheel_positions = [
		Vector3(-1.1, 0.2, 1.3), Vector3(1.1, 0.2, 1.3),
		Vector3(-1.1, 0.2, -1.3), Vector3(1.1, 0.2, -1.3),
	]
	for wp in wheel_positions:
		var wheel = MeshInstance3D.new()
		var whl = CylinderMesh.new()
		whl.top_radius = 0.3
		whl.bottom_radius = 0.3
		whl.height = 0.18
		whl.material = _make_mat(Color(0.12, 0.12, 0.12))
		wheel.mesh = whl
		wheel.position = wp
		wheel.rotation.z = PI / 2
		add_child(wheel)
		wheel_nodes.append(wheel)

		# Wheel hub
		var hub = MeshInstance3D.new()
		var hubm = CylinderMesh.new()
		hubm.top_radius = 0.15
		hubm.bottom_radius = 0.15
		hubm.height = 0.19
		hubm.material = _make_mat(Color(0.7, 0.7, 0.7))
		hub.mesh = hubm
		hub.position = wp
		hub.rotation.z = PI / 2
		add_child(hub)

	# Bumpers
	for z_off in [body_l / 2.0 + 0.05, -(body_l / 2.0 + 0.05)]:
		var bumper = MeshInstance3D.new()
		var bum = BoxMesh.new()
		bum.size = Vector3(body_w + 0.1, 0.15, 0.1)
		bum.material = _make_mat(Color(0.2, 0.2, 0.2))
		bumper.mesh = bum
		bumper.position = Vector3(0, 0.3, z_off)
		add_child(bumper)

func _physics_process(delta):
	if is_player_driving and player:
		handle_driving(delta)
		# Spin wheels
		for w in wheel_nodes:
			w.rotate(Vector3(0, 0, 1), current_speed * delta * 0.5)

func handle_driving(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left"):
		rotation.y += turn_speed * delta * (current_speed / max_speed)
	if Input.is_action_pressed("ui_right"):
		rotation.y -= turn_speed * delta * (current_speed / max_speed)

	if input_dir.z != 0:
		current_speed = move_toward(current_speed, input_dir.z * max_speed, acceleration)
	else:
		current_speed = move_toward(current_speed, 0, brake_force)

	var forward = -global_transform.basis.z
	position += forward * current_speed * delta

	if Input.is_action_just_pressed("interact"):
		exit_vehicle()

func player_entered(p: Node3D):
	player = p
	is_player_driving = true
	engine_running = true
	p.global_position = global_position + Vector3(0, 2, 0)
	p.is_in_vehicle = true
	if p.model_root:
		p.model_root.visible = false

func exit_vehicle():
	if player:
		player.is_in_vehicle = false
		player.current_vehicle = null
		player.global_position = global_position + Vector3(3, 1, 0)
		if player.model_root:
			player.model_root.visible = true
		is_player_driving = false
		engine_running = false
		player = null

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		queue_free()

func refuel():
	pass
