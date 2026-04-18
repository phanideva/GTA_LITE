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
	create_road_curbs()
	create_traffic_lights()
	create_lane_markings()
	create_crosswalks()
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
	create_districts()
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

	# Main ground (grass with better material)
	var gm = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(500, 500)
	gm.mesh = plane
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.22, 0.48, 0.18)
	grass_mat.roughness = 0.95
	grass_mat.metallic = 0.0
	grass_mat.normal_enabled = false
	gm.set_surface_override_material(0, grass_mat)
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

func create_road_curbs():
	# Raised curbs along road edges for more realistic look
	var curb_mat = _make_mat(Color(0.6, 0.6, 0.58), 0.85)
	for i in range(-5, 6):
		# N-S roads: curbs on both sides
		for side in [-1, 1]:
			var curb = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(0.2, 0.15, 500)
			cm.material = curb_mat
			curb.mesh = cm
			curb.position = Vector3(i * 22 + side * 2.3, 0.12, 0)
			add_child(curb)
		# E-W roads: curbs on both sides
		for side in [-1, 1]:
			var curb = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(500, 0.15, 0.2)
			cm.material = curb_mat
			curb.mesh = cm
			curb.position = Vector3(0, 0.12, i * 22 + side * 2.3)
			add_child(curb)

func create_traffic_lights():
	# Traffic lights at major intersections
	var intersections = []
	for ix in range(-3, 4):
		for iz in range(-3, 4):
			if ix == 0 and iz == 0:
				continue  # Skip center (park)
			intersections.append(Vector3(ix * 22.0, 0, iz * 22.0))
	
	for inter in intersections:
		_add_traffic_light(inter)

func _add_traffic_light(pos: Vector3):
	# Place traffic light pole at intersection corner
	var corners = [
		Vector3(3.5, 0, 3.5),
		Vector3(-3.5, 0, 3.5),
		Vector3(3.5, 0, -3.5),
		Vector3(-3.5, 0, -3.5),
	]
	var corner = corners[randi() % corners.size()]
	var light_pos = pos + corner
	
	# Pole
	var pole = MeshInstance3D.new()
	var pm = CylinderMesh.new()
	pm.height = 5.5
	pm.top_radius = 0.08
	pm.bottom_radius = 0.1
	pm.material = _make_mat(Color(0.25, 0.25, 0.25), 0.5, 0.6)
	pole.mesh = pm
	pole.position = light_pos + Vector3(0, 2.75, 0)
	add_child(pole)
	
	# Horizontal arm
	var arm = MeshInstance3D.new()
	var am = BoxMesh.new()
	am.size = Vector3(0.1, 0.1, 3.0)
	am.material = _make_mat(Color(0.25, 0.25, 0.25), 0.5, 0.6)
	arm.mesh = am
	arm.position = light_pos + Vector3(0, 5.5, -1.5)
	add_child(arm)
	
	# Light housing
	var housing = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.4, 1.2, 0.3)
	hm.material = _make_mat(Color(0.15, 0.15, 0.15), 0.6, 0.3)
	housing.mesh = hm
	housing.position = light_pos + Vector3(0, 5.0, -3.0)
	add_child(housing)
	
	# Red light (top)
	var red = MeshInstance3D.new()
	var rm = SphereMesh.new()
	rm.radius = 0.12
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.9, 0.1, 0.1)
	red_mat.emission_enabled = true
	red_mat.emission = Color(1.0, 0.1, 0.1)
	red_mat.emission_energy_multiplier = 0.8
	rm.material = red_mat
	red.mesh = rm
	red.position = light_pos + Vector3(0, 5.35, -3.15)
	add_child(red)
	
	# Yellow light (middle)
	var yellow = MeshInstance3D.new()
	var ym = SphereMesh.new()
	ym.radius = 0.12
	var yellow_mat = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(0.4, 0.35, 0.1)
	yellow_mat.emission_enabled = false
	ym.material = yellow_mat
	yellow.mesh = ym
	yellow.position = light_pos + Vector3(0, 5.0, -3.15)
	add_child(yellow)
	
	# Green light (bottom)
	var green = MeshInstance3D.new()
	var gm = SphereMesh.new()
	gm.radius = 0.12
	var green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.1, 0.4, 0.1)
	green_mat.emission_enabled = false
	gm.material = green_mat
	green.mesh = gm
	green.position = light_pos + Vector3(0, 4.65, -3.15)
	add_child(green)

