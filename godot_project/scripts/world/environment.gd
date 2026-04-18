extends Node3D
# World/Environment — GTA city with buildings, shops, trees, parks, etc.

var sun: DirectionalLight3D
var time_of_day = 8.0
var day_speed = 0.5
var streetlights: Array = []

func _ready():
	add_to_group("world_environment")
	create_terrain()
	create_roads()
	create_buildings()
	create_shops()
	create_trees()
	create_park()
	create_streetlights()
	create_benches()
	create_fences()
	create_dumpsters()
	create_fire_hydrants()
	create_traffic_cones()
	create_bus_stops()
	create_sidewalks()
	setup_lighting()
	setup_sky()

func _process(delta):
	time_of_day += delta * day_speed
	if time_of_day >= 24.0:
		time_of_day -= 24.0
	update_sun()
	update_streetlights()

func _make_mat(color: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	return mat

# ═══════════════════════ TERRAIN ═══════════════════════
func create_terrain():
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)

	# Main ground (grass)
	var gm = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(500, 500)
	gm.mesh = plane
	gm.set_surface_override_material(0, _make_mat(Color(0.2, 0.5, 0.2)))
	ground.add_child(gm)

	var col = CollisionShape3D.new()
	col.shape = WorldBoundaryShape3D.new()
	ground.add_child(col)

# ═══════════════════════ ROADS ═══════════════════════
func create_roads():
	# Main streets (wider)
	_add_road(Vector3(0, 0.02, 0), Vector3(5, 0.15, 500))    # Main N-S
	_add_road(Vector3(0, 0.02, 0), Vector3(500, 0.15, 5))    # Main E-W

	# City grid
	for i in range(-5, 6):
		if i == 0: continue
		_add_road(Vector3(i * 22, 0.02, 0), Vector3(3.5, 0.12, 500))
		_add_road(Vector3(0, 0.02, i * 22), Vector3(500, 0.12, 3.5))

	# Road markings (center lines)
	for i in range(-5, 6):
		for j in range(-10, 11):
			_add_road_marking(Vector3(i * 22, 0.16, j * 8), true)
			_add_road_marking(Vector3(j * 8, 0.16, i * 22), false)

func _add_road(pos: Vector3, size: Vector3):
	var road = StaticBody3D.new()
	road.position = pos
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, _make_mat(Color(0.2, 0.2, 0.22)))
	road.add_child(mi)
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	road.add_child(cs)
	add_child(road)

func _add_road_marking(pos: Vector3, is_ns: bool):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.15, 0.01, 2.0) if is_ns else Vector3(2.0, 0.01, 0.15)
	bm.material = _make_mat(Color(0.95, 0.9, 0.3))
	mi.mesh = bm
	mi.position = pos
	add_child(mi)

# ═══════════════════════ BUILDINGS ═══════════════════════
func create_buildings():
	var building_data = [
		# Downtown high-rises
		[Vector3(33, 0, 33),   Vector3(14, 35, 14), Color(0.55, 0.58, 0.65)],
		[Vector3(-33, 0, 33),  Vector3(12, 28, 12), Color(0.65, 0.6, 0.55)],
		[Vector3(33, 0, -33),  Vector3(16, 42, 12), Color(0.5, 0.55, 0.6)],
		[Vector3(-33, 0, -33), Vector3(14, 32, 14), Color(0.72, 0.68, 0.6)],
		# Mid city
		[Vector3(55, 0, 11),   Vector3(12, 20, 10), Color(0.7, 0.65, 0.58)],
		[Vector3(-55, 0, -11), Vector3(14, 24, 12), Color(0.58, 0.62, 0.68)],
		[Vector3(11, 0, 55),   Vector3(14, 22, 16), Color(0.6, 0.63, 0.7)],
		[Vector3(-11, 0, -55), Vector3(12, 38, 12), Color(0.68, 0.6, 0.55)],
		# Outer city
		[Vector3(66, 0, -55),  Vector3(18, 16, 18), Color(0.7, 0.7, 0.65)],
		[Vector3(-66, 0, 55),  Vector3(14, 26, 12), Color(0.6, 0.65, 0.7)],
		[Vector3(88, 0, 0),    Vector3(12, 20, 14), Color(0.55, 0.6, 0.68)],
		[Vector3(-88, 0, 0),   Vector3(16, 18, 12), Color(0.68, 0.62, 0.6)],
		[Vector3(44, 0, 66),   Vector3(10, 14, 10), Color(0.72, 0.7, 0.65)],
		[Vector3(-44, 0, -66), Vector3(12, 22, 14), Color(0.6, 0.65, 0.7)],
		[Vector3(77, 0, 44),   Vector3(14, 12, 14), Color(0.65, 0.62, 0.6)],
		[Vector3(-77, 0, -44), Vector3(12, 30, 10), Color(0.58, 0.6, 0.65)],
	]
	for d in building_data:
		_add_building(d[0], d[1], d[2])

