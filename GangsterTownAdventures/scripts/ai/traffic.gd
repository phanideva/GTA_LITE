extends RigidBody3D
# Traffic AI — NPC cars that drive along LA city roads
# Features: obstacle avoidance via raycast, pedestrian collision, engine sounds

@export var speed = 12.0
@export var max_speed = 25.0
var road_axis = "ns"

var current_speed = 0.0
var direction = Vector3.ZERO
var waypoint_index = 0
var waypoints: Array = []
var stopping = false
var stop_timer = 0.0
var is_player_driving = false
var player: Node3D = null
var turn_speed = 3.0
var entry_cooldown := 0.0
var wheel_nodes: Array = []
var engine_player: AudioStreamPlayer3D
var ped_hit_cooldown = 0.0
var horn_timer = 0.0
var stuck_timer = 0.0
var last_pos = Vector3.ZERO

func _ready():
	add_to_group("traffic")
	print("[TRAFFIC] %s spawned at %s" % [name, global_position])
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	freeze = true
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_car_model()
	_add_npc_driver()
	_setup_engine_sound()
	speed = randf_range(8.0, 18.0)
	generate_road_path()
	global_position.y = 0.1
	last_pos = global_position

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
	var types = [
		{"w": 1.8, "h": 0.45, "l": 4.2, "ch": 0.48, "cl": 2.1, "wr": 0.28, "rh": 0.50},
		{"w": 1.95, "h": 0.55, "l": 4.6, "ch": 0.60, "cl": 2.5, "wr": 0.34, "rh": 0.65},
		{"w": 1.7, "h": 0.35, "l": 4.0, "ch": 0.38, "cl": 1.6, "wr": 0.26, "rh": 0.38},
		{"w": 1.9, "h": 0.48, "l": 4.8, "ch": 0.55, "cl": 2.0, "wr": 0.30, "rh": 0.48},
	]
	var t = types[randi() % types.size()]
	var bw = t["w"]; var bh = t["h"]; var bl = t["l"]
	var ch = t["ch"]; var cl = t["cl"]
	var wr = t["wr"]; var rh = t["rh"]
	var body_y = rh + bh / 2.0
	var cabin_y = rh + bh + ch / 2.0

	var body_mat = _make_mat(car_color)
	var dark_mat = _make_mat(car_color.darkened(0.15))
	var trim_mat = _make_mat(Color(0.12, 0.12, 0.12))
	var chrome_mat = StandardMaterial3D.new()
	chrome_mat.albedo_color = Color(0.8, 0.8, 0.82)
	chrome_mat.roughness = 0.1
	chrome_mat.metallic = 0.9
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.5, 0.65, 0.85, 0.45)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.05

	# Main body
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(bw - 0.15, bh, bl - 0.4)
	bm.material = body_mat
	body.mesh = bm
	body.position = Vector3(0, body_y, 0)
	add_child(body)

	# Tapered hood
	var hood = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(bw - 0.2, bh * 0.7, bl * 0.2)
	hm.material = body_mat
	hood.mesh = hm
	hood.position = Vector3(0, body_y + 0.04, bl * 0.38)
	hood.rotation.x = -0.12
	add_child(hood)

	# Rounded front
	var nose = MeshInstance3D.new()
	var nm = CylinderMesh.new()
	nm.top_radius = bh * 0.35
	nm.bottom_radius = bh * 0.35
	nm.height = bw - 0.25
	nm.material = body_mat
	nose.mesh = nm
	nose.position = Vector3(0, body_y - bh * 0.1, bl / 2.0 - 0.05)
	nose.rotation.z = PI / 2
	add_child(nose)

	# Trunk
	var trunk_mi = MeshInstance3D.new()
	var tkm = BoxMesh.new()
	tkm.size = Vector3(bw - 0.18, bh * 0.6, bl * 0.18)
	tkm.material = body_mat
	trunk_mi.mesh = tkm
	trunk_mi.position = Vector3(0, body_y + 0.03, -bl * 0.38)
	trunk_mi.rotation.x = 0.12
	add_child(trunk_mi)

	# Rear round
	var rr = MeshInstance3D.new()
	var rrm = CylinderMesh.new()
	rrm.top_radius = bh * 0.3
	rrm.bottom_radius = bh * 0.3
	rrm.height = bw - 0.25
	rrm.material = body_mat
	rr.mesh = rrm
	rr.position = Vector3(0, body_y - bh * 0.1, -bl / 2.0 + 0.05)
	rr.rotation.z = PI / 2
	add_child(rr)

	# Fender arches
	for fp in [
		Vector3(-bw / 2.0 + 0.05, rh + wr * 0.3, bl * 0.30),
		Vector3(bw / 2.0 - 0.05, rh + wr * 0.3, bl * 0.30),
		Vector3(-bw / 2.0 + 0.05, rh + wr * 0.3, -bl * 0.30),
		Vector3(bw / 2.0 - 0.05, rh + wr * 0.3, -bl * 0.30),
	]:
		var fender = MeshInstance3D.new()
		var fm = SphereMesh.new()
		fm.radius = wr + 0.06
		fm.height = wr * 1.0
		fm.material = body_mat
		fender.mesh = fm
		fender.position = fp
		add_child(fender)

	# Side panels + rocker
	for side in [-1, 1]:
		var sp = MeshInstance3D.new()
		var spm = BoxMesh.new()
		spm.size = Vector3(0.05, bh * 0.8, bl - 0.8)
		spm.material = body_mat
		sp.mesh = spm
		sp.position = Vector3(side * bw / 2.0, body_y, 0)
		add_child(sp)
		var rkr = MeshInstance3D.new()
		var rkm = BoxMesh.new()
		rkm.size = Vector3(0.04, 0.06, bl - 1.2)
		rkm.material = trim_mat
		rkr.mesh = rkm
		rkr.position = Vector3(side * (bw / 2.0 - 0.02), rh + 0.03, 0)
		add_child(rkr)

	# Cabin
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(bw - 0.25, ch * 0.85, cl)
	cm.material = dark_mat
	cabin.mesh = cm
	cabin.position = Vector3(0, cabin_y, -bl * 0.05)
	add_child(cabin)

	# Roof arc
	var roof = MeshInstance3D.new()
	var rfm = CylinderMesh.new()
	rfm.top_radius = (bw - 0.3) / 2.0 - 0.06
	rfm.bottom_radius = (bw - 0.3) / 2.0
	rfm.height = cl * 0.85
	rfm.material = body_mat
	roof.mesh = rfm
	roof.position = Vector3(0, cabin_y + ch * 0.42, -bl * 0.05)
	roof.rotation.x = PI / 2
	add_child(roof)

	# Windshield
	var windshield = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = Vector3(bw - 0.35, ch * 0.75, 0.04)
	wm.material = glass_mat
	windshield.mesh = wm
	windshield.position = Vector3(0, cabin_y + ch * 0.05, cl / 2.0 - 0.08)
	windshield.rotation.x = -0.30
	add_child(windshield)

	# Rear window
	var rear_w = MeshInstance3D.new()
	var rwm = BoxMesh.new()
	rwm.size = Vector3(bw - 0.35, ch * 0.65, 0.04)
	rwm.material = glass_mat
	rear_w.mesh = rwm
	rear_w.position = Vector3(0, cabin_y + ch * 0.05, -cl / 2.0 + 0.08)
	rear_w.rotation.x = 0.25
	add_child(rear_w)

	# Headlights
	for side in [-1, 1]:
		var hl = MeshInstance3D.new()
		var hlm = SphereMesh.new()
		hlm.radius = 0.06
		hlm.height = 0.07
		var hl_mat = StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 1.0, 0.95)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 0.98, 0.85)
		hl_mat.emission_energy_multiplier = 0.4
		hlm.material = hl_mat
		hl.mesh = hlm
		hl.position = Vector3(side * (bw / 2.0 - 0.22), body_y + bh * 0.1, bl / 2.0 + 0.04)
		add_child(hl)

	# Taillights
	for side in [-1, 1]:
		var tl = MeshInstance3D.new()
		var tlm = BoxMesh.new()
		tlm.size = Vector3(0.22, 0.08, 0.05)
		var tl_mat = StandardMaterial3D.new()
		tl_mat.albedo_color = Color(0.85, 0.05, 0.05)
		tl_mat.emission_enabled = true
		tl_mat.emission = Color(0.8, 0.0, 0.0)
		tl_mat.emission_energy_multiplier = 0.4
		tlm.material = tl_mat
		tl.mesh = tlm
		tl.position = Vector3(side * (bw / 2.0 - 0.2), body_y + bh * 0.05, -bl / 2.0 - 0.01)
		add_child(tl)

	# Grille
	var grille = MeshInstance3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(bw * 0.5, bh * 0.5, 0.04)
	gm.material = chrome_mat
	grille.mesh = gm
	grille.position = Vector3(0, body_y - bh * 0.15, bl / 2.0 + 0.02)
	add_child(grille)

	# Bumpers
	for z_side in [1, -1]:
		var bumper = MeshInstance3D.new()
		var bum = BoxMesh.new()
		bum.size = Vector3(bw + 0.02, 0.15, 0.10)
		bum.material = dark_mat
		bumper.mesh = bum
		bumper.position = Vector3(0, rh + 0.10, z_side * (bl / 2.0 + 0.05))
		add_child(bumper)

	# Wheels (torus tires + cylinder rims)
	for x in [-bw / 2.0 + 0.05, bw / 2.0 - 0.05]:
		for z in [-bl * 0.30, bl * 0.30]:
			var tire = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = wr * 0.55
			tm.outer_radius = wr
			tm.material = _make_mat(Color(0.08, 0.08, 0.08))
			tm.material.roughness = 0.95
			tire.mesh = tm
			tire.position = Vector3(x, wr, z)
			tire.rotation.z = PI / 2
			add_child(tire)
			wheel_nodes.append(tire)

			var rim = MeshInstance3D.new()
			var rmm = CylinderMesh.new()
			rmm.top_radius = wr * 0.5
			rmm.bottom_radius = wr * 0.5
			rmm.height = 0.05
			rmm.material = chrome_mat
			rim.mesh = rmm
			rim.position = Vector3(x, wr, z)
			rim.rotation.z = PI / 2
			add_child(rim)