func _add_road(pos: Vector3, size: Vector3):
	var road = StaticBody3D.new()
	road.position = pos
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var road_mat = StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.18, 0.18, 0.20)
	road_mat.roughness = 0.85
	road_mat.metallic = 0.0
	mi.set_surface_override_material(0, road_mat)
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

	# Windows (rows of small dark/lit rectangles on facade)
	var floors = int(size.y / 3.0)
	for floor_i in range(1, floors):
		for side in range(4):
			var window = MeshInstance3D.new()
			var wm = BoxMesh.new()
			# Randomly lit window (~35% chance)
			var is_lit = randf() < 0.35
			var win_mat = StandardMaterial3D.new()
			if is_lit:
				win_mat.albedo_color = Color(0.85, 0.80, 0.55, 0.95)
				win_mat.emission_enabled = true
				win_mat.emission = Color(1.0, 0.9, 0.55)
				win_mat.emission_energy_multiplier = 0.6
			else:
				win_mat.albedo_color = Color(0.22, 0.28, 0.40, 0.85)
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

# ═══════════════════════ LANE MARKINGS ═══════════════════════
func create_lane_markings():
	var dash_mat = _make_mat(Color(0.95, 0.95, 0.95))
	# White dashed center line down every street
	for i in range(-5, 6):
		# N-S roads: dashes every 4 units
		for j in range(-24, 25):
			var mi = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.12, 0.02, 2.0)
			bm.material = dash_mat
			mi.mesh = bm
			mi.position = Vector3(float(i) * 22, 0.18, float(j) * 4.0)
			add_child(mi)
		# E-W roads: dashes every 4 units
		for j in range(-24, 25):
			var mi = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(2.0, 0.02, 0.12)
			bm.material = dash_mat
			mi.mesh = bm
			mi.position = Vector3(float(j) * 4.0, 0.18, float(i) * 22)
			add_child(mi)

# ═══════════════════════ CROSSWALKS ═══════════════════════
func create_crosswalks():
	var cw_mat = _make_mat(Color(0.9, 0.9, 0.9, 0.8))
	# At every road intersection, add a crosswalk
	for ix in range(-4, 5):
		for iz in range(-4, 5):
			var center = Vector3(ix * 22.0, 0.19, iz * 22.0)
			# Crosswalk strips — N side (Z+)
			for stripe in range(5):
				var mi = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(3.5, 0.01, 0.45)
				bm.material = cw_mat
				mi.mesh = bm
				mi.position = center + Vector3(0, 0, 3.6 + stripe * 0.9)
				add_child(mi)
			# Crosswalk strips — E side (X+)
			for stripe in range(5):
				var mi = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(0.45, 0.01, 3.5)
				bm.material = cw_mat
				mi.mesh = bm
				mi.position = center + Vector3(3.6 + stripe * 0.9, 0, 0)
				add_child(mi)

# ═══════════════════════ DISTRICTS ═══════════════════════
func create_districts():
	_create_harbor_district()
	_create_industrial_district()
	_create_residential_district()
	_create_downtown_extras()
	_create_police_station()
	_create_beach_area()
	_create_stadium()
	_create_parking_lots()