func _add_building(pos: Vector3, size: Vector3, color: Color):
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, size.y / 2.0, 0)

	# Main structure
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, _make_mat(color, 0.7, 0.1))
	body.add_child(mi)

	# Windows (rows of small dark rectangles on facade)
	var floors = int(size.y / 3.0)
	for floor_i in range(1, floors):
		for side in range(4):
			var window = MeshInstance3D.new()
			var wm = BoxMesh.new()
			var win_mat = StandardMaterial3D.new()
			win_mat.albedo_color = Color(0.3, 0.4, 0.55, 0.8)
			win_mat.roughness = 0.1
			win_mat.metallic = 0.3
			if side < 2:
				wm.size = Vector3(size.x * 0.7, 1.2, 0.05)
				var z_off = (size.z / 2.0 + 0.03) * (1 if side == 0 else -1)
				window.position = Vector3(0, -size.y / 2.0 + floor_i * 3.0, z_off)
			else:
				wm.size = Vector3(0.05, 1.2, size.z * 0.7)
				var x_off = (size.x / 2.0 + 0.03) * (1 if side == 2 else -1)
				window.position = Vector3(x_off, -size.y / 2.0 + floor_i * 3.0, 0)
			wm.material = win_mat
			window.mesh = wm
			body.add_child(window)

	# Roof detail
	var roof = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(size.x + 0.5, 0.3, size.z + 0.5)
	rm.material = _make_mat(color.darkened(0.2), 0.9)
	roof.mesh = rm
	roof.position = Vector3(0, size.y / 2.0 + 0.15, 0)
	body.add_child(roof)

	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)

	add_child(body)

# ═══════════════════════ SHOPS ═══════════════════════
func create_shops():
	var shops = [
		["AMMU-NATION", Vector3(12, 0, 8), Color(0.7, 0.15, 0.15), Color(0.9, 0.2, 0.2)],
		["PAY'N'SPRAY", Vector3(-12, 0, 8), Color(0.15, 0.5, 0.7), Color(0.2, 0.6, 0.9)],
		["BURGER SHOT", Vector3(12, 0, -8), Color(0.8, 0.5, 0.1), Color(0.9, 0.6, 0.1)],
		["CLUCKIN BELL", Vector3(-12, 0, -8), Color(0.7, 0.2, 0.1), Color(0.9, 0.3, 0.1)],
		["24/7 STORE", Vector3(55, 0, 33), Color(0.15, 0.5, 0.15), Color(0.2, 0.8, 0.2)],
		["BINCO", Vector3(-55, 0, 33), Color(0.3, 0.3, 0.7), Color(0.4, 0.4, 0.9)],
		["GAS STATION", Vector3(55, 0, -33), Color(0.6, 0.6, 0.6), Color(0.8, 0.15, 0.15)],
		["HOSPITAL", Vector3(-55, 0, -33), Color(0.9, 0.9, 0.9), Color(0.9, 0.2, 0.2)],
	]
	for s in shops:
		_add_shop(s[0], s[1], s[2], s[3])

func _add_shop(shop_name: String, pos: Vector3, wall_color: Color, sign_color: Color):
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, 2.5, 0)

	# Shop building
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(8, 5, 6)
	mi.mesh = bm
	mi.set_surface_override_material(0, _make_mat(wall_color, 0.6))
	body.add_child(mi)

	# Door (dark opening)
	var door = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(1.2, 2.5, 0.05)
	dm.material = _make_mat(Color(0.08, 0.06, 0.04))
	door.mesh = dm
	door.position = Vector3(0, -1.0, 3.03)
	body.add_child(door)

	# Awning
	var awning = MeshInstance3D.new()
	var am = BoxMesh.new()
	am.size = Vector3(8.5, 0.15, 1.5)
	am.material = _make_mat(sign_color)
	awning.mesh = am
	awning.position = Vector3(0, 1.5, 3.5)
	body.add_child(awning)

	# Sign (glowing text panel)
	var sign_panel = MeshInstance3D.new()
	var spm = BoxMesh.new()
	spm.size = Vector3(6, 1.0, 0.1)
	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = sign_color
	sign_mat.emission_enabled = true
	sign_mat.emission = sign_color
	sign_mat.emission_energy_multiplier = 0.6
	spm.material = sign_mat
	sign_panel.mesh = spm
	sign_panel.position = Vector3(0, 2.8, 3.05)
	body.add_child(sign_panel)

	# Shop window (glass front)
	for side in [-1, 1]:
		var win = MeshInstance3D.new()
		var wm = BoxMesh.new()
		wm.size = Vector3(2.5, 2.0, 0.05)
		var gmat = StandardMaterial3D.new()
		gmat.albedo_color = Color(0.5, 0.65, 0.8, 0.4)
		gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gmat.roughness = 0.1
		wm.material = gmat
		win.mesh = wm
		win.position = Vector3(side * 2.5, -0.5, 3.03)
		body.add_child(win)

	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(8, 5, 6)
	cs.shape = bs
	body.add_child(cs)

	add_child(body)