func _add_npc_driver():
	var CharModel = load("res://scripts/utils/character_model.gd")
	var driver = Node3D.new()
	driver.name = "Driver"
	var model = Node3D.new()
	model.set_script(CharModel)
	# LA-style diverse driver appearance
	var skins = [Color(0.95, 0.82, 0.68), Color(0.87, 0.72, 0.55), Color(0.72, 0.55, 0.40), Color(0.55, 0.38, 0.26), Color(0.82, 0.68, 0.50)]
	var shirts = [Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.8), Color(0.3, 0.7, 0.3), Color(0.9, 0.9, 0.3), Color(0.5, 0.5, 0.5), Color(0.1, 0.1, 0.1), Color(0.9, 0.9, 0.9)]
	model.skin_color = skins[randi() % skins.size()]
	model.shirt_color = shirts[randi() % shirts.size()]
	model.pants_color = [Color(0.15, 0.15, 0.2), Color(0.2, 0.15, 0.1), Color(0.1, 0.1, 0.1), Color(0.25, 0.22, 0.2)][randi() % 4]
	model.shoe_color = Color(0.15, 0.1, 0.05)
	model.hair_color = [Color(0.1, 0.07, 0.03), Color(0.6, 0.4, 0.15), Color(0.2, 0.1, 0.05), Color(0.05, 0.03, 0.02)][randi() % 4]
	driver.add_child(model)
	model.build()
	driver.position = Vector3(-0.35, 0.75, 0.15)
	driver.scale = Vector3(0.42, 0.42, 0.42)
	add_child(driver)