func _create_harbor_district():
	# Harbor: south-west, around (-100, 0, -100)
	var base = Vector3(-100, 0, -100)

	# Water area (dark blue plane)
	var water = MeshInstance3D.new()
	var wm = PlaneMesh.new()
	wm.size = Vector2(60, 40)
	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.05, 0.12, 0.28, 0.88)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.roughness = 0.05
	wm.material = wmat
	water.mesh = wm
	water.position = base + Vector3(0, 0.05, -10)
	add_child(water)

	# Dock platform
	for dk in range(3):
		var dock = StaticBody3D.new()
		dock.position = base + Vector3(dk * 18 - 18, 0.3, -8)
		var dm = MeshInstance3D.new()
		var dbm = BoxMesh.new()
		dbm.size = Vector3(5, 0.6, 20)
		dbm.material = _make_mat(Color(0.4, 0.28, 0.18), 0.9)
		dm.mesh = dbm
		dock.add_child(dm)
		var dcol = CollisionShape3D.new()
		var ds = BoxShape3D.new()
		ds.size = Vector3(5, 0.6, 20)
		dcol.shape = ds
		dock.add_child(dcol)
		add_child(dock)

		# Mooring post
		for post_side in [-1, 1]:
			var post = MeshInstance3D.new()
			var pm = CylinderMesh.new()
			pm.height = 1.5
			pm.top_radius = 0.12
			pm.bottom_radius = 0.14
			pm.material = _make_mat(Color(0.22, 0.16, 0.1))
			post.mesh = pm
			post.position = base + Vector3(dk * 18 - 18 + post_side * 2, 0.95, -8)
			add_child(post)

	# Warehouses
	_add_building(base + Vector3(30, 0, 5), Vector3(18, 10, 20), Color(0.55, 0.5, 0.48))
	_add_building(base + Vector3(-15, 0, 12), Vector3(14, 8, 16), Color(0.52, 0.48, 0.44))

	# Crane structure (simplified)
	var crane_pos = base + Vector3(0, 0, -5)
	var v_beam = MeshInstance3D.new()
	var vbm = BoxMesh.new()
	vbm.size = Vector3(0.6, 18, 0.6)
	vbm.material = _make_mat(Color(0.7, 0.6, 0.1), 0.5, 0.7)
	v_beam.mesh = vbm
	v_beam.position = crane_pos + Vector3(0, 9, 0)
	add_child(v_beam)
	var h_beam = MeshInstance3D.new()
	var hbm = BoxMesh.new()
	hbm.size = Vector3(12, 0.5, 0.5)
	hbm.material = _make_mat(Color(0.7, 0.6, 0.1), 0.5, 0.7)
	h_beam.mesh = hbm
	h_beam.position = crane_pos + Vector3(4, 18, 0)
	add_child(h_beam)

func _create_industrial_district():
	# Industrial: north-east, around (100, 0, -80)
	var base = Vector3(100, 0, -80)

	# Factory buildings (wide, low, corrugated look)
	_add_building(base + Vector3(0, 0, 0),   Vector3(22, 12, 16), Color(0.48, 0.44, 0.4))
	_add_building(base + Vector3(28, 0, 8),  Vector3(18, 10, 14), Color(0.45, 0.42, 0.38))
	_add_building(base + Vector3(-24, 0, -8), Vector3(16, 14, 12), Color(0.5, 0.46, 0.42))

	# Smokestacks
	for i in range(3):
		var stack = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		sm.top_radius = 0.4
		sm.bottom_radius = 0.55
		sm.height = 20.0
		sm.material = _make_mat(Color(0.35, 0.32, 0.3), 0.9)
		stack.mesh = sm
		stack.position = base + Vector3(i * 8 - 8, 10, -4)
		add_child(stack)
		# Smoke ring at top
		var top_ring = MeshInstance3D.new()
		var rm = CylinderMesh.new()
		rm.top_radius = 0.6
		rm.bottom_radius = 0.7
		rm.height = 0.3
		rm.material = _make_mat(Color(0.6, 0.6, 0.6, 0.5))
		top_ring.mesh = rm
		top_ring.position = base + Vector3(i * 8 - 8, 20.2, -4)
		add_child(top_ring)

	# Industrial fence with warning stripes
	for fx in range(8):
		var fence_post = MeshInstance3D.new()
		var fpm = CylinderMesh.new()
		fpm.height = 2.5
		fpm.top_radius = 0.05
		fpm.bottom_radius = 0.06
		fpm.material = _make_mat(Color(0.4, 0.4, 0.4), 0.5, 0.6)
		fence_post.mesh = fpm
		fence_post.position = base + Vector3(fx * 5 - 20, 1.25, -20)
		add_child(fence_post)

