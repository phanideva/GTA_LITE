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
var engine_player: AudioStreamPlayer3D

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
	# Snap to road surface — road top is ~Y=0.1, wheel radius is 0.3
	# So vehicle origin should be at Y=0.1 so wheels sit on road
	global_position.y = 0.1

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
		Color(0.5, 0.0, 0.5), Color(0.8, 0.4, 0.1), Color(0.0, 0.0, 0.0),
		Color(0.35, 0.35, 0.4), Color(0.6, 0.55, 0.45), Color(0.15, 0.15, 0.6),
	]
	var car_color = colors[randi() % colors.size()]

	# Pick random type if not set
	var types = ["sedan", "suv", "sports", "pickup", "van", "muscle"]
	if vehicle_type == "sedan":
		vehicle_type = types[randi() % types.size()]

	var body_w: float
	var body_h: float
	var body_l: float
	var cabin_h: float
	var cabin_l_ratio: float
	var wheel_r: float
	var ride_height: float

	match vehicle_type:
		"sedan":
			body_w = 1.8; body_h = 0.65; body_l = 4.5
			cabin_h = 0.50; cabin_l_ratio = 0.5; wheel_r = 0.30; ride_height = 0.50
		"suv":
			body_w = 2.0; body_h = 0.85; body_l = 4.8
			cabin_h = 0.65; cabin_l_ratio = 0.55; wheel_r = 0.36; ride_height = 0.70
		"sports":
			body_w = 1.85; body_h = 0.50; body_l = 4.4
			cabin_h = 0.38; cabin_l_ratio = 0.4; wheel_r = 0.28; ride_height = 0.38
		"pickup":
			body_w = 1.95; body_h = 0.80; body_l = 5.2
			cabin_h = 0.60; cabin_l_ratio = 0.35; wheel_r = 0.35; ride_height = 0.65
		"van":
			body_w = 2.05; body_h = 1.05; body_l = 5.4
			cabin_h = 0.85; cabin_l_ratio = 0.7; wheel_r = 0.32; ride_height = 0.55
		"muscle":
			body_w = 1.90; body_h = 0.60; body_l = 4.8
			cabin_h = 0.48; cabin_l_ratio = 0.4; wheel_r = 0.32; ride_height = 0.48
		_:
			body_w = 1.8; body_h = 0.65; body_l = 4.5
			cabin_h = 0.50; cabin_l_ratio = 0.5; wheel_r = 0.30; ride_height = 0.50

	# Lower body (main chassis)
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(body_w, body_h, body_l)
	bm.material = _make_mat(car_color)
	body.mesh = bm
	body.position = Vector3(0, ride_height, 0)
	add_child(body)

	# Cabin / upper body
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(body_w - 0.2, cabin_h, body_l * cabin_l_ratio)
	cm.material = _make_mat(car_color.darkened(0.1))
	cabin.mesh = cm
	cabin.position = Vector3(0, ride_height + body_h / 2 + cabin_h / 2, -0.2)
	add_child(cabin)

	# Windshield (front)
	var windshield = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = Vector3(body_w - 0.3, cabin_h - 0.05, 0.05)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.6, 0.75, 0.9, 0.5)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.3
	wm.material = glass_mat
	windshield.mesh = wm
	windshield.position = Vector3(0, ride_height + body_h / 2 + cabin_h / 2 - 0.05, body_l * cabin_l_ratio / 2 - 0.35)
	windshield.rotation.x = -0.25
	add_child(windshield)

	# Rear window
	var rear_w = MeshInstance3D.new()
	rear_w.mesh = wm
	rear_w.position = Vector3(0, ride_height + body_h / 2 + cabin_h / 2 - 0.05, -body_l * cabin_l_ratio / 2 - 0.1)
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
		hl.position = Vector3(side * 0.7, ride_height - 0.05, body_l / 2.0)
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
		tl.position = Vector3(side * 0.8, ride_height - 0.05, -body_l / 2.0)
		add_child(tl)

	# Wheels (4)
	var wx_offset = body_w / 2.0 + 0.05
	var wz_front = body_l * 0.3
	var wz_rear = -body_l * 0.3
	var wheel_positions = [
		Vector3(-wx_offset, wheel_r, wz_front), Vector3(wx_offset, wheel_r, wz_front),
		Vector3(-wx_offset, wheel_r, wz_rear), Vector3(wx_offset, wheel_r, wz_rear),
	]
	for wp in wheel_positions:
		var wheel = MeshInstance3D.new()
		var whl = CylinderMesh.new()
		whl.top_radius = wheel_r
		whl.bottom_radius = wheel_r
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
		hubm.top_radius = wheel_r * 0.55
		hubm.bottom_radius = wheel_r * 0.55
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
		mirror.position = Vector3(side * (body_w / 2.0 + 0.08), ride_height + body_h / 2, 0.5)
		add_child(mirror)

	# Door handles
	for side in [-1, 1]:
		var handle = MeshInstance3D.new()
		var hm = BoxMesh.new()
		hm.size = Vector3(0.04, 0.03, 0.15)
		hm.material = _make_mat(Color(0.7, 0.7, 0.7))
		handle.mesh = hm
		handle.position = Vector3(side * (body_w / 2.0 + 0.02), ride_height, 0.3)
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
	plate.position = Vector3(0, ride_height - 0.15, -(body_l / 2.0 + 0.03))
	add_child(plate)

	# Side windows (glass panels)
	for side in [-1, 1]:
		var swin = MeshInstance3D.new()
		var swm = BoxMesh.new()
		swm.size = Vector3(0.04, cabin_h - 0.1, body_l * cabin_l_ratio * 0.7)
		var sglass = StandardMaterial3D.new()
		sglass.albedo_color = Color(0.5, 0.65, 0.85, 0.35)
		sglass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sglass.roughness = 0.1
		swm.material = sglass
		swin.mesh = swm
		swin.position = Vector3(side * (body_w / 2.0 - 0.08), ride_height + body_h / 2 + cabin_h / 2, -0.1)
		add_child(swin)

	# Pickup truck bed
	if vehicle_type == "pickup":
		var bed = MeshInstance3D.new()
		var bdm = BoxMesh.new()
		bdm.size = Vector3(body_w - 0.1, 0.4, body_l * 0.35)
		bdm.material = _make_mat(car_color.darkened(0.15))
		bed.mesh = bdm
		bed.position = Vector3(0, ride_height + 0.2, -body_l * 0.3)
		add_child(bed)
		# Bed walls
		for side in [-1, 1]:
			var wall = MeshInstance3D.new()
			var wlm = BoxMesh.new()
			wlm.size = Vector3(0.06, 0.5, body_l * 0.35)
			wlm.material = _make_mat(car_color.darkened(0.1))
			wall.mesh = wlm
			wall.position = Vector3(side * body_w / 2.0, ride_height + 0.45, -body_l * 0.3)
			add_child(wall)

	# Spoiler for sports/muscle
	if vehicle_type in ["sports", "muscle"]:
		var spoiler = MeshInstance3D.new()
		var spm = BoxMesh.new()
		spm.size = Vector3(body_w * 0.8, 0.06, 0.3)
		spm.material = _make_mat(car_color.darkened(0.2))
		spoiler.mesh = spm
		spoiler.position = Vector3(0, ride_height + body_h / 2 + 0.2, -body_l / 2.0 + 0.2)
		add_child(spoiler)
		for side in [-1, 1]:
			var strut = MeshInstance3D.new()
			var stm = BoxMesh.new()
			stm.size = Vector3(0.05, 0.2, 0.05)
			stm.material = _make_mat(car_color.darkened(0.2))
			strut.mesh = stm
			strut.position = Vector3(side * body_w * 0.3, ride_height + body_h / 2 + 0.1, -body_l / 2.0 + 0.2)
			add_child(strut)