func _setup_engine_sound():
	engine_player = AudioStreamPlayer3D.new()
	engine_player.unit_size = 12.0
	engine_player.max_distance = 60.0
	engine_player.volume_db = -14.0
	engine_player.pitch_scale = 0.6
	add_child(engine_player)
	# Generate Vice City style traffic engine — deep rumble with character
	var sr = 44100
	var count = sr  # 1 second loop
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
		# V6/V8 engine tone with exhaust resonance
		var v = sin(t_val * 38.0 * TAU) * 0.35
		v += sin(t_val * 76.0 * TAU) * 0.18
		v += sin(t_val * 19.0 * TAU) * 0.12
		v += sin(t_val * 152.0 * TAU) * 0.06
		# Light crackle texture
		var noise = (fmod(t_val * 9876.5, 1.0) - 0.5) * 0.05
		v += noise
		# Two-stage low-pass for warm muffled tone
		v = prev * 0.6 + v * 0.4
		prev = v
		v = prev2 * 0.5 + v * 0.5
		prev2 = v
		var sample = int(clamp(v * 20000.0, -32768, 32767))
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	audio.data = data
	engine_player.stream = audio
	engine_player.play()

func is_npc_driving() -> bool:
	return not is_player_driving

func _physics_process(delta):
	if entry_cooldown > 0:
		entry_cooldown -= delta
	ped_hit_cooldown = max(0.0, ped_hit_cooldown - delta)
	horn_timer = max(0.0, horn_timer - delta)

	if is_player_driving and player:
		_handle_player_driving(delta)
		_check_ped_collisions(true)
		_update_engine_sound()
		return

	if waypoints.is_empty():
		return

	# Intersection stopping (simulate traffic lights)
	if stopping:
		stop_timer -= delta
		current_speed = move_toward(current_speed, 0.0, 12.0 * delta)
		_update_engine_sound()
		_spin_wheels(delta)
		if stop_timer <= 0:
			stopping = false
		return

	var target_wp = waypoints[waypoint_index]
	var to_target = target_wp - global_position
	to_target.y = 0
	var dist_to_wp = to_target.length()

	if dist_to_wp < 3.0:
		waypoint_index = (waypoint_index + 1) % waypoints.size()
		# Stop at some intersections (traffic light simulation)
		if randf() < 0.18:
			stopping = true
			stop_timer = randf_range(2.5, 6.0)
		return

	direction = to_target.normalized()
	var desired_speed = speed

	# ── OBSTACLE AVOIDANCE via raycast ──
	var obstacle_dist = _raycast_ahead()
	if obstacle_dist > 0:
		if obstacle_dist < 15.0:
			desired_speed *= clamp((obstacle_dist - 3.0) / 12.0, 0.0, 1.0)
		if obstacle_dist < 5.0:
			desired_speed = 0.0
			# Try skipping waypoint to reroute
			stuck_timer += 0.016
			if stuck_timer > 2.0:
				_skip_to_clear_waypoint()
				stuck_timer = 0.0
	else:
		stuck_timer = 0.0

	# Also check side rays for tight spaces
	var left_clear = _raycast_side(-1)
	var right_clear = _raycast_side(1)
	if obstacle_dist > 0 and obstacle_dist < 10.0:
		# Steer toward clear side
		var steer = Vector3.ZERO
		if right_clear > left_clear:
			steer = global_transform.basis.x.normalized() * 0.4
		elif left_clear > right_clear:
			steer = -global_transform.basis.x.normalized() * 0.4
		direction = (direction + steer).normalized()

	# ── AVOID PLAYER ──
	if Globals.player:
		var dp = global_position.distance_to(Globals.player.global_position)
		if dp < 10.0:
			desired_speed *= clamp((dp - 3.0) / 7.0, 0.0, 1.0)
			if horn_timer <= 0 and dp < 6.0:
				SFX.play_sfx("car_horn", 0.15)
				horn_timer = 3.0
		if dp < 3.5:
			desired_speed = 0.0

	# ── AVOID OTHER TRAFFIC ──
	for other in get_tree().get_nodes_in_group("traffic"):
		if other == self or not is_instance_valid(other):
			continue
		var d = global_position.distance_to(other.global_position)
		if d < 7.0:
			desired_speed *= clamp((d - 2.5) / 4.5, 0.0, 1.0)
		if d < 3.0:
			desired_speed = 0.0

	# Avoid parked vehicles
	for other in get_tree().get_nodes_in_group("vehicle"):
		if other == self or not is_instance_valid(other):
			continue
		var d = global_position.distance_to(other.global_position)
		if d < 5.0:
			desired_speed *= 0.2

	# Smooth acceleration / deceleration
	var accel = 6.0 if desired_speed > current_speed else 10.0
	current_speed = move_toward(current_speed, desired_speed, accel * delta)

	# Move vehicle
	position += direction * current_speed * delta
	position.y = 0.1

	# Face movement direction smoothly
	if direction.length() > 0.01:
		var target_rot = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 4.0 * delta)

	_spin_wheels(delta)
	_check_ped_collisions(false)
	_update_engine_sound()

	# Stuck detection (hasn't moved much in a while)
	if global_position.distance_to(last_pos) < 0.1:
		stuck_timer += delta
		if stuck_timer > 4.0:
			_skip_to_clear_waypoint()
			stuck_timer = 0.0
	else:
		stuck_timer = max(0.0, stuck_timer - delta)
	last_pos = global_position