# ═══════════════════════ TREES ═══════════════════════
func create_trees():
	for i in range(50):
		var x = randf_range(-180, 180)
		var z = randf_range(-180, 180)
		# Skip roads and buildings
		if abs(fmod(x, 22.0)) < 3.0 or abs(fmod(z, 22.0)) < 3.0:
			continue
		if abs(x) < 15 and abs(z) < 15:
			continue
		_add_tree(Vector3(x, 0, z))

func _add_tree(pos: Vector3):
	var tree = Node3D.new()
	tree.position = pos

	var trunk_h = randf_range(2.5, 5.0)
	var canopy_r = randf_range(1.5, 3.5)

	# Trunk (brown cylinder)
	var trunk = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.15
	tm.bottom_radius = 0.25
	tm.height = trunk_h
	tm.material = _make_mat(Color(0.35, 0.22, 0.1))
	trunk.mesh = tm
	trunk.position.y = trunk_h / 2.0
	tree.add_child(trunk)

	# Canopy (green sphere)
	var canopy = MeshInstance3D.new()
	var cm = SphereMesh.new()
	cm.radius = canopy_r
	cm.height = canopy_r * 1.6
	var leaf_green = Color(
		randf_range(0.1, 0.25),
		randf_range(0.45, 0.7),
		randf_range(0.08, 0.2)
	)
	cm.material = _make_mat(leaf_green)
	canopy.mesh = cm
	canopy.position.y = trunk_h + canopy_r * 0.5
	tree.add_child(canopy)

	# Some trees get a second canopy layer
	if randf() > 0.5:
		var c2 = MeshInstance3D.new()
		var c2m = SphereMesh.new()
		c2m.radius = canopy_r * 0.7
		c2m.height = canopy_r * 1.0
		c2m.material = _make_mat(leaf_green.lightened(0.1))
		c2.mesh = c2m
		c2.position.y = trunk_h + canopy_r * 1.1
		c2.position.x = randf_range(-0.5, 0.5)
		tree.add_child(c2)

	add_child(tree)

# ═══════════════════════ PARK ═══════════════════════
func create_park():
	# Central park area with grass, flowers, fountain
	var park_pos = Vector3(0, 0.01, 0)

	# Park ground (darker green)
	var pg = MeshInstance3D.new()
	var pgm = BoxMesh.new()
	pgm.size = Vector3(14, 0.05, 14)
	pgm.material = _make_mat(Color(0.15, 0.55, 0.15))
	pg.mesh = pgm
	pg.position = park_pos + Vector3(0, 0.03, 0)
	add_child(pg)

	# Fountain base
	var fb = MeshInstance3D.new()
	var fbm = CylinderMesh.new()
	fbm.top_radius = 2.0
	fbm.bottom_radius = 2.2
	fbm.height = 0.6
	fbm.material = _make_mat(Color(0.6, 0.6, 0.65), 0.5, 0.2)
	fb.mesh = fbm
	fb.position = park_pos + Vector3(0, 0.3, 0)
	add_child(fb)

	# Water surface
	var water = MeshInstance3D.new()
	var wm = CylinderMesh.new()
	wm.top_radius = 1.8
	wm.bottom_radius = 1.8
	wm.height = 0.05
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.2, 0.4, 0.8, 0.7)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.05
	wm.material = water_mat
	water.mesh = wm
	water.position = park_pos + Vector3(0, 0.55, 0)
	add_child(water)

	# Fountain pillar
	var fp = MeshInstance3D.new()
	var fpm = CylinderMesh.new()
	fpm.top_radius = 0.15
	fpm.bottom_radius = 0.2
	fpm.height = 1.5
	fpm.material = _make_mat(Color(0.65, 0.65, 0.7), 0.4, 0.3)
	fp.mesh = fpm
	fp.position = park_pos + Vector3(0, 1.0, 0)
	add_child(fp)

	# Flower patches
	var flower_colors = [Color(0.9, 0.2, 0.2), Color(0.9, 0.8, 0.1), Color(0.8, 0.2, 0.8), Color(0.95, 0.5, 0.1)]
	for i in range(12):
		var flower = MeshInstance3D.new()
		var flm = SphereMesh.new()
		flm.radius = 0.15
		flm.height = 0.2
		flm.material = _make_mat(flower_colors[i % flower_colors.size()])
		flower.mesh = flm
		var angle = i * (TAU / 12.0)
		flower.position = park_pos + Vector3(cos(angle) * 5.5, 0.15, sin(angle) * 5.5)
		add_child(flower)