func _physics_process(delta):
	if entry_cooldown > 0:
		entry_cooldown -= delta
	if is_player_driving and player:
		handle_driving(delta)
		# Spin wheels around their local X axis (the axle after Z rotation)
		var wheel_spin = current_speed * delta * 2.0
		for w in wheel_nodes:
			w.rotate_object_local(Vector3(0, 1, 0), wheel_spin)
		# Update engine sound pitch based on speed — Vice City rev behavior
		if engine_player:
			var spd_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
			engine_player.pitch_scale = 0.6 + spd_ratio * 0.9
			engine_player.volume_db = clamp(-10.0 + spd_ratio * 6.0, -12.0, -4.0)
		# Check pedestrian collisions while player drives
		_check_ped_hits()

func _check_ped_hits():
	if abs(current_speed) < 3.0:
		return
	for npc in get_tree().get_nodes_in_group("npc"):
		if not is_instance_valid(npc) or npc.is_dead:
			continue
		var dist = global_position.distance_to(npc.global_position)
		if dist < 2.8:
			var damage = int(clamp(abs(current_speed) * 5.0, 15, 100))
			npc.take_damage(damage)
			Globals.wanted_level = clamp(Globals.wanted_level + 1, 0, 6)
			SFX.play_sfx("hit", 0.25)
			break

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

	# Raycast to prevent driving through buildings — slide along walls
	var forward = -global_transform.basis.z
	var wall_result = _raycast_wall(forward)
	if wall_result.dist > 0 and wall_result.dist < 5.0 and current_speed < 0:
		if wall_result.dist < 2.5:
			# Push away from wall
			var push = wall_result.normal * 8.0 * delta
			push.y = 0
			position += push
			current_speed = max(current_speed, 0.0)
		else:
			# Slide along wall instead of stopping
			var slide = forward - wall_result.normal * forward.dot(wall_result.normal)
			slide.y = 0
			position += slide.normalized() * abs(current_speed) * delta * 0.5
			current_speed *= 0.85
	else:
		position += forward * current_speed * delta
	var back = global_transform.basis.z
	var wall_back = _raycast_wall(back)
	if wall_back.dist > 0 and wall_back.dist < 5.0 and current_speed > 0:
		if wall_back.dist < 2.5:
			var push_b = wall_back.normal * 8.0 * delta
			push_b.y = 0
			position += push_b
			current_speed = min(current_speed, 0.0)
		else:
			var slide_b = back - wall_back.normal * back.dot(wall_back.normal)
			slide_b.y = 0
			position += slide_b.normalized() * abs(current_speed) * delta * 0.5
			current_speed *= 0.85
	# Keep on road surface
	position.y = max(position.y, 0.1)

	if Input.is_action_just_pressed("interact") and entry_cooldown <= 0:
		exit_vehicle()