func _spin_wheels(delta):
	var wheel_spin = current_speed * delta * 2.0
	for w in wheel_nodes:
		if is_instance_valid(w):
			w.rotate_object_local(Vector3(0, 1, 0), wheel_spin)

# ══════════════════════ OBSTACLE DETECTION ══════════════════════

func _raycast_ahead() -> float:
	# Cast a ray forward to detect buildings/walls
	var space = get_world_3d().direct_space_state
	if not space:
		return -1.0
	var from_pos = global_position + Vector3(0, 0.6, 0)
	var forward = direction if direction.length() > 0.01 else -global_transform.basis.z.normalized()
	var to_pos = from_pos + forward * 20.0
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1  # World/building layer only
	query.exclude = [get_rid()]
	var result = space.intersect_ray(query)
	if result:
		return from_pos.distance_to(result.position)
	return -1.0

func _raycast_side(side_dir: int) -> float:
	# Check clearance to left (-1) or right (+1)
	var space = get_world_3d().direct_space_state
	if not space:
		return 20.0
	var from_pos = global_position + Vector3(0, 0.6, 0)
	var side_vec = global_transform.basis.x.normalized() * float(side_dir)
	var forward = direction if direction.length() > 0.01 else -global_transform.basis.z.normalized()
	var to_pos = from_pos + (forward * 8.0 + side_vec * 5.0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result = space.intersect_ray(query)
	if result:
		return from_pos.distance_to(result.position)
	return 20.0

func _skip_to_clear_waypoint():
	# Skip ahead in waypoints to find a clear path
	for skip in range(1, mini(4, waypoints.size())):
		var idx = (waypoint_index + skip) % waypoints.size()
		var wp = waypoints[idx]
		var to_wp = (wp - global_position)
		to_wp.y = 0
		var test_dir = to_wp.normalized()
		# Quick raycast test
		var space = get_world_3d().direct_space_state
		if space:
			var from_pos = global_position + Vector3(0, 0.6, 0)
			var to_pos = from_pos + test_dir * min(to_wp.length(), 15.0)
			var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
			query.collision_mask = 1
			query.exclude = [get_rid()]
			var result = space.intersect_ray(query)
			if not result:
				waypoint_index = idx
				return
	# If all blocked, just advance
	waypoint_index = (waypoint_index + 2) % waypoints.size()

# ══════════════════════ PEDESTRIAN COLLISION ══════════════════════

func _check_ped_collisions(is_player: bool):
	if current_speed < 3.0 or ped_hit_cooldown > 0:
		return
	for npc in get_tree().get_nodes_in_group("npc"):
		if not is_instance_valid(npc):
			continue
		if npc.is_dead:
			continue
		var dist = global_position.distance_to(npc.global_position)
		if dist < 2.8:
			var damage = int(clamp(current_speed * 5.0, 15, 100))
			npc.take_damage(damage)
			ped_hit_cooldown = 0.3
			SFX.play_sfx("hit", 0.25)
			# Player driving increases wanted level
			if is_player:
				Globals.wanted_level = clamp(Globals.wanted_level + 1, 0, 6)
			break

# ══════════════════════ ENGINE SOUND ══════════════════════

func _update_engine_sound():
	if not engine_player:
		return
	var spd_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
	# Smooth pitch: idle at 0.6, max at 1.5
	engine_player.pitch_scale = 0.6 + spd_ratio * 0.9
	# Volume: audible at idle, loud at speed
	var target_vol = -14.0 + spd_ratio * 8.0
	engine_player.volume_db = clamp(target_vol, -16.0, -6.0)

# ══════════════════════ ROAD PATHFINDING ══════════════════════

func generate_road_path():
	# Generate waypoints that strictly follow road grid center lines
	# Roads are at multiples of 50m, US right-hand driving (offset +2.0 for lane position)
	waypoints.clear()
	var start = global_position

	# Snap to nearest road intersection
	var nearest_ns = round(start.x / 50.0) * 50.0
	var nearest_ew = round(start.z / 50.0) * 50.0

	# Right-hand lane offset (US driving - drive on the right)
	var lane = 2.0

	# Build a rectangular circuit following roads
	var path_points: Array = []
	var cx = nearest_ns
	var cz = nearest_ew

	# Random route: 2-4 blocks per side
	var route_blocks = randi_range(2, 4)
	var dirs = ["north", "east", "south", "west"]
	var start_dir = randi() % 4

	for step in range(4):
		var d = dirs[(start_dir + step) % 4]
		for blk in range(route_blocks):
			# Add intermediate waypoints along the road (every ~12.5m for smoother driving)
			for sub in range(4):
				var frac = (blk * 4.0 + sub + 1) / (route_blocks * 4.0) * 50.0
				match d:
					"north":
						path_points.append(Vector3(cx + lane, 0.15, cz - frac))
					"south":
						path_points.append(Vector3(cx - lane, 0.15, cz + frac))
					"east":
						path_points.append(Vector3(cx + frac, 0.15, cz + lane))
					"west":
						path_points.append(Vector3(cx - frac, 0.15, cz - lane))
		# Update position after completing this leg
		match d:
			"north": cz -= route_blocks * 50.0
			"south": cz += route_blocks * 50.0
			"east": cx += route_blocks * 50.0
			"west": cx -= route_blocks * 50.0

	if path_points.is_empty():
		for z in range(-3, 4):
			path_points.append(Vector3(nearest_ns + lane, 0.15, nearest_ew + z * 50.0))

	waypoints = path_points

# ══════════════════════ PLAYER VEHICLE CONTROL ══════════════════════

func player_entered(p: Node3D):
	print("[TRAFFIC] Carjacking!")
	player = p
	is_player_driving = true
	entry_cooldown = 0.5
	p.global_position = global_position + Vector3(0, 1.5, 0)
	p.is_in_vehicle = true
	if p.model_root:
		p.model_root.visible = false
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
		current_speed = move_toward(current_speed, accel_input * max_speed, 3.5)
	else:
		current_speed = move_toward(current_speed, 0, 4.0)

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
			var push = wall_back.normal * 8.0 * delta
			push.y = 0
			position += push
			current_speed = min(current_speed, 0.0)
		else:
			var slide = back - wall_back.normal * back.dot(wall_back.normal)
			slide.y = 0
			position += slide.normalized() * abs(current_speed) * delta * 0.5
			current_speed *= 0.85
	position.y = 0.1
	_spin_wheels(delta)

	if Input.is_action_just_pressed("interact") and entry_cooldown <= 0:
		exit_vehicle()

func _raycast_ahead_dir(dir: Vector3) -> float:
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