# ═══════════════════════ STREETLIGHTS ═══════════════════════
func create_streetlights():
	var light_positions = []
	# Along every road intersection
	for i in range(-4, 5):
		for j in range(-4, 5):
			if (i + j) % 2 == 0:
				light_positions.append(Vector3(i * 22 + 2.5, 0, j * 22 + 2.5))

	for lp in light_positions:
		# Pole
		var pole = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 7.0
		pm.top_radius = 0.06
		pm.bottom_radius = 0.1
		pm.material = _make_mat(Color(0.35, 0.35, 0.35), 0.5, 0.6)
		pole.mesh = pm
		pole.position = lp + Vector3(0, 3.5, 0)
		add_child(pole)

		# Lamp housing
		var lamp = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.5, 0.15, 0.25)
		lm.material = _make_mat(Color(0.3, 0.3, 0.3), 0.5, 0.5)
		lamp.mesh = lm
		lamp.position = lp + Vector3(0, 7.1, 0)
		add_child(lamp)

		# Light bulb (visible glow)
		var bulb = MeshInstance3D.new()
		var bm = SphereMesh.new()
		bm.radius = 0.12
		var bulb_mat = StandardMaterial3D.new()
		bulb_mat.albedo_color = Color(1.0, 0.95, 0.8)
		bulb_mat.emission_enabled = true
		bulb_mat.emission = Color(1.0, 0.9, 0.7)
		bulb_mat.emission_energy_multiplier = 0.3
		bm.material = bulb_mat
		bulb.mesh = bm
		bulb.position = lp + Vector3(0, 7.0, 0)
		add_child(bulb)

		# OmniLight
		var omni = OmniLight3D.new()
		omni.position = lp + Vector3(0, 7.0, 0)
		omni.omni_range = 18.0
		omni.light_energy = 0.0
		omni.light_color = Color(1.0, 0.9, 0.7)
		add_child(omni)
		streetlights.append(omni)

# ═══════════════════════ BENCHES ═══════════════════════
func create_benches():
	var bench_positions = [
		Vector3(6, 0, 3), Vector3(-6, 0, 3), Vector3(6, 0, -3), Vector3(-6, 0, -3),
		Vector3(22, 0, 10), Vector3(-22, 0, -10), Vector3(44, 0, 22), Vector3(-44, 0, -22),
	]
	for bp in bench_positions:
		_add_bench(bp)

func _add_bench(pos: Vector3):
	var bench = Node3D.new()
	bench.position = pos

	# Seat
	var seat = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(1.2, 0.08, 0.4)
	sm.material = _make_mat(Color(0.45, 0.28, 0.12))
	seat.mesh = sm
	seat.position.y = 0.45
	bench.add_child(seat)

	# Backrest
	var back = MeshInstance3D.new()
	var bkm = BoxMesh.new()
	bkm.size = Vector3(1.2, 0.5, 0.06)
	bkm.material = _make_mat(Color(0.45, 0.28, 0.12))
	back.mesh = bkm
	back.position = Vector3(0, 0.7, -0.17)
	bench.add_child(back)

	# Legs
	for side in [-1, 1]:
		var leg = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.06, 0.45, 0.4)
		lm.material = _make_mat(Color(0.25, 0.25, 0.25), 0.5, 0.5)
		leg.mesh = lm
		leg.position = Vector3(side * 0.5, 0.22, 0)
		bench.add_child(leg)

	add_child(bench)