func _create_residential_district():
	# Residential: south-east, around (-80, 0, 100)
	var base = Vector3(-80, 0, 100)

	# Houses (smaller, varied colors)
	var house_data = [
		[Vector3(0, 0, 0),    Color(0.85, 0.78, 0.65)],
		[Vector3(20, 0, 0),   Color(0.72, 0.82, 0.72)],
		[Vector3(40, 0, 0),   Color(0.82, 0.72, 0.68)],
		[Vector3(0, 0, 22),   Color(0.78, 0.76, 0.85)],
		[Vector3(20, 0, 22),  Color(0.88, 0.82, 0.68)],
		[Vector3(40, 0, 22),  Color(0.74, 0.84, 0.76)],
	]
	for h in house_data:
		_add_house(base + h[0], h[1])

func _add_house(pos: Vector3, wall_color: Color):
	var body = StaticBody3D.new()
	var house_size = Vector3(10, 5.5, 8)
	body.position = pos + Vector3(0, house_size.y / 2.0, 0)

	# Walls
	var walls = MeshInstance3D.new()
	var wm = BoxMesh.new()
	wm.size = house_size
	wm.material = _make_mat(wall_color, 0.8)
	walls.mesh = wm
	body.add_child(walls)

	# Roof (gabled — two sloped faces)
	var roof = MeshInstance3D.new()
	var rm = PrismMesh.new()
	rm.size = Vector3(house_size.x + 0.6, 3.0, house_size.z + 0.6)
	rm.material = _make_mat(Color(0.55, 0.28, 0.18), 0.85)
	roof.mesh = rm
	roof.position = Vector3(0, house_size.y / 2.0 + 1.5, 0)
	body.add_child(roof)

	# Front door
	var door = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(1.1, 2.2, 0.06)
	dm.material = _make_mat(Color(0.35, 0.22, 0.12))
	door.mesh = dm
	door.position = Vector3(0, -house_size.y / 2.0 + 1.1, house_size.z / 2.0 + 0.03)
	body.add_child(door)

	# Windows
	for side_x in [-1, 1]:
		var win = MeshInstance3D.new()
		var wwin = BoxMesh.new()
		wwin.size = Vector3(1.6, 1.2, 0.05)
		var wmat = StandardMaterial3D.new()
		wmat.albedo_color = Color(0.75, 0.85, 0.95, 0.75)
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wmat.roughness = 0.05
		wwin.material = wmat
		win.mesh = wwin
		win.position = Vector3(side_x * 2.8, house_size.y / 2.0 - 1.5, house_size.z / 2.0 + 0.03)
		body.add_child(win)

	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = house_size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)

	# Front yard (small patch)
	var yard = MeshInstance3D.new()
	var ym = BoxMesh.new()
	ym.size = Vector3(house_size.x, 0.04, 5.0)
	ym.material = _make_mat(Color(0.18, 0.52, 0.18), 0.95)
	yard.mesh = ym
	yard.position = pos + Vector3(0, 0.02, house_size.z / 2.0 + 2.5)
	add_child(yard)

func _create_downtown_extras():
	# Billboard / large billboard structures near city center
	for bx in range(3):
		var pos = Vector3(-30 + bx * 30, 0, 0)
		# Billboard support poles
		for side in [-1, 1]:
			var pole = MeshInstance3D.new()
			var pm = CylinderMesh.new()
			pm.height = 9.0
			pm.top_radius = 0.12
			pm.bottom_radius = 0.16
			pm.material = _make_mat(Color(0.35, 0.35, 0.35), 0.5, 0.6)
			pole.mesh = pm
			pole.position = pos + Vector3(side * 2.0, 4.5, 12)
			add_child(pole)
		# Billboard face
		var board = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(6.0, 3.0, 0.15)
		var colors = [Color(0.9, 0.2, 0.1), Color(0.1, 0.5, 0.9), Color(0.15, 0.75, 0.3)]
		var bmat = StandardMaterial3D.new()
		bmat.albedo_color = colors[bx % colors.size()]
		bmat.emission_enabled = true
		bmat.emission = colors[bx % colors.size()]
		bmat.emission_energy_multiplier = 0.25
		bm.material = bmat
		board.mesh = bm
		board.position = pos + Vector3(0, 9.5, 12)
		add_child(board)

