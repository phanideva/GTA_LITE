extends RigidBody3D
# Motorcycle / Bicycle — rideable 2-wheeled vehicle

@export var max_speed = 60.0
@export var acceleration = 3.0
@export var brake_force = 4.0
@export var turn_speed = 4.0
@export var is_bicycle: bool = false

var current_speed = 0.0
var is_player_driving = false
var player: Node3D = null
var health = 100

func _ready():
	add_to_group("vehicle")
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	freeze = true
	# Remove old meshes
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	if is_bicycle:
		max_speed = 25.0
		acceleration = 1.5
		_build_bicycle()
	else:
		_build_motorcycle()

func _make_mat(color: Color, metallic: float = 0.4) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mat.metallic = metallic
	return mat

func _build_motorcycle():
	var frame_color = [Color(0.8, 0.1, 0.1), Color(0.1, 0.1, 0.1), Color(0.0, 0.2, 0.7), Color(0.9, 0.7, 0.0)][randi() % 4]

	# Frame / body
	var frame = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(0.4, 0.35, 1.6)
	fm.material = _make_mat(frame_color, 0.6)
	frame.mesh = fm
	frame.position = Vector3(0, 0.65, 0)
	add_child(frame)

	# Gas tank
	var tank = MeshInstance3D.new()
	var tm = SphereMesh.new()
	tm.radius = 0.2
	tm.height = 0.35
	tm.material = _make_mat(frame_color)
	tank.mesh = tm
	tank.position = Vector3(0, 0.85, 0.15)
	add_child(tank)

	# Seat
	var seat = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.3, 0.08, 0.5)
	sm.material = _make_mat(Color(0.12, 0.1, 0.08))
	seat.mesh = sm
	seat.position = Vector3(0, 0.88, -0.25)
	add_child(seat)

	# Handlebars
	var hbar = MeshInstance3D.new()
	var hm = CylinderMesh.new()
	hm.top_radius = 0.02
	hm.bottom_radius = 0.02
	hm.height = 0.6
	hm.material = _make_mat(Color(0.7, 0.7, 0.7), 0.8)
	hbar.mesh = hm
	hbar.position = Vector3(0, 1.0, 0.65)
	hbar.rotation.z = PI / 2
	add_child(hbar)

	# Headlight
	var hl = MeshInstance3D.new()
	var hlm = SphereMesh.new()
	hlm.radius = 0.08
	var hl_mat = _make_mat(Color(1.0, 1.0, 0.9))
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(1.0, 1.0, 0.8)
	hl_mat.emission_energy_multiplier = 0.5
	hlm.material = hl_mat
	hl.mesh = hlm
	hl.position = Vector3(0, 0.85, 0.82)
	add_child(hl)

	# Wheels (2)
	for z_off in [0.65, -0.65]:
		var wheel = MeshInstance3D.new()
		var wm = CylinderMesh.new()
		wm.top_radius = 0.28
		wm.bottom_radius = 0.28
		wm.height = 0.1
		wm.material = _make_mat(Color(0.1, 0.1, 0.1))
		wheel.mesh = wm
		wheel.position = Vector3(0, 0.28, z_off)
		wheel.rotation.z = PI / 2
		add_child(wheel)

	# Exhaust pipe
	var exhaust = MeshInstance3D.new()
	var em = CylinderMesh.new()
	em.top_radius = 0.035
	em.bottom_radius = 0.04
	em.height = 0.8
	em.material = _make_mat(Color(0.5, 0.5, 0.5), 0.8)
	exhaust.mesh = em
	exhaust.position = Vector3(0.2, 0.45, -0.4)
	exhaust.rotation.x = PI / 2
	add_child(exhaust)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 0.9, 1.8)
	col.shape = shape
	col.position = Vector3(0, 0.55, 0)
	add_child(col)