func _raycast_forward(dir: Vector3) -> float:
	var r = _raycast_wall(dir)
	return r.dist

func _raycast_wall(dir: Vector3) -> Dictionary:
	var space = get_world_3d().direct_space_state
	if not space:
		return {"dist": -1.0, "normal": Vector3.ZERO}
	var from_pos = global_position + Vector3(0, 0.6, 0)
	var to_pos = from_pos + dir * 12.0
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result = space.intersect_ray(query)
	if result:
		return {"dist": from_pos.distance_to(result.position), "normal": result.normal}
	return {"dist": -1.0, "normal": Vector3.ZERO}

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
	_start_engine_sound()
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
		_stop_engine_sound()

func _start_engine_sound():
	if engine_player:
		return
	engine_player = AudioStreamPlayer3D.new()
	engine_player.unit_size = 15.0
	engine_player.max_distance = 80.0
	engine_player.volume_db = -10.0
	engine_player.pitch_scale = 0.6
	add_child(engine_player)
	# Generate Vice City style engine sound — deep aggressive V8 rumble
	var sr = 44100
	var count = sr * 2  # 2 second loop for natural cycling
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sr
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_end = count
	var data = PackedByteArray()
	data.resize(count * 2)  # 16-bit = 2 bytes per sample
	var prev = 0.0
	var prev2 = 0.0
	for i in range(count):
		var t_val = float(i) / sr
		# V8 firing pattern: 4 cylinders per revolution at different phases
		var rpm_base = 35.0  # Idle RPM frequency in Hz
		var v = 0.0
		# Main firing frequency — deep bass thump
		v += sin(t_val * rpm_base * TAU) * 0.40
		# Second order (V8 has strong 2nd order)
		v += sin(t_val * rpm_base * 2.0 * TAU) * 0.25
		# Fourth order harmonic — gives that V8 burble
		v += sin(t_val * rpm_base * 4.0 * TAU + 0.3) * 0.12
		# Sub-bass rumble
		v += sin(t_val * rpm_base * 0.5 * TAU) * 0.15
		# Exhaust crackle — random noise mixed in lightly
		var noise = (fmod(t_val * 12345.6789, 1.0) - 0.5) * 0.08
		v += noise
		# Two-stage low-pass filter for warm, muffled exhaust tone
		v = prev * 0.6 + v * 0.4
		prev = v
		v = prev2 * 0.5 + v * 0.5
		prev2 = v
		# 16-bit output
		var sample = int(clamp(v * 24000.0, -32768, 32767))
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	audio.data = data
	engine_player.stream = audio
	engine_player.play()

func _stop_engine_sound():
	if engine_player:
		engine_player.stop()
		engine_player.queue_free()
		engine_player = null

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