# ═══════════════════════ FENCES ═══════════════════════
func create_fences():
	# Fences around the park
	for side in range(4):
		var fence = MeshInstance3D.new()
		var fm = BoxMesh.new()
		var fence_mat = _make_mat(Color(0.3, 0.3, 0.3), 0.6, 0.4)
		match side:
			0: fm.size = Vector3(14, 0.8, 0.06); fence.position = Vector3(0, 0.4, 7)
			1: fm.size = Vector3(14, 0.8, 0.06); fence.position = Vector3(0, 0.4, -7)
			2: fm.size = Vector3(0.06, 0.8, 14); fence.position = Vector3(7, 0.4, 0)
			3: fm.size = Vector3(0.06, 0.8, 14); fence.position = Vector3(-7, 0.4, 0)
		fm.material = fence_mat
		fence.mesh = fm
		add_child(fence)

# ═══════════════════════ DUMPSTERS ═══════════════════════
func create_dumpsters():
	var positions = [
		Vector3(35, 0, 28), Vector3(-35, 0, 28), Vector3(35, 0, -28),
		Vector3(-35, 0, -28), Vector3(60, 0, 15), Vector3(-60, 0, -15),
	]
	for pos in positions:
		var dump = MeshInstance3D.new()
		var dm = BoxMesh.new()
		dm.size = Vector3(1.5, 1.2, 1.0)
		dm.material = _make_mat(Color(0.15, 0.35, 0.15))
		dump.mesh = dm
		dump.position = pos + Vector3(0, 0.6, 0)
		add_child(dump)

		# Lid
		var lid = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(1.6, 0.08, 1.1)
		lm.material = _make_mat(Color(0.12, 0.3, 0.12))
		lid.mesh = lm
		lid.position = pos + Vector3(0, 1.24, 0)
		add_child(lid)

# ═══════════════════════ FIRE HYDRANTS ═══════════════════════
func create_fire_hydrants():
	var positions = [
		Vector3(8, 0, 4), Vector3(-8, 0, -4), Vector3(30, 0, 4),
		Vector3(-30, 0, -4), Vector3(52, 0, 4), Vector3(-52, 0, -4),
		Vector3(4, 0, 26), Vector3(-4, 0, -26), Vector3(4, 0, 48),
	]
	for pos in positions:
		var hydrant = Node3D.new()
		hydrant.position = pos
		# Body
		var body = MeshInstance3D.new()
		var bm = CylinderMesh.new()
		bm.top_radius = 0.12
		bm.bottom_radius = 0.15
		bm.height = 0.6
		bm.material = _make_mat(Color(0.85, 0.15, 0.1), 0.5, 0.3)
		body.mesh = bm
		body.position.y = 0.3
		hydrant.add_child(body)
		# Cap
		var cap = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.14
		cm.height = 0.1
		cm.material = _make_mat(Color(0.85, 0.15, 0.1), 0.5, 0.3)
		cap.mesh = cm
		cap.position.y = 0.65
		hydrant.add_child(cap)
		# Side nozzle
		var nozzle = MeshInstance3D.new()
		var nm = CylinderMesh.new()
		nm.top_radius = 0.04
		nm.bottom_radius = 0.04
		nm.height = 0.12
		nm.material = _make_mat(Color(0.7, 0.7, 0.1), 0.4, 0.5)
		nozzle.mesh = nm
		nozzle.position = Vector3(0.12, 0.4, 0)
		nozzle.rotation.z = PI / 2
		hydrant.add_child(nozzle)
		add_child(hydrant)

# ═══════════════════════ TRAFFIC CONES ═══════════════════════
func create_traffic_cones():
	# Place cones near construction areas
	var cone_groups = [
		Vector3(40, 0, 0), Vector3(-40, 0, 0), Vector3(0, 0, 44),
	]
	for base in cone_groups:
		for i in range(4):
			var cone = Node3D.new()
			cone.position = base + Vector3(i * 1.2, 0, 0)
			var body = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.15
			cm.height = 0.5
			cm.material = _make_mat(Color(1.0, 0.5, 0.0), 0.6)
			body.mesh = cm
			body.position.y = 0.25
			cone.add_child(body)
			# White stripe
			var stripe = MeshInstance3D.new()
			var sm = CylinderMesh.new()
			sm.top_radius = 0.06
			sm.bottom_radius = 0.09
			sm.height = 0.08
			sm.material = _make_mat(Color(0.95, 0.95, 0.95))
			stripe.mesh = sm
			stripe.position.y = 0.32
			cone.add_child(stripe)
			add_child(cone)