# ═══════════════════════ SIDEWALKS ═══════════════════════
func create_sidewalks():
	# Raised sidewalks along roads with collision to keep traffic on roads
	var sw_mat = _make_mat(Color(0.58, 0.56, 0.52), 0.9)
	for i in range(-5, 6):
		for is_ns in [true, false]:
			for side in [-1, 1]:
				var body = StaticBody3D.new()
				body.collision_layer = 1  # World layer
				body.collision_mask = 0
				
				var sw = MeshInstance3D.new()
				var swm = BoxMesh.new()
				var col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				
				if is_ns:
					swm.size = Vector3(1.4, 0.18, 500)
					box.size = Vector3(1.4, 0.18, 500)
					body.position = Vector3(i * 22 + side * 3.0, 0.09, 0)
				else:
					swm.size = Vector3(500, 0.18, 1.4)
					box.size = Vector3(500, 0.18, 1.4)
					body.position = Vector3(0, 0.09, i * 22 + side * 3.0)
				
				swm.material = sw_mat
				sw.mesh = swm
				col.shape = box
				body.add_child(sw)
				body.add_child(col)
				add_child(body)

# ═══════════════════════ LIGHTING ═══════════════════════
func setup_lighting():
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0
	sun.directional_shadow_max_distance = 250.0
	sun.light_color = Color(1.0, 0.96, 0.88)
	add_child(sun)
	
	# Add fill light for softer shadows
	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_energy = 0.3
	fill.light_color = Color(0.7, 0.8, 1.0)
	fill.shadow_enabled = false
	fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(120), 0)
	add_child(fill)

func setup_sky():
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var proc_sky = ProceduralSkyMaterial.new()
	proc_sky.sky_top_color = Color(0.12, 0.30, 0.70)
	proc_sky.sky_horizon_color = Color(0.50, 0.65, 0.90)
	proc_sky.ground_bottom_color = Color(0.15, 0.40, 0.15)
	proc_sky.ground_horizon_color = Color(0.50, 0.60, 0.50)
	proc_sky.sun_angle_max = 35.0
	proc_sky.sun_curve = 0.08
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

# ═══════════════════════ POLICE STATION ═══════════════════════
func _create_police_station():
	var base = Vector3(80, 0, 60)
	
	# Main building
	var station = StaticBody3D.new()
	station.position = base + Vector3(0, 6, 0)
	
	var main_bldg = MeshInstance3D.new()
	var mbm = BoxMesh.new()
	mbm.size = Vector3(20, 12, 16)
	mbm.material = _make_mat(Color(0.7, 0.72, 0.75), 0.6, 0.1)
	main_bldg.mesh = mbm
	station.add_child(main_bldg)
	
	# Police station sign
	var sign = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(12, 1.5, 0.2)
	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = Color(0.1, 0.2, 0.5)
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(0.15, 0.25, 0.6)
	sign_mat.emission_energy_multiplier = 0.5
	sm.material = sign_mat
	sign.mesh = sm
	sign.position = Vector3(0, 5.2, 8.1)
	station.add_child(sign)
	
	# Blue light bars on roof
	for side in [-1, 1]:
		var light_bar = MeshInstance3D.new()
		var lbm = BoxMesh.new()
		lbm.size = Vector3(3, 0.3, 0.4)
		var light_mat = StandardMaterial3D.new()
		light_mat.albedo_color = Color(0.2, 0.4, 0.9)
		light_mat.emission_enabled = true
		light_mat.emission = Color(0.2, 0.4, 1.0)
		light_mat.emission_energy_multiplier = 1.0
		lbm.material = light_mat
		light_bar.mesh = lbm
		light_bar.position = Vector3(side * 5, 6.2, 0)
		station.add_child(light_bar)
	
	# Entry doors
	for dx in [-1, 1]:
		var door = MeshInstance3D.new()
		var dm = BoxMesh.new()
		dm.size = Vector3(1.5, 3, 0.08)
		dm.material = _make_mat(Color(0.3, 0.35, 0.4))
		door.mesh = dm
		door.position = Vector3(dx * 2, -4.5, 8.04)
		station.add_child(door)
	
	# Windows
	for floor_i in range(2):
		for wx in range(-2, 3):
			if wx == 0 and floor_i == 0:
				continue  # Skip window above door
			var win = MeshInstance3D.new()
			var wm = BoxMesh.new()
			wm.size = Vector3(2, 1.8, 0.06)
			var wmat = StandardMaterial3D.new()
			wmat.albedo_color = Color(0.5, 0.6, 0.75, 0.7)
			wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wmat.roughness = 0.1
			wm.material = wmat
			win.mesh = wm
			win.position = Vector3(wx * 3.5, -1.5 + floor_i * 4, 8.03)
			station.add_child(win)
	
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(20, 12, 16)
	cs.shape = bs
	station.add_child(cs)
	add_child(station)
	
	# Parking lot in front
	var lot = MeshInstance3D.new()
	var lm = BoxMesh.new()
	lm.size = Vector3(24, 0.1, 12)
	lm.material = _make_mat(Color(0.18, 0.18, 0.2))
	lot.mesh = lm
	lot.position = base + Vector3(0, 0.05, 18)
	add_child(lot)
	
	# Parking lines
	for px in range(-3, 4):
		var line = MeshInstance3D.new()
		var linm = BoxMesh.new()
		linm.size = Vector3(0.1, 0.02, 5)
		linm.material = _make_mat(Color(0.9, 0.9, 0.9))
		line.mesh = linm
		line.position = base + Vector3(px * 3, 0.12, 18)
		add_child(line)

