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
var entry_cooldown := 0.0  # Prevents instant exit after entering

func _ready():
	add_to_group("vehicle")
	print("[VEHICLE] %s added to 'vehicle' group at %s" % [name, global_position])
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

	# Side mirrors
	for side in [-1, 1]:
		var mirror = MeshInstance3D.new()
		var mm = BoxMesh.new()
		mm.size = Vector3(0.12, 0.08, 0.1)
		mm.material = _make_mat(car_color)
		mirror.mesh = mm
		mirror.position = Vector3(side * (body_w / 2.0 + 0.08), 1.0, 0.5)
		add_child(mirror)

	# Door handles
	for side in [-1, 1]:
		var handle = MeshInstance3D.new()
		var hm = BoxMesh.new()
		hm.size = Vector3(0.04, 0.03, 0.15)
		hm.material = _make_mat(Color(0.7, 0.7, 0.7))
		handle.mesh = hm
		handle.position = Vector3(side * (body_w / 2.0 + 0.02), 0.75, 0.3)
		add_child(handle)

	# License plate (rear)
	var plate = MeshInstance3D.new()
	var plm = BoxMesh.new()
	plm.size = Vector3(0.5, 0.15, 0.02)
	var plate_mat = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.95, 0.95, 0.9)
	plate_mat.roughness = 0.5
	plm.material = plate_mat
	plate.mesh = plm
	plate.position = Vector3(0, 0.35, -(body_l / 2.0 + 0.03))
	add_child(plate)

	# Side windows (glass panels)
	for side in [-1, 1]:
		var swin = MeshInstance3D.new()
		var swm = BoxMesh.new()
		swm.size = Vector3(0.04, 0.4, body_l * 0.35)
		var sglass = StandardMaterial3D.new()
		sglass.albedo_color = Color(0.5, 0.65, 0.85, 0.35)
		sglass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sglass.roughness = 0.1
		swm.material = sglass
		swin.mesh = swm
		swin.position = Vector3(side * (body_w / 2.0 - 0.08), 1.15, -0.1)
		add_child(swin)

func _physics_process(delta):
	if entry_cooldown > 0:
		entry_cooldown -= delta
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
		rotation.y += turn_speed * delta * clamp(abs(current_speed) / max_speed, 0.15, 1.0)
	if Input.is_action_pressed("ui_right"):
		rotation.y -= turn_speed * delta * clamp(abs(current_speed) / max_speed, 0.15, 1.0)

	if input_dir.z != 0:
		current_speed = move_toward(current_speed, input_dir.z * max_speed, acceleration)
	else:
		current_speed = move_toward(current_speed, 0, brake_force)

	var forward = -global_transform.basis.z
	position += forward * current_speed * delta

	# Engine sound pitch based on speed
	var eng = get_node_or_null("EngineLoop")
	if eng:
		eng.pitch_scale = 0.8 + abs(current_speed) / max_speed * 0.8

	if Input.is_action_just_pressed("interact") and entry_cooldown <= 0:
		exit_vehicle()

func player_entered(p: Node3D):
	print("[VEHICLE] player_entered() called by %s" % p.name)
	player = p
	is_player_driving = true
	engine_running = true
	entry_cooldown = 0.5  # Prevent instant exit
	p.global_position = global_position + Vector3(0, 1.5, 0)
	p.is_in_vehicle = true
	if p.model_root:
		p.model_root.visible = false
	# Start engine sound
	var eng = AudioStreamPlayer.new()
	eng.name = "EngineLoop"
	eng.bus = "Master"
	eng.volume_db = -14.0
	eng.stream = SFX.generate_engine_loop()
	add_child(eng)
	eng.play()
	# Start radio on first station
	if Radio:
		Radio.cycle_station()
	print("[VEHICLE] Player now driving %s" % name)

func exit_vehicle():
	if player:
		player.is_in_vehicle = false
		player.current_vehicle = null
		var exit_dir = global_transform.basis.x.normalized()
		player.global_position = global_position + exit_dir * 3.0 + Vector3(0, 1, 0)
		if player.model_root:
			player.model_root.visible = true
		is_player_driving = false
		engine_running = false
		player = null
		current_speed = 0.0
		# Stop engine sound
		var eng = get_node_or_null("EngineLoop")
		if eng:
			eng.stop()
			eng.queue_free()
		# Stop radio
		if Radio:
			Radio.stop()
			Globals.current_radio_station = "OFF"

func take_damage(amount: int):
	health -= amount
	# Tint body to show damage
	_apply_damage_tint()
	if health <= 0:
		_explode()
		queue_free()

func _apply_damage_tint():
	var hp_ratio = clamp(float(health) / 200.0, 0.0, 1.0)
	for child in get_children():
		if child is MeshInstance3D and child.mesh:
			var mat = child.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				# Shift toward red/dark as damage increases
				mat.albedo_color = mat.albedo_color.lerp(Color(0.3, 0.05, 0.05), 1.0 - hp_ratio)

func _explode():
	SFX.play_sfx("explosion")
	# Visual explosion: orange light + smoke
	var scene = get_tree().current_scene
	if not scene:
		return
	var flash = OmniLight3D.new()
	flash.omni_range = 12.0
	flash.light_energy = 8.0
	flash.light_color = Color(1.0, 0.5, 0.1)
	scene.add_child(flash)
	flash.global_position = global_position + Vector3(0, 1, 0)
	get_tree().create_timer(0.15).timeout.connect(flash.queue_free)
	# Smoke column
	var smoke = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 1.5
	cyl.height = 5.0
	var sm_mat = StandardMaterial3D.new()
	sm_mat.albedo_color = Color(0.15, 0.15, 0.15, 0.7)
	sm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl.material = sm_mat
	smoke.mesh = cyl
	scene.add_child(smoke)
	smoke.global_position = global_position + Vector3(0, 2.5, 0)
	get_tree().create_timer(3.0).timeout.connect(smoke.queue_free)

func refuel():
	pass
