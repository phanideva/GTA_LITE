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

	var types = ["sedan", "suv", "sports", "pickup", "van", "muscle"]
	if vehicle_type == "sedan":
		vehicle_type = types[randi() % types.size()]

	# ═══ KENNEY GLB PATH ═══
	# If a Kenney Car Kit GLB is available, use the real model and skip procedural meshes.
	var kenney_filter := "sedan"
	match vehicle_type:
		"sedan": kenney_filter = "sedan"
		"sports": kenney_filter = "sports"
		"suv": kenney_filter = "suv"
		"pickup": kenney_filter = "truck"
		"van": kenney_filter = "van"
		"muscle": kenney_filter = "hatchback"
		_: kenney_filter = "sedan"
	var car_glb := AssetLoader.pick_random_filtered("vehicle", kenney_filter)
	if car_glb == null:
		car_glb = AssetLoader.pick_random_filtered("vehicle", "sedan")
	if car_glb != null:
		var inst = car_glb.instantiate()
		inst.scale = Vector3.ONE  # Kenney cars are ~1 m unit space; matches game scale
		inst.position = Vector3(0, 0, 0)
		# Kenney cars come with built-in vibrant colors — keep them as-is for visual variety.
		add_child(inst)
		return

	# --- Dimensions per vehicle type ---
	var bw: float; var bh: float; var bl: float
	var cabin_h: float; var cabin_l: float; var wheel_r: float; var ride_h: float
	var hood_slope: float; var trunk_slope: float; var roof_arc: float

	match vehicle_type:
		"sedan":
			bw = 1.8; bh = 0.45; bl = 4.5; cabin_h = 0.50; cabin_l = 2.2
			wheel_r = 0.30; ride_h = 0.50; hood_slope = 0.12; trunk_slope = 0.15; roof_arc = 0.08
		"suv":
			bw = 2.0; bh = 0.55; bl = 4.8; cabin_h = 0.70; cabin_l = 2.8
			wheel_r = 0.36; ride_h = 0.70; hood_slope = 0.08; trunk_slope = 0.06; roof_arc = 0.04
		"sports":
			bw = 1.85; bh = 0.35; bl = 4.4; cabin_h = 0.38; cabin_l = 1.8
			wheel_r = 0.28; ride_h = 0.38; hood_slope = 0.18; trunk_slope = 0.20; roof_arc = 0.12
		"pickup":
			bw = 1.95; bh = 0.50; bl = 5.2; cabin_h = 0.60; cabin_l = 1.8
			wheel_r = 0.35; ride_h = 0.65; hood_slope = 0.08; trunk_slope = 0.0; roof_arc = 0.04
		"van":
			bw = 2.05; bh = 0.50; bl = 5.4; cabin_h = 0.95; cabin_l = 3.8
			wheel_r = 0.32; ride_h = 0.55; hood_slope = 0.05; trunk_slope = 0.02; roof_arc = 0.03
		"muscle":
			bw = 1.90; bh = 0.42; bl = 4.8; cabin_h = 0.48; cabin_l = 2.0
			wheel_r = 0.32; ride_h = 0.48; hood_slope = 0.10; trunk_slope = 0.18; roof_arc = 0.10
		_:
			bw = 1.8; bh = 0.45; bl = 4.5; cabin_h = 0.50; cabin_l = 2.2
			wheel_r = 0.30; ride_h = 0.50; hood_slope = 0.12; trunk_slope = 0.15; roof_arc = 0.08

	var body_y = ride_h + bh / 2.0
	var cabin_y = ride_h + bh + cabin_h / 2.0
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
	glass_mat.metallic = 0.4

	# ═══ LOWER BODY (main chassis — rounded with fender flares) ═══
	# Main body slab
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(bw - 0.15, bh, bl - 0.4)
	bm.material = body_mat
	body.mesh = bm
	body.position = Vector3(0, body_y, 0)
	add_child(body)

	# Front end (tapered hood — narrower toward front)
	var hood = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(bw - 0.2, bh * 0.7, bl * 0.22)
	hm.material = body_mat
	hood.mesh = hm
	hood.position = Vector3(0, body_y + hood_slope * 0.3, bl * 0.38)
	hood.rotation.x = -hood_slope
	add_child(hood)

	# Hood nose (rounded front)
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

	# Rear end (trunk deck — sloped)
	var trunk = MeshInstance3D.new()
	var tkm = BoxMesh.new()
	tkm.size = Vector3(bw - 0.18, bh * 0.6, bl * 0.18)
	tkm.material = body_mat
	trunk.mesh = tkm
	trunk.position = Vector3(0, body_y + trunk_slope * 0.2, -bl * 0.38)
	trunk.rotation.x = trunk_slope
	add_child(trunk)

	# Rear rounded edge
	var rear_round = MeshInstance3D.new()
	var rrm = CylinderMesh.new()
	rrm.top_radius = bh * 0.3
	rrm.bottom_radius = bh * 0.3
	rrm.height = bw - 0.25
	rrm.material = body_mat
	rear_round.mesh = rrm
	rear_round.position = Vector3(0, body_y - bh * 0.1, -bl / 2.0 + 0.05)
	rear_round.rotation.z = PI / 2
	add_child(rear_round)

	# ═══ FENDER FLARES (wheel arches — quarter-sphere bulges) ═══
	var fender_positions = [
		Vector3(-bw / 2.0 + 0.05, ride_h + wheel_r * 0.3, bl * 0.30),
		Vector3(bw / 2.0 - 0.05, ride_h + wheel_r * 0.3, bl * 0.30),
		Vector3(-bw / 2.0 + 0.05, ride_h + wheel_r * 0.3, -bl * 0.30),
		Vector3(bw / 2.0 - 0.05, ride_h + wheel_r * 0.3, -bl * 0.30),
	]
	for fp in fender_positions:
		var fender = MeshInstance3D.new()
		var fm = SphereMesh.new()
		fm.radius = wheel_r + 0.08
		fm.height = wheel_r * 1.1
		fm.material = body_mat
		fender.mesh = fm
		fender.position = fp
		add_child(fender)

	# ═══ SIDE BODY SCULPTING (character line + rocker panel) ═══
	for side in [-1, 1]:
		# Upper body side panel (smooth)
		var side_panel = MeshInstance3D.new()
		var spm = BoxMesh.new()
		spm.size = Vector3(0.06, bh * 0.8, bl - 0.8)
		spm.material = body_mat
		side_panel.mesh = spm
		side_panel.position = Vector3(side * bw / 2.0, body_y, 0)
		add_child(side_panel)

		# Character line (thin raised strip along side)
		var char_line = MeshInstance3D.new()
		var clm = BoxMesh.new()
		clm.size = Vector3(0.02, 0.04, bl - 1.0)
		clm.material = dark_mat
		char_line.mesh = clm
		char_line.position = Vector3(side * (bw / 2.0 + 0.02), body_y + bh * 0.15, 0)
		add_child(char_line)

		# Rocker panel (bottom trim)
		var rocker = MeshInstance3D.new()
		var rkm = BoxMesh.new()
		rkm.size = Vector3(0.05, 0.08, bl - 1.2)
		rkm.material = trim_mat
		rocker.mesh = rkm
		rocker.position = Vector3(side * (bw / 2.0 - 0.02), ride_h + 0.04, 0)
		add_child(rocker)

	# ═══ CABIN (curved roof with pillars) ═══
	# Main cabin box
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(bw - 0.25, cabin_h * 0.85, cabin_l)
	cm.material = dark_mat
	cabin.mesh = cm
	cabin.position = Vector3(0, cabin_y, -bl * 0.05)
	add_child(cabin)

	# Roof arc (CylinderMesh for rounded top)
	var roof = MeshInstance3D.new()
	var rfm = CylinderMesh.new()
	rfm.top_radius = (bw - 0.3) / 2.0 - roof_arc
	rfm.bottom_radius = (bw - 0.3) / 2.0
	rfm.height = cabin_l * 0.85
	rfm.material = body_mat
	roof.mesh = rfm
	roof.position = Vector3(0, cabin_y + cabin_h * 0.42, -bl * 0.05)
	roof.rotation.x = PI / 2
	add_child(roof)

	# ═══ A-PILLAR (windshield frame — angled) ═══
	for side in [-1, 1]:
		var pillar = MeshInstance3D.new()
		var pm = BoxMesh.new()
		pm.size = Vector3(0.04, cabin_h * 0.95, 0.04)
		pm.material = trim_mat
		pillar.mesh = pm
		pillar.position = Vector3(side * (bw / 2.0 - 0.18), cabin_y, cabin_l / 2.0 - 0.15)
		pillar.rotation.z = side * 0.08
		pillar.rotation.x = -0.15
		add_child(pillar)

	# ═══ WINDSHIELD (angled, wider) ═══
	var windshield = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = Vector3(bw - 0.35, cabin_h * 0.75, 0.04)
	wm.material = glass_mat
	windshield.mesh = wm
	windshield.position = Vector3(0, cabin_y + cabin_h * 0.05, cabin_l / 2.0 - 0.08)
	windshield.rotation.x = -0.35
	add_child(windshield)

	# Rear window (angled opposite)
	var rear_w = MeshInstance3D.new()
	var rwm = BoxMesh.new()
	rwm.size = Vector3(bw - 0.35, cabin_h * 0.65, 0.04)
	rwm.material = glass_mat
	rear_w.mesh = rwm
	rear_w.position = Vector3(0, cabin_y + cabin_h * 0.05, -cabin_l / 2.0 + 0.08)
	rear_w.rotation.x = 0.30
	add_child(rear_w)

	# Side windows
	for side in [-1, 1]:
		var swin = MeshInstance3D.new()
		var swm = BoxMesh.new()
		swm.size = Vector3(0.03, cabin_h * 0.60, cabin_l * 0.65)
		swm.material = glass_mat
		swin.mesh = swm
		swin.position = Vector3(side * (bw / 2.0 - 0.14), cabin_y + cabin_h * 0.08, -bl * 0.05)
		add_child(swin)

	# ═══ HEADLIGHTS (modern shaped — wider, integrated) ═══
	for side in [-1, 1]:
		# Main headlight housing
		var hl_housing = MeshInstance3D.new()
		var hlhm = BoxMesh.new()
		hlhm.size = Vector3(0.28, 0.12, 0.10)
		hlhm.material = StandardMaterial3D.new()
		hlhm.material.albedo_color = Color(0.85, 0.88, 0.92, 0.7)
		hlhm.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hlhm.material.roughness = 0.05
		hl_housing.mesh = hlhm
		hl_housing.position = Vector3(side * (bw / 2.0 - 0.25), body_y + bh * 0.1, bl / 2.0 + 0.02)
		add_child(hl_housing)
		# Bulb
		var hl = MeshInstance3D.new()
		var hlm = SphereMesh.new()
		hlm.radius = 0.06
		hlm.height = 0.08
		var hl_mat = StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 1.0, 0.95)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 0.98, 0.85)
		hl_mat.emission_energy_multiplier = 0.6
		hlm.material = hl_mat
		hl.mesh = hlm
		hl.position = Vector3(side * (bw / 2.0 - 0.25), body_y + bh * 0.1, bl / 2.0 + 0.05)
		add_child(hl)

	# ═══ TAILLIGHTS (modern wrap-around) ═══
	for side in [-1, 1]:
		var tl = MeshInstance3D.new()
		var tlm = BoxMesh.new()
		tlm.size = Vector3(0.25, 0.10, 0.06)
		var tl_mat = StandardMaterial3D.new()
		tl_mat.albedo_color = Color(0.9, 0.05, 0.05)
		tl_mat.emission_enabled = true
		tl_mat.emission = Color(0.85, 0.0, 0.0)
		tl_mat.emission_energy_multiplier = 0.5
		tlm.material = tl_mat
		tl.mesh = tlm
		tl.position = Vector3(side * (bw / 2.0 - 0.22), body_y + bh * 0.05, -bl / 2.0 - 0.01)
		add_child(tl)

	# ═══ GRILLE (front — chrome or dark mesh) ═══
	var grille = MeshInstance3D.new()
	var gm = BoxMesh.new()
	gm.size = Vector3(bw * 0.55, bh * 0.55, 0.04)
	gm.material = chrome_mat if vehicle_type in ["sedan", "suv", "muscle"] else trim_mat
	grille.mesh = gm
	grille.position = Vector3(0, body_y - bh * 0.15, bl / 2.0 + 0.03)
	add_child(grille)

	# ═══ BUMPERS (integrated, body-colored with chrome strip) ═══
	for z_side in [1, -1]:
		var bumper = MeshInstance3D.new()
		var bum = BoxMesh.new()
		bum.size = Vector3(bw + 0.04, 0.18, 0.12)
		bum.material = dark_mat
		bumper.mesh = bum
		bumper.position = Vector3(0, ride_h + 0.12, z_side * (bl / 2.0 + 0.06))
		add_child(bumper)
		# Chrome accent strip on bumper
		var bstrip = MeshInstance3D.new()
		var bsm = BoxMesh.new()
		bsm.size = Vector3(bw * 0.7, 0.025, 0.02)
		bsm.material = chrome_mat
		bstrip.mesh = bsm
		bstrip.position = Vector3(0, ride_h + 0.15, z_side * (bl / 2.0 + 0.12))
		add_child(bstrip)

	# ═══ WHEELS (detailed — tire + rim + spokes + brake disc) ═══
	var wx_offset = bw / 2.0 + 0.05
	var wz_front = bl * 0.30
	var wz_rear = -bl * 0.30
	var wheel_positions = [
		Vector3(-wx_offset, wheel_r, wz_front), Vector3(wx_offset, wheel_r, wz_front),
		Vector3(-wx_offset, wheel_r, wz_rear), Vector3(wx_offset, wheel_r, wz_rear),
	]
	for wp in wheel_positions:
		# Tire (torus for sidewall + cylinder for tread)
		var tire = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = wheel_r * 0.55
		tm.outer_radius = wheel_r
		tm.material = _make_mat(Color(0.08, 0.08, 0.08))
		tm.material.roughness = 0.95
		tire.mesh = tm
		tire.position = wp
		tire.rotation.z = PI / 2
		add_child(tire)
		wheel_nodes.append(tire)

		# Rim (shiny metallic disc)
		var rim = MeshInstance3D.new()
		var rmm = CylinderMesh.new()
		rmm.top_radius = wheel_r * 0.55
		rmm.bottom_radius = wheel_r * 0.55
		rmm.height = 0.06
		rmm.material = chrome_mat
		rim.mesh = rmm
		rim.position = wp
		rim.rotation.z = PI / 2
		add_child(rim)

		# Spoke pattern (5 spokes)
		for spoke_i in range(5):
			var spoke = MeshInstance3D.new()
			var skm = BoxMesh.new()
			skm.size = Vector3(wheel_r * 0.4, 0.02, 0.025)
			skm.material = chrome_mat
			spoke.mesh = skm
			spoke.position = wp
			spoke.rotation.z = PI / 2
			spoke.rotation.y = spoke_i * TAU / 5.0
			add_child(spoke)

		# Brake disc (dark behind rim)
		var brake = MeshInstance3D.new()
		var bkm = CylinderMesh.new()
		bkm.top_radius = wheel_r * 0.42
		bkm.bottom_radius = wheel_r * 0.42
		bkm.height = 0.03
		bkm.material = _make_mat(Color(0.3, 0.28, 0.25))
		bkm.material.roughness = 0.6
		bkm.material.metallic = 0.7
		brake.mesh = bkm
		brake.position = wp + Vector3(sign(wp.x) * 0.04, 0, 0)
		brake.rotation.z = PI / 2
		add_child(brake)

	# ═══ SIDE MIRRORS (aerodynamic teardrop shape) ═══
	for side in [-1, 1]:
		var mirror_arm = MeshInstance3D.new()
		var mam = BoxMesh.new()
		mam.size = Vector3(0.12, 0.03, 0.06)
		mam.material = body_mat
		mirror_arm.mesh = mam
		mirror_arm.position = Vector3(side * (bw / 2.0 + 0.06), cabin_y - cabin_h * 0.2, cabin_l * 0.3)
		add_child(mirror_arm)

		var mirror_head = MeshInstance3D.new()
		var mhm = SphereMesh.new()
		mhm.radius = 0.05
		mhm.height = 0.04
		mhm.material = body_mat
		mirror_head.mesh = mhm
		mirror_head.position = Vector3(side * (bw / 2.0 + 0.12), cabin_y - cabin_h * 0.2, cabin_l * 0.3)
		add_child(mirror_head)

	# ═══ DOOR HANDLES (recessed, chrome) ═══
	for side in [-1, 1]:
		for door_z in [0.3, -0.3]:
			var handle = MeshInstance3D.new()
			var dhm = BoxMesh.new()
			dhm.size = Vector3(0.02, 0.025, 0.12)
			dhm.material = chrome_mat
			handle.mesh = dhm
			handle.position = Vector3(side * (bw / 2.0 + 0.01), body_y + bh * 0.2, door_z)
			add_child(handle)

	# ═══ LICENSE PLATE ═══
	var plate = MeshInstance3D.new()
	var plm = BoxMesh.new()
	plm.size = Vector3(0.45, 0.12, 0.015)
	var plate_mat = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.95, 0.95, 0.88)
	plate_mat.roughness = 0.5
	plm.material = plate_mat
	plate.mesh = plm
	plate.position = Vector3(0, ride_h + 0.18, -(bl / 2.0 + 0.08))
	add_child(plate)

	# ═══ EXHAUST PIPES ═══
	var exhaust_count = 2 if vehicle_type in ["sports", "muscle"] else 1
	for ei in range(exhaust_count):
		var exhaust = MeshInstance3D.new()
		var exm = CylinderMesh.new()
		exm.top_radius = 0.03
		exm.bottom_radius = 0.035
		exm.height = 0.12
		exm.material = chrome_mat
		exhaust.mesh = exm
		var ex_x = 0.0 if exhaust_count == 1 else (-0.25 + ei * 0.5)
		exhaust.position = Vector3(ex_x, ride_h + 0.06, -bl / 2.0 - 0.08)
		exhaust.rotation.x = PI / 2
		add_child(exhaust)

	# ═══ TYPE-SPECIFIC DETAILS ═══
	match vehicle_type:
		"pickup":
			# Truck bed (separated from cabin)
			var bed = MeshInstance3D.new()
			var bdm = BoxMesh.new()
			bdm.size = Vector3(bw - 0.12, 0.35, bl * 0.35)
			bdm.material = dark_mat
			bed.mesh = bdm
			bed.position = Vector3(0, ride_h + bh + 0.18, -bl * 0.28)
			add_child(bed)
			# Bed side walls
			for side in [-1, 1]:
				var wall = MeshInstance3D.new()
				var wlm = BoxMesh.new()
				wlm.size = Vector3(0.05, 0.50, bl * 0.35)
				wlm.material = body_mat
				wall.mesh = wlm
				wall.position = Vector3(side * (bw / 2.0 - 0.06), ride_h + bh + 0.35, -bl * 0.28)
				add_child(wall)
			# Tailgate
			var tailgate = MeshInstance3D.new()
			var tgm = BoxMesh.new()
			tgm.size = Vector3(bw - 0.12, 0.50, 0.05)
			tgm.material = body_mat
			tailgate.mesh = tgm
			tailgate.position = Vector3(0, ride_h + bh + 0.35, -bl * 0.45)
			add_child(tailgate)

		"sports", "muscle":
			# Rear spoiler (elevated on struts)
			var spoiler = MeshInstance3D.new()
			var spm = BoxMesh.new()
			spm.size = Vector3(bw * 0.75, 0.04, 0.22)
			spm.material = dark_mat
			spoiler.mesh = spm
			spoiler.position = Vector3(0, cabin_y + cabin_h * 0.5 + 0.08, -cabin_l / 2.0 - 0.3)
			add_child(spoiler)
			for side in [-1, 1]:
				var strut = MeshInstance3D.new()
				var stm = CylinderMesh.new()
				stm.top_radius = 0.018
				stm.bottom_radius = 0.022
				stm.height = 0.20
				stm.material = trim_mat
				strut.mesh = stm
				strut.position = Vector3(side * bw * 0.28, cabin_y + cabin_h * 0.4, -cabin_l / 2.0 - 0.3)
				add_child(strut)

		"muscle":
			# Hood scoop
			var scoop = MeshInstance3D.new()
			var scm = BoxMesh.new()
			scm.size = Vector3(0.30, 0.10, 0.45)
			scm.material = trim_mat
			scoop.mesh = scm
			scoop.position = Vector3(0, body_y + bh / 2.0 + 0.05, bl * 0.2)
			add_child(scoop)
			# Scoop opening
			var scoop_open = MeshInstance3D.new()
			var som = BoxMesh.new()
			som.size = Vector3(0.22, 0.06, 0.10)
			som.material = _make_mat(Color(0.05, 0.05, 0.05))
			scoop_open.mesh = som
			scoop_open.position = Vector3(0, body_y + bh / 2.0 + 0.10, bl * 0.30)
			add_child(scoop_open)

		"suv":
			# Roof rack bars
			for z_off in [-0.4, 0.4]:
				var rack = MeshInstance3D.new()
				var rkm = CylinderMesh.new()
				rkm.top_radius = 0.015
				rkm.bottom_radius = 0.015
				rkm.height = bw - 0.4
				rkm.material = chrome_mat
				rack.mesh = rkm
				rack.position = Vector3(0, cabin_y + cabin_h * 0.5 + 0.06, z_off)
				rack.rotation.z = PI / 2
				add_child(rack)
			# Cross bars
			for side in [-1, 1]:
				var xbar = MeshInstance3D.new()
				var xbm = CylinderMesh.new()
				xbm.top_radius = 0.012
				xbm.bottom_radius = 0.012
				xbm.height = 0.85
				xbm.material = chrome_mat
				xbar.mesh = xbm
				xbar.position = Vector3(side * (bw / 2.0 - 0.25), cabin_y + cabin_h * 0.5 + 0.04, 0)
				xbar.rotation.x = PI / 2
				add_child(xbar)

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