# ═══════════════════════ BEACH AREA ═══════════════════════
func _create_beach_area():
	var base = Vector3(-120, 0, 80)
	
	# Sand area
	var sand = MeshInstance3D.new()
	var sandm = BoxMesh.new()
	sandm.size = Vector3(50, 0.15, 40)
	sandm.material = _make_mat(Color(0.92, 0.85, 0.65), 0.95)
	sand.mesh = sandm
	sand.position = base + Vector3(0, 0.08, 0)
	add_child(sand)
	
	# Ocean water
	var ocean = MeshInstance3D.new()
	var om = PlaneMesh.new()
	om.size = Vector2(100, 60)
	var ocean_mat = StandardMaterial3D.new()
	ocean_mat.albedo_color = Color(0.08, 0.25, 0.45, 0.85)
	ocean_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ocean_mat.roughness = 0.02
	om.material = ocean_mat
	ocean.mesh = om
	ocean.position = base + Vector3(-50, 0.03, 0)
	add_child(ocean)
	
	# Beach umbrellas
	var umbrella_colors = [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.9, 0.8, 0.2), Color(0.2, 0.8, 0.3)]
	for i in range(6):
		var ux = randf_range(-20, 20)
		var uz = randf_range(-15, 15)
		# Pole
		var pole = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 2.5
		pm.top_radius = 0.04
		pm.bottom_radius = 0.05
		pm.material = _make_mat(Color(0.45, 0.35, 0.2))
		pole.mesh = pm
		pole.position = base + Vector3(ux, 1.25, uz)
		add_child(pole)
		# Umbrella top
		var top = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.1
		tm.bottom_radius = 1.8
		tm.height = 0.4
		tm.material = _make_mat(umbrella_colors[i % umbrella_colors.size()])
		top.mesh = tm
		top.position = base + Vector3(ux, 2.6, uz)
		add_child(top)
	
	# Lifeguard tower
	var tower_base = base + Vector3(15, 0, 10)
	# Platform
	var platform = MeshInstance3D.new()
	var pfm = BoxMesh.new()
	pfm.size = Vector3(4, 0.2, 4)
	pfm.material = _make_mat(Color(0.75, 0.55, 0.35))
	platform.mesh = pfm
	platform.position = tower_base + Vector3(0, 3.1, 0)
	add_child(platform)
	# Legs
	for lx in [-1, 1]:
		for lz in [-1, 1]:
			var leg = MeshInstance3D.new()
			var legm = CylinderMesh.new()
			legm.height = 3.0
			legm.top_radius = 0.08
			legm.bottom_radius = 0.1
			legm.material = _make_mat(Color(0.75, 0.55, 0.35))
			leg.mesh = legm
			leg.position = tower_base + Vector3(lx * 1.5, 1.5, lz * 1.5)
			add_child(leg)
	# Cabin
	var cabin = MeshInstance3D.new()
	var cbm = BoxMesh.new()
	cbm.size = Vector3(3.5, 2.5, 3.5)
	cbm.material = _make_mat(Color(0.85, 0.75, 0.6))
	cabin.mesh = cbm
	cabin.position = tower_base + Vector3(0, 4.45, 0)
	add_child(cabin)
	# Red stripe
	var stripe = MeshInstance3D.new()
	var stm = BoxMesh.new()
	stm.size = Vector3(3.6, 0.4, 0.1)
	stm.material = _make_mat(Color(0.9, 0.2, 0.15))
	stripe.mesh = stm
	stripe.position = tower_base + Vector3(0, 4.8, 1.8)
	add_child(stripe)