# ═══════════════════════ BUS STOPS ═══════════════════════
func create_bus_stops():
	var positions = [Vector3(22, 0, 6), Vector3(-22, 0, -6), Vector3(44, 0, 6)]
	for pos in positions:
		var stop = Node3D.new()
		stop.position = pos
		# Post
		var post = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.top_radius = 0.05
		pm.bottom_radius = 0.05
		pm.height = 3.0
		pm.material = _make_mat(Color(0.5, 0.5, 0.5), 0.4, 0.5)
		post.mesh = pm
		post.position.y = 1.5
		stop.add_child(post)
		# Sign
		var sign = MeshInstance3D.new()
		var sgn = BoxMesh.new()
		sgn.size = Vector3(0.6, 0.4, 0.04)
		var sign_mat = StandardMaterial3D.new()
		sign_mat.albedo_color = Color(0.1, 0.3, 0.7)
		sign_mat.emission_enabled = true
		sign_mat.emission = Color(0.1, 0.2, 0.5)
		sign_mat.emission_energy_multiplier = 0.2
		sgn.material = sign_mat
		sign.mesh = sgn
		sign.position = Vector3(0, 2.8, 0)
		stop.add_child(sign)
		# Shelter roof
		var roof = MeshInstance3D.new()
		var rm = BoxMesh.new()
		rm.size = Vector3(2.5, 0.08, 1.5)
		rm.material = _make_mat(Color(0.3, 0.3, 0.35), 0.5, 0.3)
		roof.mesh = rm
		roof.position = Vector3(0, 2.5, -0.5)
		stop.add_child(roof)
		# Bench
		var bench = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(2.0, 0.06, 0.35)
		bm.material = _make_mat(Color(0.4, 0.25, 0.12))
		bench.mesh = bm
		bench.position = Vector3(0, 0.5, -0.8)
		stop.add_child(bench)
		add_child(stop)

# ═══════════════════════ SIDEWALKS ═══════════════════════
func create_sidewalks():
	# Raised sidewalk curbs along roads
	for i in range(-5, 6):
		for is_ns in [true, false]:
			# Sidewalk on each side of the road
			for side in [-1, 1]:
				var sw = MeshInstance3D.new()
				var swm = BoxMesh.new()
				if is_ns:
					swm.size = Vector3(1.2, 0.12, 500)
					sw.position = Vector3(i * 22 + side * 3.2, 0.06, 0)
				else:
					swm.size = Vector3(500, 0.12, 1.2)
					sw.position = Vector3(0, 0.06, i * 22 + side * 3.2)
				swm.material = _make_mat(Color(0.55, 0.55, 0.5), 0.9)
				sw.mesh = swm
				add_child(sw)

# ═══════════════════════ LIGHTING ═══════════════════════
func setup_lighting():
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 200.0
	sun.light_color = Color(1.0, 0.95, 0.85)
	add_child(sun)

func setup_sky():
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var proc_sky = ProceduralSkyMaterial.new()
	proc_sky.sky_top_color = Color(0.15, 0.35, 0.75)
	proc_sky.sky_horizon_color = Color(0.55, 0.7, 0.95)
	proc_sky.ground_bottom_color = Color(0.18, 0.45, 0.18)
	proc_sky.ground_horizon_color = Color(0.55, 0.65, 0.55)
	proc_sky.sun_angle_max = 40.0
	proc_sky.sun_curve = 0.1
	sky.sky_material = proc_sky
	env.sky = sky

	# Ambient lighting from sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.ambient_light_sky_contribution = 1.0

	# Tone mapping for cinematic look
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1

	# Glow/bloom for neon signs and lights
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Fog for depth/atmosphere
	env.fog_enabled = true
	env.fog_light_color = Color(0.65, 0.72, 0.85)
	env.fog_density = 0.0008
	env.fog_aerial_perspective = 0.5

	# SSAO for depth in shadows
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.5

	we.environment = env
	add_child(we)

func update_sun():
	var angle = (time_of_day - 6.0) / 12.0 * PI
	sun.rotation = Vector3(-angle + PI / 2.0, 0.3, 0)
	var t = clamp((time_of_day - 5.0) / 14.0, 0.0, 1.0)
	sun.light_energy = lerp(0.0, 1.4, sin(t * PI))

func update_streetlights():
	var is_night = time_of_day < 6.5 or time_of_day > 19.5
	for light in streetlights:
		light.light_energy = 1.5 if is_night else 0.0