func _build_bicycle():
	var frame_color = [Color(0.1, 0.5, 0.8), Color(0.8, 0.2, 0.1), Color(0.1, 0.7, 0.2), Color(0.9, 0.9, 0.1)][randi() % 4]

	# Frame (triangular-ish using tubes)
	var main_tube = MeshInstance3D.new()
	var mtm = CylinderMesh.new()
	mtm.top_radius = 0.02
	mtm.bottom_radius = 0.02
	mtm.height = 1.0
	mtm.material = _make_mat(frame_color, 0.3)
	main_tube.mesh = mtm
	main_tube.position = Vector3(0, 0.55, 0)
	main_tube.rotation.x = 0.3
	add_child(main_tube)

	# Seat
	var seat = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.15, 0.04, 0.2)
	sm.material = _make_mat(Color(0.1, 0.08, 0.05))
	seat.mesh = sm
	seat.position = Vector3(0, 0.9, -0.15)
	add_child(seat)

	# Handlebars
	var hbar = MeshInstance3D.new()
	var hm = CylinderMesh.new()
	hm.top_radius = 0.015
	hm.bottom_radius = 0.015
	hm.height = 0.4
	hm.material = _make_mat(Color(0.6, 0.6, 0.6), 0.7)
	hbar.mesh = hm
	hbar.position = Vector3(0, 0.85, 0.4)
	hbar.rotation.z = PI / 2
	add_child(hbar)

	# Wheels (2)
	for z_off in [0.45, -0.45]:
		var wheel = MeshInstance3D.new()
		var wm = CylinderMesh.new()
		wm.top_radius = 0.25
		wm.bottom_radius = 0.25
		wm.height = 0.05
		wm.material = _make_mat(Color(0.1, 0.1, 0.1))
		wheel.mesh = wm
		wheel.position = Vector3(0, 0.25, z_off)
		wheel.rotation.z = PI / 2
		add_child(wheel)

	# Pedals
	for side in [-1, 1]:
		var pedal = MeshInstance3D.new()
		var pm = BoxMesh.new()
		pm.size = Vector3(0.06, 0.02, 0.1)
		pm.material = _make_mat(Color(0.3, 0.3, 0.3))
		pedal.mesh = pm
		pedal.position = Vector3(side * 0.15, 0.35, 0)
		add_child(pedal)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.8, 1.2)
	col.shape = shape
	col.position = Vector3(0, 0.5, 0)
	add_child(col)

func _physics_process(delta):
	if is_player_driving and player:
		handle_driving(delta)

func handle_driving(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left"):
		rotation.y += turn_speed * delta * clamp(abs(current_speed) / 10.0, 0.3, 1.0)
	if Input.is_action_pressed("ui_right"):
		rotation.y -= turn_speed * delta * clamp(abs(current_speed) / 10.0, 0.3, 1.0)

	if input_dir.z != 0:
		current_speed = move_toward(current_speed, input_dir.z * max_speed, acceleration)
	else:
		current_speed = move_toward(current_speed, 0, brake_force)

	# Lean into turns
	var lean = 0.0
	if Input.is_action_pressed("ui_left"): lean = 0.15
	if Input.is_action_pressed("ui_right"): lean = -0.15
	rotation.z = move_toward(rotation.z, lean, delta * 3.0)

	var forward = -global_transform.basis.z
	position += forward * current_speed * delta

	if Input.is_action_just_pressed("interact"):
		exit_vehicle()

func player_entered(p: Node3D):
	player = p
	is_player_driving = true
	p.global_position = global_position + Vector3(0, 1.2, 0)
	p.is_in_vehicle = true
	if p.model_root:
		p.model_root.visible = false

func exit_vehicle():
	if player:
		player.is_in_vehicle = false
		player.current_vehicle = null
		player.global_position = global_position + Vector3(2, 1, 0)
		if player.model_root:
			player.model_root.visible = true
		is_player_driving = false
		player = null
		rotation.z = 0  # Reset lean

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		queue_free()