# ═══════════════════════ STADIUM ═══════════════════════
func _create_stadium():
	var base = Vector3(100, 0, 100)
	
	# Stadium ring (outer wall)
	var wall_segments = 16
	var radius = 35.0
	var wall_height = 18.0
	
	for i in range(wall_segments):
		var angle = i * (TAU / wall_segments)
		var next_angle = (i + 1) * (TAU / wall_segments)
		var mid_angle = (angle + next_angle) / 2.0
		
		var wall = MeshInstance3D.new()
		var wm = BoxMesh.new()
		wm.size = Vector3(radius * 0.4, wall_height, 1.5)
		wm.material = _make_mat(Color(0.75, 0.75, 0.8), 0.7, 0.1)
		wall.mesh = wm
		wall.position = base + Vector3(cos(mid_angle) * radius, wall_height / 2, sin(mid_angle) * radius)
		wall.rotation.y = -mid_angle + PI / 2
		add_child(wall)
	
	# Field (green)
	var field = MeshInstance3D.new()
	var fm = CylinderMesh.new()
	fm.top_radius = 28.0
	fm.bottom_radius = 28.0
	fm.height = 0.1
	fm.material = _make_mat(Color(0.15, 0.55, 0.18))
	field.mesh = fm
	field.position = base + Vector3(0, 0.05, 0)
	add_child(field)
	
	# Stadium seating tiers (simplified)
	for tier in range(3):
		var seats = MeshInstance3D.new()
		var sm = TorusMesh.new()
		sm.inner_radius = 28.0 + tier * 2.5
		sm.outer_radius = 30.0 + tier * 2.5
		var seat_mat = StandardMaterial3D.new()
		seat_mat.albedo_color = Color(0.5 + tier * 0.1, 0.5 + tier * 0.05, 0.55)
		sm.material = seat_mat
		seats.mesh = sm
		seats.position = base + Vector3(0, 1.5 + tier * 4, 0)
		seats.rotation.x = PI / 2
		add_child(seats)
	
	# Floodlights on corners
	var light_positions = [
		Vector3(-32, 0, -32), Vector3(32, 0, -32),
		Vector3(-32, 0, 32), Vector3(32, 0, 32)
	]
	for lp in light_positions:
		# Light pole
		var pole = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 30.0
		pm.top_radius = 0.3
		pm.bottom_radius = 0.5
		pm.material = _make_mat(Color(0.4, 0.4, 0.4), 0.5, 0.6)
		pole.mesh = pm
		pole.position = base + lp + Vector3(0, 15, 0)
		add_child(pole)
		# Light fixture
		var fixture = MeshInstance3D.new()
		var fxm = BoxMesh.new()
		fxm.size = Vector3(4, 2, 1)
		var fix_mat = StandardMaterial3D.new()
		fix_mat.albedo_color = Color(0.9, 0.9, 0.9)
		fix_mat.emission_enabled = true
		fix_mat.emission = Color(1.0, 0.98, 0.9)
		fix_mat.emission_energy_multiplier = 0.8
		fxm.material = fix_mat
		fixture.mesh = fxm
		fixture.position = base + lp + Vector3(0, 30.5, 0)
		add_child(fixture)
		fixture.look_at(base + Vector3(0, 0, 0), Vector3.UP)

# ═══════════════════════ PARKING LOTS ═══════════════════════
func _create_parking_lots():
	var lot_positions = [
		Vector3(70, 0, -50),
		Vector3(-70, 0, 45),
		Vector3(45, 0, 75),
	]
	
	for lot_pos in lot_positions:
		# Asphalt surface
		var lot = MeshInstance3D.new()
		var lm = BoxMesh.new()
		var lot_size = Vector3(30, 0.1, 20)
		lm.size = lot_size
		lm.material = _make_mat(Color(0.15, 0.15, 0.17))
		lot.mesh = lm
		lot.position = lot_pos + Vector3(0, 0.05, 0)
		add_child(lot)
		
		# Parking space lines
		var spaces_x = int(lot_size.x / 3.5)
		for sx in range(spaces_x):
			# Vertical lines
			var line = MeshInstance3D.new()
			var linm = BoxMesh.new()
			linm.size = Vector3(0.08, 0.02, 5)
			linm.material = _make_mat(Color(0.9, 0.9, 0.9))
			line.mesh = linm
			line.position = lot_pos + Vector3(-lot_size.x / 2 + 2 + sx * 3.5, 0.12, -5)
			add_child(line)
			# Back row
			var line2 = MeshInstance3D.new()
			var linm2 = BoxMesh.new()
			linm2.size = Vector3(0.08, 0.02, 5)
			linm2.material = _make_mat(Color(0.9, 0.9, 0.9))
			line2.mesh = linm2
			line2.position = lot_pos + Vector3(-lot_size.x / 2 + 2 + sx * 3.5, 0.12, 5)
			add_child(line2)
		
		# Random parked cars (decorative)
		for i in range(randi() % 4 + 2):
			var car_x = randf_range(-lot_size.x / 2 + 3, lot_size.x / 2 - 3)
			var car_z = [-5, 5][randi() % 2] + randf_range(-1, 1)
			_add_parked_car(lot_pos + Vector3(car_x, 0, car_z))

func _add_parked_car(pos: Vector3):
	var car = Node3D.new()
	car.position = pos
	
	var car_colors = [
		Color(0.7, 0.1, 0.1),   # Red
		Color(0.1, 0.1, 0.7),   # Blue
		Color(0.1, 0.1, 0.1),   # Black
		Color(0.9, 0.9, 0.9),   # White
		Color(0.5, 0.5, 0.5),   # Gray
		Color(0.2, 0.5, 0.2),   # Green
	]
	var car_color = car_colors[randi() % car_colors.size()]
	
	# Car body
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.8, 0.8, 4.0)
	bm.material = _make_mat(car_color, 0.4, 0.3)
	body.mesh = bm
	body.position.y = 0.7
	car.add_child(body)
	
	# Cabin
	var cabin = MeshInstance3D.new()
	var cbm = BoxMesh.new()
	cbm.size = Vector3(1.6, 0.6, 2.0)
	cbm.material = _make_mat(car_color.darkened(0.1), 0.4, 0.3)
	cabin.mesh = cbm
	cabin.position = Vector3(0, 1.25, -0.3)
	car.add_child(cabin)
	
	# Windows
	var win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.2, 0.25, 0.35, 0.7)
	win_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	win_mat.roughness = 0.05
	
	# Front windshield
	var fw = MeshInstance3D.new()
	var fwm = BoxMesh.new()
	fwm.size = Vector3(1.5, 0.55, 0.05)
	fwm.material = win_mat
	fw.mesh = fwm
	fw.position = Vector3(0, 1.25, 0.72)
	fw.rotation.x = 0.3
	car.add_child(fw)
	
	# Wheels
	for wx in [-1, 1]:
		for wz in [-1, 1]:
			var wheel = MeshInstance3D.new()
			var wm = CylinderMesh.new()
			wm.top_radius = 0.28
			wm.bottom_radius = 0.28
			wm.height = 0.2
			wm.material = _make_mat(Color(0.1, 0.1, 0.1), 0.9)
			wheel.mesh = wm
			wheel.position = Vector3(wx * 0.85, 0.28, wz * 1.3)
			wheel.rotation.z = PI / 2
			car.add_child(wheel)
	
	# Random rotation
	car.rotation.y = randf_range(-0.1, 0.1) + (PI if randf() > 0.5 else 0)
	add_child(car)
