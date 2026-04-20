extends Node3D
# World/Environment — GTA city with buildings, shops, trees, parks, etc.

var sun: DirectionalLight3D
var time_of_day = 8.0
var day_speed = 0.015
var streetlights: Array = []

# Spatial exclusion zones to prevent object overlapping (Vice City style)
var _occupied_zones: Array = []  # Array of Rect2 (x, z, w, d)

func _register_zone(center_x: float, center_z: float, width: float, depth: float):
	_occupied_zones.append(Rect2(center_x - width / 2.0, center_z - depth / 2.0, width, depth))

func _is_zone_free(center_x: float, center_z: float, width: float, depth: float) -> bool:
	var test = Rect2(center_x - width / 2.0, center_z - depth / 2.0, width, depth)
	for zone in _occupied_zones:
		if zone.intersects(test):
			return false
	return true

func _ready():
	add_to_group("world_environment")
	print("[WORLD] Starting environment generation...")
	create_terrain()
	create_roads()
	_register_road_zones()
	create_road_curbs()
	create_ocean_and_beach()
	# Priority placement order: landmarks → establishments → buildings
	create_districts()
	create_buildings()
	create_shops()
	create_traffic_lights()
	create_crosswalks()
	create_trees()
	create_park()
	create_streetlights()
	create_sidewalks()
	create_save_point_markers()
	create_neon_signs()
	setup_lighting()
	setup_sky()
	print("[WORLD] Environment generation complete!")

func _register_road_zones():
	# Register all road strips as occupied zones so buildings/objects don't overlap them
	# 18m zone = 8m road + 5m sidewalk each side — prevents any clipping
	for i in range(-12, 13):
		var road_pos = i * 50.0
		var zone_w = 18.0 if i != 0 else 22.0  # Main boulevard wider
		# North-south roads (extended to 1300m to cover bigger map)
		_register_zone(road_pos, 0, zone_w, 1300.0)
		# East-west roads
		_register_zone(0, road_pos, 1300.0, zone_w)

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

	var gm = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(1500, 1500)
	gm.mesh = plane
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.18, 0.52, 0.22)
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
	# Main streets (4-lane boulevard — realistic 12m width)
	_add_road(Vector3(0, 0.02, 0), Vector3(12, 0.15, 1800))    # Main N-S boulevard
	_add_road(Vector3(0, 0.02, 0), Vector3(1800, 0.15, 12))    # Main E-W boulevard

	# City grid — from -12 to +12 blocks (50m spacing, realistic block size)
	for i in range(-12, 13):
		if i == 0: continue
		_add_road(Vector3(i * 50, 0.02, 0), Vector3(8.0, 0.12, 1800))   # 2-lane roads (8m)
		_add_road(Vector3(0, 0.02, i * 50), Vector3(1800, 0.12, 8.0))

	# Road center lines — yellow dashed on every road
	for i in range(-12, 13, 2):
		for j in range(-18, 19):
			_add_road_marking(Vector3(i * 50, 0.16, j * 20), true)
			_add_road_marking(Vector3(j * 20, 0.16, i * 50), false)

func create_road_curbs():
	var curb_mat = _make_mat(Color(0.6, 0.6, 0.58), 0.85)
	for i in range(-12, 13):
		for side in [-1, 1]:
			var curb = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(0.25, 0.15, 1800)
			cm.material = curb_mat
			curb.mesh = cm
			curb.position = Vector3(i * 50 + side * 4.5, 0.12, 0)
			add_child(curb)
		for side in [-1, 1]:
			var curb = MeshInstance3D.new()
			var cm = BoxMesh.new()
			cm.size = Vector3(1800, 0.15, 0.25)
			cm.material = curb_mat
			curb.mesh = cm
			curb.position = Vector3(0, 0.12, i * 50 + side * 4.5)
			add_child(curb)

func create_traffic_lights():
	# Traffic lights at major intersections only (every 3rd)
	var intersections = []
	for ix in range(-8, 9):
		for iz in range(-8, 9):
			if ix == 0 and iz == 0:
				continue
			if (ix + iz) % 3 == 0:
				intersections.append(Vector3(ix * 50.0, 0, iz * 50.0))
	
	for inter in intersections:
		_add_traffic_light(inter)

func _add_traffic_light(pos: Vector3):
	# Place traffic light pole at intersection corner
	var corners = [
		Vector3(5.5, 0, 5.5),
		Vector3(-5.5, 0, 5.5),
		Vector3(5.5, 0, -5.5),
		Vector3(-5.5, 0, -5.5),
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
	# Vice City style — pastel Art Deco colors, neon accents
	var building_colors = [
		Color(0.90, 0.75, 0.80),  # Pink pastel
		Color(0.70, 0.88, 0.90),  # Aqua/teal
		Color(0.95, 0.90, 0.75),  # Cream/sand
		Color(0.85, 0.80, 0.95),  # Lavender
		Color(0.95, 0.85, 0.70),  # Peach
		Color(0.75, 0.90, 0.80),  # Mint green
		Color(0.92, 0.92, 0.88),  # Off-white
		Color(0.80, 0.85, 0.92),  # Light blue
		Color(0.90, 0.78, 0.68),  # Coral
		Color(0.88, 0.82, 0.75),  # Tan
		Color(0.75, 0.80, 0.90),  # Periwinkle
		Color(0.92, 0.80, 0.85),  # Rose
	]
	# Neon accent colors for building trim
	var neon_colors = [
		Color(1.0, 0.2, 0.6),   # Hot pink
		Color(0.2, 0.9, 0.9),   # Cyan
		Color(1.0, 0.5, 0.1),   # Orange neon
		Color(0.5, 0.2, 1.0),   # Purple neon
		Color(0.2, 1.0, 0.4),   # Green neon
		Color(1.0, 1.0, 0.2),   # Yellow neon
	]
	
	for bx in range(-11, 12):
		for bz in range(-11, 12):
			# Skip the center park area and shop blocks
			if abs(bx) <= 1 and abs(bz) <= 1:
				continue
			# Skip ocean/beach area (south side)
			if bz > 6:
				continue
			# Skip LA River channel area
			if bx == 3 or bx == -3:
				continue
			
			var block_center = Vector3((bx + 0.5) * 50, 0, (bz + 0.5) * 50)
			var dist_from_center = Vector2(block_center.x, block_center.z).length()
			# LA skyline: tall downtown, medium midtown, low suburbs (now extends to ±550m)
			var max_height = 55.0 if dist_from_center < 60 else (35.0 if dist_from_center < 120 else (20.0 if dist_from_center < 180 else (12.0 if dist_from_center < 350 else 8.0)))
			var min_height = 18.0 if dist_from_center < 60 else (8.0 if dist_from_center < 120 else (4.0 if dist_from_center < 180 else (3.0 if dist_from_center < 350 else 3.0)))
			
			var height = randf_range(min_height, max_height)
			var width = randf_range(14, 26)
			var depth = randf_range(14, 26)
			var color = building_colors[randi() % building_colors.size()]
			
			# Check overlap before placing — skip if zone occupied (6m margin)
			if not _is_zone_free(block_center.x, block_center.z, width + 6, depth + 6):
				# Try smaller building
				width = min(width, 12)
				depth = min(depth, 12)
				if not _is_zone_free(block_center.x, block_center.z, width + 6, depth + 6):
					continue
			
			_register_zone(block_center.x, block_center.z, width, depth)
			_add_building(block_center, Vector3(width, height, depth), color)

func _add_building(pos: Vector3, size: Vector3, color: Color):
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, size.y / 2.0, 0)
	var dist = Vector2(pos.x, pos.z).length()
	var style = 0  # 0=modern glass, 1=art deco, 2=LA stucco, 3=industrial
	if dist < 60:
		style = 0  # Downtown: modern glass towers
	elif dist < 120:
		style = 1 if randf() < 0.6 else 2  # Midtown: art deco or stucco
	elif dist < 200:
		style = 2 if randf() < 0.7 else 3  # Suburbs: LA stucco or industrial
	else:
		style = 3  # Periphery: industrial

	# ═══ KENNEY GLB PATH ═══
	# Use real Kenney building art when available. Style 0/1 → commercial, 2/3 → suburban.
	var glb_filter = "building-skyscraper" if style == 0 else ("building-" if style == 1 else "building-type-")
	var glb := AssetLoader.pick_random_filtered("building", glb_filter)
	if glb == null:
		glb = AssetLoader.pick_random_any("building")
	if glb != null:
		var inst = glb.instantiate()
		# Kenney buildings are roughly 4-unit grid blocks. Scale to fit requested footprint and height.
		var scale_xz = max(size.x, size.z) / 4.5
		var scale_y = max(size.y / 6.0, scale_xz)  # Buildings stretch vertically for towers
		inst.scale = Vector3(scale_xz, scale_y, scale_xz)
		inst.position = Vector3(0, -size.y / 2.0, 0)  # GLB pivot is at base
		inst.rotation.y = (randi() % 4) * (PI * 0.5)  # cardinal rotations only
		body.add_child(inst)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		add_child(body)
		return

	var base_mat = _make_mat(color, 0.6, 0.05)
	var dark_mat = _make_mat(color.darkened(0.2), 0.7, 0.05)
	var accent_color = color.lightened(0.15)
	var accent_mat = _make_mat(accent_color, 0.5, 0.1)

	# ═══ MAIN STRUCTURE (with setbacks for tall buildings) ═══
	if size.y > 30 and style == 0:
		# Stepped tower: base wider, upper narrower
		var base_h = size.y * 0.4
		var tower_h = size.y * 0.6
		# Base podium
		var base_mi = MeshInstance3D.new()
		var bbm = BoxMesh.new()
		bbm.size = Vector3(size.x, base_h, size.z)
		bbm.material = base_mat
		base_mi.mesh = bbm
		base_mi.position = Vector3(0, -size.y / 2.0 + base_h / 2.0, 0)
		body.add_child(base_mi)
		# Upper tower (narrower)
		var tower = MeshInstance3D.new()
		var twm = BoxMesh.new()
		twm.size = Vector3(size.x * 0.72, tower_h, size.z * 0.72)
		twm.material = _make_mat(color.lightened(0.05), 0.5, 0.08)
		tower.mesh = twm
		tower.position = Vector3(0, -size.y / 2.0 + base_h + tower_h / 2.0, 0)
		body.add_child(tower)
	else:
		# Standard building
		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.set_surface_override_material(0, base_mat)
		body.add_child(mi)

	# ═══ FACADE DETAILS (style-dependent) ═══
	match style:
		0:  # Modern glass — curtain wall grid + reflective panels
			# Horizontal floor lines
			var floors = int(size.y / 3.5)
			for fi in range(1, floors):
				var floor_line = MeshInstance3D.new()
				var flm = BoxMesh.new()
				flm.size = Vector3(size.x + 0.08, 0.06, size.z + 0.08)
				flm.material = _make_mat(Color(0.25, 0.25, 0.28), 0.3, 0.6)
				floor_line.mesh = flm
				floor_line.position = Vector3(0, -size.y / 2.0 + fi * 3.5, 0)
				body.add_child(floor_line)
			# Vertical mullions on front/back
			var mullion_count = int(size.x / 3.0)
			for mi_i in range(mullion_count + 1):
				var mullion = MeshInstance3D.new()
				var mlm = BoxMesh.new()
				mlm.size = Vector3(0.06, size.y, 0.06)
				mlm.material = _make_mat(Color(0.25, 0.25, 0.28), 0.3, 0.6)
				mullion.mesh = mlm
				mullion.position = Vector3(-size.x / 2.0 + mi_i * 3.0, 0, size.z / 2.0 + 0.03)
				body.add_child(mullion)
			# Glass curtain wall panels (front + back)
			for face in [1, -1]:
				var glass_panel = MeshInstance3D.new()
				var gpm = BoxMesh.new()
				gpm.size = Vector3(size.x * 0.92, size.y * 0.85, 0.04)
				var gmat = StandardMaterial3D.new()
				gmat.albedo_color = Color(0.35, 0.45, 0.60, 0.55)
				gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				gmat.roughness = 0.05
				gmat.metallic = 0.5
				gpm.material = gmat
				glass_panel.mesh = gpm
				glass_panel.position = Vector3(0, 0, face * (size.z / 2.0 + 0.03))
				body.add_child(glass_panel)

		1:  # Art Deco — vertical pilasters, crown detail, geometric trim
			# Pilasters (vertical strips on facade)
			var pilaster_count = int(size.x / 5.0) + 1
			for pi in range(pilaster_count):
				var pilaster = MeshInstance3D.new()
				var plm = BoxMesh.new()
				plm.size = Vector3(0.35, size.y, 0.15)
				plm.material = accent_mat
				pilaster.mesh = plm
				pilaster.position = Vector3(-size.x / 2.0 + pi * 5.0, 0, size.z / 2.0 + 0.08)
				body.add_child(pilaster)
			# Crown/cornice (stepped top)
			var crown = MeshInstance3D.new()
			var crm = BoxMesh.new()
			crm.size = Vector3(size.x + 0.5, 1.2, size.z + 0.5)
			crm.material = accent_mat
			crown.mesh = crm
			crown.position = Vector3(0, size.y / 2.0 - 0.5, 0)
			body.add_child(crown)
			# Stepped pyramid crown detail
			var tip = MeshInstance3D.new()
			var tipm = BoxMesh.new()
			tipm.size = Vector3(size.x * 0.4, 1.5, size.z * 0.4)
			tipm.material = _make_mat(accent_color.lightened(0.1), 0.4, 0.15)
			tip.mesh = tipm
			tip.position = Vector3(0, size.y / 2.0 + 0.8, 0)
			body.add_child(tip)
			# Decorative window arches (front)
			for fi in range(1, int(size.y / 4.0)):
				for wx in range(int(size.x / 4.5)):
					if randf() < 0.3:
						continue
					var arch = MeshInstance3D.new()
					var arm = CylinderMesh.new()
					arm.top_radius = 0.5
					arm.bottom_radius = 0.5
					arm.height = 0.08
					arm.material = accent_mat
					arch.mesh = arm
					arch.position = Vector3(-size.x / 2.0 + 2.5 + wx * 4.5, -size.y / 2.0 + fi * 4.0 + 1.2, size.z / 2.0 + 0.05)
					arch.rotation.x = PI / 2
					body.add_child(arch)

		2:  # LA Stucco — warm colors, balconies, terracotta accents
			# Balconies (every other floor)
			for fi in range(2, int(size.y / 4.0), 2):
				for side_x in [-1, 1]:
					if randf() < 0.4:
						continue
					var balcony_floor = MeshInstance3D.new()
					var bfm = BoxMesh.new()
					bfm.size = Vector3(3.0, 0.12, 1.2)
					bfm.material = _make_mat(Color(0.75, 0.7, 0.65), 0.8)
					balcony_floor.mesh = bfm
					balcony_floor.position = Vector3(side_x * (size.x / 2.0 - 2.0), -size.y / 2.0 + fi * 4.0, size.z / 2.0 + 0.6)
					body.add_child(balcony_floor)
					# Balcony railing
					var railing = MeshInstance3D.new()
					var rlm = BoxMesh.new()
					rlm.size = Vector3(3.0, 0.8, 0.05)
					rlm.material = _make_mat(Color(0.4, 0.35, 0.3), 0.6, 0.3)
					railing.mesh = rlm
					railing.position = Vector3(side_x * (size.x / 2.0 - 2.0), -size.y / 2.0 + fi * 4.0 + 0.4, size.z / 2.0 + 1.15)
					body.add_child(railing)
			# Terracotta roof ledge
			var roof_ledge = MeshInstance3D.new()
			var rlm2 = BoxMesh.new()
			rlm2.size = Vector3(size.x + 0.6, 0.35, size.z + 0.6)
			rlm2.material = _make_mat(Color(0.72, 0.42, 0.22), 0.85)
			roof_ledge.mesh = rlm2
			roof_ledge.position = Vector3(0, size.y / 2.0 + 0.18, 0)
			body.add_child(roof_ledge)

		3:  # Industrial — corrugated look, exposed elements
			# Corrugated ridges (horizontal lines)
			for ri in range(0, int(size.y / 1.5)):
				var ridge = MeshInstance3D.new()
				var rdm = BoxMesh.new()
				rdm.size = Vector3(size.x + 0.04, 0.08, 0.06)
				rdm.material = dark_mat
				ridge.mesh = rdm
				ridge.position = Vector3(0, -size.y / 2.0 + ri * 1.5, size.z / 2.0 + 0.03)
				body.add_child(ridge)
			# Loading dock door
			var dock_door = MeshInstance3D.new()
			var ddm = BoxMesh.new()
			ddm.size = Vector3(4.0, 4.0, 0.08)
			ddm.material = _make_mat(Color(0.3, 0.3, 0.32), 0.6, 0.4)
			dock_door.mesh = ddm
			dock_door.position = Vector3(0, -size.y / 2.0 + 2.0, size.z / 2.0 + 0.04)
			body.add_child(dock_door)

	# ═══ NEON ACCENT TRIM (Vice City style — kept for all styles) ═══
	var neon_colors = [
		Color(1.0, 0.2, 0.6), Color(0.2, 0.9, 0.9), Color(1.0, 0.5, 0.1),
		Color(0.5, 0.2, 1.0), Color(0.2, 1.0, 0.4), Color(1.0, 1.0, 0.2),
	]
	var neon_color = neon_colors[randi() % neon_colors.size()]
	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = neon_color
	neon_mat.emission_enabled = true
	neon_mat.emission = neon_color
	neon_mat.emission_energy_multiplier = 0.8

	# Neon roof trim (front + back)
	for face in [1, -1]:
		var trim = MeshInstance3D.new()
		var tfm = BoxMesh.new()
		tfm.size = Vector3(size.x + 0.2, 0.12, 0.08)
		tfm.material = neon_mat
		trim.mesh = tfm
		trim.position = Vector3(0, size.y / 2.0 - 0.3, face * (size.z / 2.0 + 0.04))
		body.add_child(trim)

	# ═══ GROUND FLOOR (awning + entry) ═══
	if size.y > 6.0:
		var awning_mat = _make_mat(neon_color.darkened(0.3), 0.7)
		var awning = MeshInstance3D.new()
		var awm = BoxMesh.new()
		awm.size = Vector3(size.x * 0.8, 0.08, 1.5)
		awm.material = awning_mat
		awning.mesh = awm
		awning.position = Vector3(0, -size.y / 2.0 + 3.5, size.z / 2.0 + 0.75)
		body.add_child(awning)
		# Entry door
		var entry = MeshInstance3D.new()
		var enm = BoxMesh.new()
		enm.size = Vector3(1.8, 2.8, 0.06)
		enm.material = _make_mat(Color(0.06, 0.05, 0.04))
		entry.mesh = enm
		entry.position = Vector3(0, -size.y / 2.0 + 1.4, size.z / 2.0 + 0.04)
		body.add_child(entry)

	# ═══ WINDOWS (rows on facade) ═══
	var floors = int(size.y / 3.0)
	for floor_i in range(1, floors, 3):
		for side in range(2):
			var window = MeshInstance3D.new()
			var wm = BoxMesh.new()
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
			wm.size = Vector3(size.x * 0.7, 1.2, 0.05)
			var z_off = (size.z / 2.0 + 0.03) * (1 if side == 0 else -1)
			window.position = Vector3(0, -size.y / 2.0 + floor_i * 3.0, z_off)
			wm.material = win_mat
			window.mesh = wm
			body.add_child(window)

	# ═══ ROOFTOP FEATURES ═══
	# Roof slab
	var roof = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(size.x + 0.5, 0.3, size.z + 0.5)
	rm.material = _make_mat(color.darkened(0.2), 0.9)
	roof.mesh = rm
	roof.position = Vector3(0, size.y / 2.0 + 0.15, 0)
	body.add_child(roof)

	# AC units on roof (for buildings > 10m)
	if size.y > 10:
		for ai in range(randi() % 3 + 1):
			var ac = MeshInstance3D.new()
			var acm = BoxMesh.new()
			acm.size = Vector3(1.8, 0.9, 1.2)
			acm.material = _make_mat(Color(0.55, 0.55, 0.58), 0.6, 0.3)
			ac.mesh = acm
			ac.position = Vector3(randf_range(-size.x / 3.0, size.x / 3.0), size.y / 2.0 + 0.6, randf_range(-size.z / 3.0, size.z / 3.0))
			body.add_child(ac)

	# Water tower on tall buildings (> 25m)
	if size.y > 25 and randf() < 0.4:
		var wt_pos = Vector3(randf_range(-size.x / 4.0, size.x / 4.0), size.y / 2.0, randf_range(-size.z / 4.0, size.z / 4.0))
		# Legs
		for lx in [-1, 1]:
			for lz in [-1, 1]:
				var leg = MeshInstance3D.new()
				var lgm = CylinderMesh.new()
				lgm.height = 2.5
				lgm.top_radius = 0.06
				lgm.bottom_radius = 0.08
				lgm.material = _make_mat(Color(0.35, 0.35, 0.35), 0.6, 0.5)
				leg.mesh = lgm
				leg.position = wt_pos + Vector3(lx * 0.8, 1.25, lz * 0.8)
				body.add_child(leg)
		# Tank
		var tank = MeshInstance3D.new()
		var tnkm = CylinderMesh.new()
		tnkm.top_radius = 1.2
		tnkm.bottom_radius = 1.0
		tnkm.height = 2.0
		tnkm.material = _make_mat(Color(0.4, 0.38, 0.35), 0.7, 0.2)
		tank.mesh = tnkm
		tank.position = wt_pos + Vector3(0, 3.5, 0)
		body.add_child(tank)
		# Cone roof on water tower
		var cone = MeshInstance3D.new()
		var cnm = CylinderMesh.new()
		cnm.top_radius = 0.1
		cnm.bottom_radius = 1.3
		cnm.height = 0.8
		cnm.material = _make_mat(Color(0.35, 0.33, 0.3), 0.8)
		cone.mesh = cnm
		cone.position = wt_pos + Vector3(0, 4.9, 0)
		body.add_child(cone)

	# Antenna on very tall buildings
	if size.y > 40 and randf() < 0.5:
		var antenna = MeshInstance3D.new()
		var anm = CylinderMesh.new()
		anm.top_radius = 0.03
		anm.bottom_radius = 0.06
		anm.height = 8.0
		anm.material = _make_mat(Color(0.6, 0.6, 0.6), 0.4, 0.7)
		antenna.mesh = anm
		antenna.position = Vector3(0, size.y / 2.0 + 4.0, 0)
		body.add_child(antenna)
		# Red aviation light
		var av_light = MeshInstance3D.new()
		var avm = SphereMesh.new()
		avm.radius = 0.12
		var avl_mat = StandardMaterial3D.new()
		avl_mat.albedo_color = Color(1.0, 0.1, 0.1)
		avl_mat.emission_enabled = true
		avl_mat.emission = Color(1.0, 0.0, 0.0)
		avl_mat.emission_energy_multiplier = 1.2
		avm.material = avl_mat
		av_light.mesh = avm
		av_light.position = Vector3(0, size.y / 2.0 + 8.0, 0)
		body.add_child(av_light)

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
		["TATTOO PARLOR", Vector3(100, 0, 55), Color(0.3, 0.1, 0.3), Color(0.6, 0.2, 0.8)],
		["BARBER SHOP", Vector3(-100, 0, 55), Color(0.2, 0.4, 0.6), Color(0.3, 0.5, 0.8)],
		["PIZZA STACK", Vector3(100, 0, -55), Color(0.7, 0.3, 0.1), Color(0.9, 0.4, 0.1)],
		["ZERO RC", Vector3(-100, 0, -55), Color(0.4, 0.6, 0.2), Color(0.5, 0.8, 0.3)],
		["GYM", Vector3(140, 0, 12), Color(0.5, 0.5, 0.5), Color(0.8, 0.7, 0.1)],
		["CASINO", Vector3(-140, 0, 12), Color(0.15, 0.1, 0.3), Color(0.9, 0.7, 0.2)],
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
	for i in range(180):
		var x = randf_range(-550, 550)
		var z = randf_range(-550, 550)
		if abs(fmod(x, 50.0)) < 6.0 or abs(fmod(z, 50.0)) < 6.0:
			continue
		if abs(x) < 15 and abs(z) < 15:
			continue
		# Skip beach area — palms there
		if z > 115:
			continue
		# Mix in some palms inland too for Vice City look
		if randf() < 0.25:
			_add_palm_tree(Vector3(x, 0, z))
		else:
			_add_tree(Vector3(x, 0, z))

func _add_tree(pos: Vector3):
	# Try GLB first (Kenney Nature Kit trees); fall back to procedural.
	# Use any tree_* GLB except palms (palms handled by _add_palm_tree).
	var glb := AssetLoader.pick_random_filtered("nature", "tree_")
	if glb and String(glb.resource_path).find("palm") >= 0:
		glb = null  # don't double-up palms here
	if glb:
		var inst = glb.instantiate()
		inst.position = pos
		inst.scale = Vector3.ONE * randf_range(1.4, 2.2)
		inst.rotation.y = randf_range(0, TAU)
		add_child(inst)
		return
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
	for i in range(-8, 9):
		for j in range(-8, 9):
			if (i + j) % 5 == 0:
				light_positions.append(Vector3(i * 50 + 4.8, 0, j * 50 + 4.8))

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
		Vector3(8, 0, 5), Vector3(-8, 0, 5), Vector3(8, 0, -5), Vector3(-8, 0, -5),
		Vector3(50, 0, 12), Vector3(-50, 0, -12), Vector3(100, 0, 50), Vector3(-100, 0, -50),
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
	var positions = [Vector3(50, 0, 8), Vector3(-50, 0, -8), Vector3(100, 0, 8)]
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
	# White dashed lane lines on each road
	for i in range(-8, 9):
		# N-S roads: dashes every 8 units
		for j in range(-25, 26):
			var mi = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.15, 0.02, 3.0)
			bm.material = dash_mat
			mi.mesh = bm
			mi.position = Vector3(float(i) * 50, 0.18, float(j) * 8.0)
			add_child(mi)
		# E-W roads: dashes every 8 units
		for j in range(-25, 26):
			var mi = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(3.0, 0.02, 0.15)
			bm.material = dash_mat
			mi.mesh = bm
			mi.position = Vector3(float(j) * 8.0, 0.18, float(i) * 50)
			add_child(mi)

# ═══════════════════════ CROSSWALKS ═══════════════════════
func create_crosswalks():
	var cw_mat = _make_mat(Color(0.9, 0.9, 0.9, 0.8))
	# At every 3rd intersection
	for ix in range(-8, 9):
		for iz in range(-8, 9):
			if (ix + iz) % 3 != 0:
				continue
			var center = Vector3(ix * 50.0, 0.19, iz * 50.0)
			for stripe in range(4):
				var mi = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(6.0, 0.01, 0.55)
				bm.material = cw_mat
				mi.mesh = bm
				mi.position = center + Vector3(0, 0, 5.0 + stripe * 1.5)
				add_child(mi)
			for stripe in range(4):
				var mi = MeshInstance3D.new()
				var bm = BoxMesh.new()
				bm.size = Vector3(0.55, 0.01, 6.0)
				bm.material = cw_mat
				mi.mesh = bm
				mi.position = center + Vector3(5.0 + stripe * 1.5, 0, 0)
				add_child(mi)

# ═══════════════════════ OCEAN & BEACH ═══════════════════════
func create_ocean_and_beach():
	# Large ocean on the south side of the map
	var ocean = MeshInstance3D.new()
	var om = PlaneMesh.new()
	om.size = Vector2(1000, 250)
	var ocean_mat = StandardMaterial3D.new()
	ocean_mat.albedo_color = Color(0.04, 0.18, 0.42, 0.88)
	ocean_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ocean_mat.roughness = 0.02
	ocean_mat.metallic = 0.15
	om.material = ocean_mat
	ocean.mesh = om
	ocean.position = Vector3(0, -0.1, 260)
	add_child(ocean)

	# Beach sand strip
	var sand = MeshInstance3D.new()
	var sandm = BoxMesh.new()
	sandm.size = Vector3(600, 0.2, 50)
	sandm.material = _make_mat(Color(0.92, 0.85, 0.65), 0.95)
	sand.mesh = sandm
	sand.position = Vector3(0, 0.05, 165)
	add_child(sand)

	# Palm trees along beach
	for i in range(20):
		var px = randf_range(-220, 220)
		_add_palm_tree(Vector3(px, 0, 145 + randf_range(0, 30)))

	# Beach umbrellas
	var umbrella_colors = [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.9, 0.8, 0.2), Color(0.2, 0.8, 0.3), Color(0.9, 0.5, 0.1)]
	for i in range(8):
		var ux = randf_range(-100, 100)
		var uz = 125 + randf_range(0, 18)
		var pole = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 2.5
		pm.top_radius = 0.04
		pm.bottom_radius = 0.05
		pm.material = _make_mat(Color(0.45, 0.35, 0.2))
		pole.mesh = pm
		pole.position = Vector3(ux, 1.35, uz)
		add_child(pole)
		var top = MeshInstance3D.new()
		var tm = CylinderMesh.new()
		tm.top_radius = 0.1
		tm.bottom_radius = 1.8
		tm.height = 0.4
		tm.material = _make_mat(umbrella_colors[i % umbrella_colors.size()])
		top.mesh = tm
		top.position = Vector3(ux, 2.7, uz)
		add_child(top)

	# Beach towels (colored flat boxes)
	for i in range(6):
		var towel = MeshInstance3D.new()
		var twm = BoxMesh.new()
		twm.size = Vector3(1.0, 0.02, 2.0)
		var towel_colors = [Color(0.9, 0.3, 0.3), Color(0.3, 0.3, 0.9), Color(0.3, 0.9, 0.3), Color(0.9, 0.9, 0.3)]
		twm.material = _make_mat(towel_colors[i % towel_colors.size()])
		towel.mesh = twm
		towel.position = Vector3(randf_range(-80, 80), 0.16, 130 + randf_range(0, 12))
		towel.rotation.y = randf_range(0, TAU)
		add_child(towel)

	# Lifeguard tower on beach
	_add_lifeguard_tower(Vector3(30, 0, 140))
	_add_lifeguard_tower(Vector3(-60, 0, 140))

func _add_palm_tree(pos: Vector3):
	# Try GLB first (Kenney Nature Kit palms); fall back to procedural
	var glb = AssetLoader.pick_random_filtered("nature", "palm")
	if glb:
		var inst = glb.instantiate()
		inst.position = pos
		inst.scale = Vector3.ONE * randf_range(1.6, 2.4)
		inst.rotation.y = randf_range(0, TAU)
		add_child(inst)
		return
	var tree = Node3D.new()
	tree.position = pos
	var trunk_h = randf_range(7, 12)
	# Curved trunk made of stacked tapered cylinder segments for an organic Vice City silhouette
	var segments = 6
	var curve_dir = Vector3(randf_range(-0.18, 0.18), 0, randf_range(-0.18, 0.18))
	var accumulated = Vector3.ZERO
	var prev_y = 0.0
	for s in range(segments):
		var seg_h = trunk_h / float(segments)
		var seg = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		var t_top = float(s + 1) / float(segments)
		var t_bot = float(s) / float(segments)
		sm.top_radius = lerp(0.28, 0.13, t_top)
		sm.bottom_radius = lerp(0.28, 0.13, t_bot)
		sm.height = seg_h
		sm.material = _make_mat(Color(0.42 + randf() * 0.08, 0.30, 0.18))
		seg.mesh = sm
		# Curve outward as we go up
		var lateral = curve_dir * pow(t_bot, 1.4) * 0.6
		accumulated = lateral
		seg.position = Vector3(accumulated.x, prev_y + seg_h * 0.5, accumulated.z)
		prev_y += seg_h
		tree.add_child(seg)
	var top_pos = Vector3(accumulated.x, trunk_h, accumulated.z)
	# Coconuts cluster at top
	for c in range(randi_range(2, 5)):
		var coco = MeshInstance3D.new()
		var com = SphereMesh.new()
		com.radius = 0.16
		com.height = 0.32
		com.material = _make_mat(Color(0.28, 0.18, 0.10))
		coco.mesh = com
		var ang = randf() * TAU
		coco.position = top_pos + Vector3(cos(ang) * 0.35, -0.15, sin(ang) * 0.35)
		tree.add_child(coco)
	# Palm fronds — drooping curved fronds (multi-segment per frond)
	var frond_count = randi_range(7, 10)
	for f in range(frond_count):
		var base_ang = (float(f) / frond_count) * TAU
		var droop = randf_range(-0.55, -0.25)
		# Frond is 3 stacked elongated boxes that curve down
		var segs_per_frond = 3
		var last_pos = top_pos + Vector3(0, 0.1, 0)
		var last_dir = Vector3(cos(base_ang), 0.05, sin(base_ang))
		for fs in range(segs_per_frond):
			var seg = MeshInstance3D.new()
			var fmesh = BoxMesh.new()
			var seg_len = 1.4 - fs * 0.25
			fmesh.size = Vector3(0.45 - fs * 0.05, 0.04, seg_len)
			var leaf = Color(0.10 + randf() * 0.06, 0.50 + randf() * 0.15, 0.12 + randf() * 0.05)
			fmesh.material = _make_mat(leaf)
			seg.mesh = fmesh
			last_dir.y += droop * 0.4
			last_dir = last_dir.normalized()
			var mid = last_pos + last_dir * (seg_len * 0.5)
			seg.position = mid
			seg.look_at(seg.position + last_dir, Vector3.UP)
			tree.add_child(seg)
			last_pos = last_pos + last_dir * seg_len
	add_child(tree)

func _add_lifeguard_tower(pos: Vector3):
	var tower = Node3D.new()
	tower.position = pos
	for lx in [-1, 1]:
		for lz in [-1, 1]:
			var leg = MeshInstance3D.new()
			var lm = CylinderMesh.new()
			lm.height = 3.0
			lm.top_radius = 0.08
			lm.bottom_radius = 0.1
			lm.material = _make_mat(Color(0.75, 0.55, 0.35))
			leg.mesh = lm
			leg.position = Vector3(lx * 1.2, 1.5, lz * 1.2)
			tower.add_child(leg)
	var platform = MeshInstance3D.new()
	var pfm = BoxMesh.new()
	pfm.size = Vector3(3, 0.15, 3)
	pfm.material = _make_mat(Color(0.75, 0.55, 0.35))
	platform.mesh = pfm
	platform.position.y = 3.1
	tower.add_child(platform)
	var cabin = MeshInstance3D.new()
	var cbm = BoxMesh.new()
	cbm.size = Vector3(2.8, 2.2, 2.8)
	cbm.material = _make_mat(Color(0.85, 0.75, 0.6))
	cabin.mesh = cbm
	cabin.position.y = 4.3
	tower.add_child(cabin)
	var stripe = MeshInstance3D.new()
	var stm = BoxMesh.new()
	stm.size = Vector3(2.9, 0.4, 0.08)
	stm.material = _make_mat(Color(0.9, 0.15, 0.1))
	stripe.mesh = stm
	stripe.position = Vector3(0, 4.5, 1.45)
	tower.add_child(stripe)
	add_child(tower)

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
	_create_highway()
	_create_la_river()
	_create_bridges()
	_create_hollywood_sign()
	_create_la_establishments()
	_create_la_landmarks()

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
	var sw_mat = _make_mat(Color(0.58, 0.56, 0.52), 0.9)
	for i in range(-8, 9):
		for is_ns in [true, false]:
			for side in [-1, 1]:
				var body = StaticBody3D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var sw = MeshInstance3D.new()
				var swm = BoxMesh.new()
				var col = CollisionShape3D.new()
				var box = BoxShape3D.new()
				if is_ns:
					swm.size = Vector3(2.0, 0.18, 1200)
					box.size = Vector3(2.0, 0.18, 1200)
					body.position = Vector3(i * 50 + side * 5.5, 0.09, 0)
				else:
					swm.size = Vector3(1200, 0.18, 2.0)
					box.size = Vector3(1200, 0.18, 2.0)
					body.position = Vector3(0, 0.09, i * 50 + side * 5.5)
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
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 100.0
	# Vice City warm golden sunlight
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-25), 0)
	add_child(sun)
	
	# Warm fill light (Vice City pink bounce)
	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_energy = 0.3
	fill.light_color = Color(0.95, 0.75, 0.85)
	fill.shadow_enabled = false
	fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(120), 0)
	add_child(fill)

# ═══════════════════ NEON SIGNS (Vice City vibe) ═══════════════════
func create_neon_signs():
	# Glowing neon strips and signs scattered around city for that synthwave Vice City feel
	var neon_palette = [
		Color(1.0, 0.2, 0.7),    # Hot pink
		Color(0.2, 0.95, 1.0),   # Cyan
		Color(1.0, 0.5, 0.0),    # Orange
		Color(0.6, 0.2, 1.0),    # Purple
		Color(0.2, 1.0, 0.4),    # Green
		Color(1.0, 0.95, 0.2),   # Yellow
	]
	var sign_words = ["NEON", "BAR", "HOTEL", "CASINO", "DINER", "CLUB", "MOTEL", "PIZZA", "GROOVE", "DISCO", "ROXY", "MALIBU"]
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Place ~50 neon signs along sidewalks of the city grid
	var placed = 0
	var tries = 0
	while placed < 60 and tries < 400:
		tries += 1
		var bx = rng.randi_range(-9, 9)
		var bz = rng.randi_range(-9, 9)
		if abs(bx) <= 1 and abs(bz) <= 1:
			continue
		if bz > 5:  # Skip ocean
			continue
		# Place at building corner near road
		var corner_x = bx * 50.0 + rng.randf_range(-15.0, 15.0)
		var corner_z = bz * 50.0 + rng.randf_range(-15.0, 15.0)
		# Don't overlap road strip
		if abs(fmod(corner_x + 600.0, 50.0) - 25.0) > 18.0 or abs(fmod(corner_z + 600.0, 50.0) - 25.0) > 18.0:
			pass
		var col = neon_palette[rng.randi() % neon_palette.size()]
		var word = sign_words[rng.randi() % sign_words.size()]
		_add_neon_sign(Vector3(corner_x, rng.randf_range(4.0, 12.0), corner_z), col, word)
		placed += 1

	# Also dot some neon trim along main boulevard
	for i in range(-10, 11, 2):
		var col = neon_palette[abs(i) % neon_palette.size()]
		_add_neon_strip(Vector3(7.0, 6.5, i * 50.0), Vector3(0.3, 0.3, 4.0), col)
		_add_neon_strip(Vector3(-7.0, 6.5, i * 50.0), Vector3(0.3, 0.3, 4.0), col)
		_add_neon_strip(Vector3(i * 50.0, 6.5, 7.0), Vector3(4.0, 0.3, 0.3), col)
		_add_neon_strip(Vector3(i * 50.0, 6.5, -7.0), Vector3(4.0, 0.3, 0.3), col)

func _add_neon_strip(pos: Vector3, size: Vector3, color: Color):
	var strip = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.metallic = 0.0
	mat.roughness = 0.4
	sm.material = mat
	strip.mesh = sm
	strip.position = pos
	add_child(strip)
	# Tiny omni light to throw color on nearby surfaces
	var lt = OmniLight3D.new()
	lt.light_color = color
	lt.light_energy = 0.6
	lt.omni_range = 6.0
	lt.position = pos
	add_child(lt)

func _add_neon_sign(pos: Vector3, color: Color, word: String):
	# Backplate
	var back = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(3.2, 1.4, 0.18)
	bm.material = _make_mat(Color(0.1, 0.08, 0.10), 0.85)
	back.mesh = bm
	back.position = pos
	add_child(back)
	# Glowing letters strip
	var letters = MeshInstance3D.new()
	var lm = BoxMesh.new()
	lm.size = Vector3(2.8, 0.9, 0.05)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 6.0
	lm.material = mat
	letters.mesh = lm
	letters.position = pos + Vector3(0, 0, 0.12)
	add_child(letters)
	# Word label (3D text would be ideal but use Label3D for simplicity)
	var label = Label3D.new()
	label.text = word
	label.font_size = 64
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	label.position = pos + Vector3(0, 0, 0.16)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.pixel_size = 0.012
	add_child(label)
	# Neon spill light
	var lt = OmniLight3D.new()
	lt.light_color = color
	lt.light_energy = 1.4
	lt.omni_range = 12.0
	lt.position = pos + Vector3(0, 0, 1.0)
	add_child(lt)

func setup_sky():
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var proc_sky = ProceduralSkyMaterial.new()
	# Vice City sunset palette — warm pinks, oranges, deep blue
	proc_sky.sky_top_color = Color(0.12, 0.18, 0.55)
	proc_sky.sky_horizon_color = Color(0.95, 0.55, 0.45)
	proc_sky.ground_bottom_color = Color(0.15, 0.38, 0.18)
	proc_sky.ground_horizon_color = Color(0.75, 0.50, 0.45)
	proc_sky.sun_angle_max = 35.0
	proc_sky.sun_curve = 0.08
	sky.sky_material = proc_sky
	env.sky = sky

	# Warm ambient lighting — Vice City golden hour feel
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.ambient_light_sky_contribution = 1.0

	# Tone mapping — punchy, saturated Vice City look
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1

	# Glow/bloom for neon signs and sunset
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Warm atmospheric fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.65, 0.55)
	env.fog_density = 0.0003
	env.fog_aerial_perspective = 0.35

	env.ssao_enabled = false

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
	# ═══ KENNEY GLB PATH ═══
	var glb := AssetLoader.pick_random_any("vehicle")
	if glb != null:
		var inst = glb.instantiate()
		inst.position = pos
		inst.rotation.y = randf_range(-0.1, 0.1) + (PI if randf() > 0.5 else 0)
		add_child(inst)
		return
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

# ═══════════════════════ HIGHWAY / FREEWAY ═══════════════════════
func _create_highway():
	# Elevated freeway loop around downtown (like LA's 110/101 interchange area)
	# The freeway runs in a rectangular loop at ~120m from center, elevated 6m
	var hw_mat = _make_mat(Color(0.22, 0.22, 0.24), 0.85)
	var barrier_mat = _make_mat(Color(0.55, 0.55, 0.55), 0.7, 0.2)
	var pillar_mat = _make_mat(Color(0.5, 0.5, 0.52), 0.7, 0.1)
	var hw_y = 6.0
	var hw_width = 8.0
	var half_len = 180.0

	# Four straight highway segments (N, S, E, W sides)
	var segments = [
		# [position, size, barrier_offset_axis]
		[Vector3(0, hw_y, -half_len), Vector3(hw_width, 0.4, half_len * 2), "z"],
		[Vector3(0, hw_y, half_len), Vector3(hw_width, 0.4, half_len * 2), "z"],
		[Vector3(-half_len, hw_y, 0), Vector3(half_len * 2, 0.4, hw_width), "x"],
		[Vector3(half_len, hw_y, 0), Vector3(half_len * 2, 0.4, hw_width), "x"],
	]

	# North side highway
	var hw_n = StaticBody3D.new()
	hw_n.position = Vector3(0, hw_y, -half_len)
	var hw_n_mesh = MeshInstance3D.new()
	var hw_n_box = BoxMesh.new()
	hw_n_box.size = Vector3(half_len * 2, 0.4, hw_width)
	hw_n_box.material = hw_mat
	hw_n_mesh.mesh = hw_n_box
	hw_n.add_child(hw_n_mesh)
	var hw_n_col = CollisionShape3D.new()
	hw_n_col.shape = BoxShape3D.new()
	hw_n_col.shape.size = Vector3(half_len * 2, 0.4, hw_width)
	hw_n.add_child(hw_n_col)
	add_child(hw_n)

	# South side highway
	var hw_s = StaticBody3D.new()
	hw_s.position = Vector3(0, hw_y, half_len - 40)
	var hw_s_mesh = MeshInstance3D.new()
	var hw_s_box = BoxMesh.new()
	hw_s_box.size = Vector3(half_len * 2, 0.4, hw_width)
	hw_s_box.material = hw_mat
	hw_s_mesh.mesh = hw_s_box
	hw_s.add_child(hw_s_mesh)
	var hw_s_col = CollisionShape3D.new()
	hw_s_col.shape = BoxShape3D.new()
	hw_s_col.shape.size = Vector3(half_len * 2, 0.4, hw_width)
	hw_s.add_child(hw_s_col)
	add_child(hw_s)

	# East side highway
	var hw_e = StaticBody3D.new()
	hw_e.position = Vector3(half_len, hw_y, -20)
	var hw_e_mesh = MeshInstance3D.new()
	var hw_e_box = BoxMesh.new()
	hw_e_box.size = Vector3(hw_width, 0.4, half_len * 2 - 40)
	hw_e_box.material = hw_mat
	hw_e_mesh.mesh = hw_e_box
	hw_e.add_child(hw_e_mesh)
	var hw_e_col = CollisionShape3D.new()
	hw_e_col.shape = BoxShape3D.new()
	hw_e_col.shape.size = Vector3(hw_width, 0.4, half_len * 2 - 40)
	hw_e.add_child(hw_e_col)
	add_child(hw_e)

	# West side highway
	var hw_w = StaticBody3D.new()
	hw_w.position = Vector3(-half_len, hw_y, -20)
	var hw_w_mesh = MeshInstance3D.new()
	var hw_w_box = BoxMesh.new()
	hw_w_box.size = Vector3(hw_width, 0.4, half_len * 2 - 40)
	hw_w_box.material = hw_mat
	hw_w_mesh.mesh = hw_w_box
	hw_w.add_child(hw_w_mesh)
	var hw_w_col = CollisionShape3D.new()
	hw_w_col.shape = BoxShape3D.new()
	hw_w_col.shape.size = Vector3(hw_width, 0.4, half_len * 2 - 40)
	hw_w.add_child(hw_w_col)
	add_child(hw_w)

	# Highway support pillars
	for i in range(-8, 9):
		for side_pos in [-half_len, half_len]:
			# N-S pillars
			var pillar = MeshInstance3D.new()
			var pm = CylinderMesh.new()
			pm.height = hw_y
			pm.top_radius = 0.35
			pm.bottom_radius = 0.45
			pm.material = pillar_mat
			pillar.mesh = pm
			pillar.position = Vector3(i * 40, hw_y / 2.0, side_pos)
			add_child(pillar)
		for side_pos in [-half_len, half_len]:
			# E-W pillars
			var pillar = MeshInstance3D.new()
			var pm = CylinderMesh.new()
			pm.height = hw_y
			pm.top_radius = 0.35
			pm.bottom_radius = 0.45
			pm.material = pillar_mat
			pillar.mesh = pm
			pillar.position = Vector3(side_pos, hw_y / 2.0, i * 40 - 20)
			add_child(pillar)

	# Highway barrier walls (concrete jersey barriers)
	for z_off in [-half_len]:
		for side in [-1, 1]:
			var barrier = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(half_len * 2, 0.8, 0.3)
			bm.material = barrier_mat
			barrier.mesh = bm
			barrier.position = Vector3(0, hw_y + 0.6, z_off + side * (hw_width / 2.0))
			add_child(barrier)

	# On/off ramps (sloped sections connecting ground to highway)
	_add_highway_ramp(Vector3(-100, 0, -half_len), Vector3(-100, hw_y, -half_len), 0.0)
	_add_highway_ramp(Vector3(100, 0, -half_len), Vector3(100, hw_y, -half_len), PI)
	_add_highway_ramp(Vector3(-half_len, 0, -80), Vector3(-half_len, hw_y, -80), PI / 2)
	_add_highway_ramp(Vector3(half_len, 0, -80), Vector3(half_len, hw_y, -80), -PI / 2)

	# Highway lane markings (white dashes on elevated road)
	var dash_mat = _make_mat(Color(0.95, 0.95, 0.95))
	for i in range(-16, 17, 2):
		var dm = MeshInstance3D.new()
		var dbm = BoxMesh.new()
		dbm.size = Vector3(2.0, 0.02, 0.12)
		dbm.material = dash_mat
		dm.mesh = dbm
		dm.position = Vector3(i * 10.0, hw_y + 0.22, -half_len)
		add_child(dm)

func _add_highway_ramp(ground_pos: Vector3, hw_pos: Vector3, rot_y: float):
	# Sloped ramp connecting ground level to highway
	var ramp = StaticBody3D.new()
	var mid = (ground_pos + hw_pos) / 2.0
	mid.y = (ground_pos.y + hw_pos.y) / 2.0
	ramp.position = mid

	var ramp_len = ground_pos.distance_to(hw_pos) + 30.0
	var mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(6.0, 0.3, ramp_len)
	bm.material = _make_mat(Color(0.22, 0.22, 0.24), 0.85)
	mesh.mesh = bm
	ramp.add_child(mesh)

	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(6.0, 0.3, ramp_len)
	ramp.add_child(col)

	# Angle the ramp upward
	var angle = atan2(hw_pos.y - ground_pos.y, ramp_len)
	ramp.rotation.x = -angle
	ramp.rotation.y = rot_y
	add_child(ramp)

# ═══════════════════════ LA RIVER (CONCRETE CHANNEL) ═══════════════════════
func _create_la_river():
	# LA River: concrete channel running north-south at x = 110
	var river_x = 110.0
	var river_len = 800.0
	var channel_width = 14.0
	var channel_depth = 4.0
	var concrete = _make_mat(Color(0.55, 0.53, 0.50), 0.9)
	var water_level = -2.5

	# Channel floor
	var floor_body = StaticBody3D.new()
	floor_body.position = Vector3(river_x, -channel_depth, 0)
	var floor_mesh = MeshInstance3D.new()
	var fbm = BoxMesh.new()
	fbm.size = Vector3(channel_width - 1, 0.3, river_len)
	fbm.material = concrete
	floor_mesh.mesh = fbm
	floor_body.add_child(floor_mesh)
	var floor_col = CollisionShape3D.new()
	floor_col.shape = BoxShape3D.new()
	floor_col.shape.size = Vector3(channel_width - 1, 0.3, river_len)
	floor_body.add_child(floor_col)
	add_child(floor_body)

	# Channel walls (both sides)
	for side in [-1, 1]:
		var wall = StaticBody3D.new()
		wall.position = Vector3(river_x + side * channel_width / 2.0, -channel_depth / 2.0, 0)
		var wm = MeshInstance3D.new()
		var wbm = BoxMesh.new()
		wbm.size = Vector3(0.5, channel_depth + 0.5, river_len)
		wbm.material = concrete
		wm.mesh = wbm
		wall.add_child(wm)
		var wcol = CollisionShape3D.new()
		wcol.shape = BoxShape3D.new()
		wcol.shape.size = Vector3(0.5, channel_depth + 0.5, river_len)
		wall.add_child(wcol)
		add_child(wall)

	# Sloped embankments
	for side in [-1, 1]:
		var slope = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(3.0, 0.3, river_len)
		sm.material = concrete
		slope.mesh = sm
		slope.position = Vector3(river_x + side * (channel_width / 2.0 + 1.5), -channel_depth / 2.0, 0)
		slope.rotation.z = side * 0.5
		add_child(slope)

	# Water in channel
	var water = MeshInstance3D.new()
	var wpm = BoxMesh.new()
	wpm.size = Vector3(channel_width - 2, 0.1, river_len)
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.15, 0.30, 0.42, 0.75)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.02
	wpm.material = water_mat
	water.mesh = wpm
	water.position = Vector3(river_x, water_level, 0)
	add_child(water)

	# Chain-link fence along the top of the channel
	for side in [-1, 1]:
		var fence = MeshInstance3D.new()
		var fm = BoxMesh.new()
		fm.size = Vector3(0.05, 2.0, river_len)
		var fence_mat = StandardMaterial3D.new()
		fence_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
		fence_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fence_mat.roughness = 0.4
		fence_mat.metallic = 0.6
		fm.material = fence_mat
		fence.mesh = fm
		fence.position = Vector3(river_x + side * (channel_width / 2.0 + 0.3), 1.0, 0)
		add_child(fence)

# ═══════════════════════ BRIDGES ═══════════════════════
func _create_bridges():
	# Bridges crossing the LA River at major road intersections
	var river_x = 110.0
	var bridge_roads = [-66.0, 0.0, 66.0, 132.0]  # Z positions of E-W roads crossing the river

	for bz in bridge_roads:
		_add_bridge(Vector3(river_x, 0, bz))

func _add_bridge(pos: Vector3):
	var bridge = StaticBody3D.new()
	bridge.position = pos + Vector3(0, 0.5, 0)

	# Bridge deck
	var deck = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(22.0, 0.5, 8.0)
	dm.material = _make_mat(Color(0.25, 0.25, 0.27), 0.8)
	deck.mesh = dm
	bridge.add_child(deck)

	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(22.0, 0.5, 8.0)
	bridge.add_child(col)

	# Bridge railings
	for side in [-1, 1]:
		var railing = MeshInstance3D.new()
		var rm = BoxMesh.new()
		rm.size = Vector3(22.0, 1.2, 0.15)
		rm.material = _make_mat(Color(0.45, 0.45, 0.45), 0.6, 0.4)
		railing.mesh = rm
		railing.position = Vector3(0, 0.85, side * 3.9)
		bridge.add_child(railing)

	# Support pillars
	for px in [-8, 0, 8]:
		var pillar = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 5.0
		pm.top_radius = 0.4
		pm.bottom_radius = 0.5
		pm.material = _make_mat(Color(0.5, 0.48, 0.46), 0.7, 0.1)
		pillar.mesh = pm
		pillar.position = Vector3(px, -2.25, 0)
		bridge.add_child(pillar)

	add_child(bridge)

# ═══════════════════════ HOLLYWOOD SIGN ═══════════════════════
func _create_hollywood_sign():
	# Iconic HOLLYWOOD sign on a hillside in the northwest — realistic letter shapes
	var base = Vector3(-200, 0, -200)

	# Multi-layered hillside terrain
	var hill = StaticBody3D.new()
	hill.position = base
	# Main hill body
	var hill_mesh = MeshInstance3D.new()
	var hm = CylinderMesh.new()
	hm.top_radius = 40.0
	hm.bottom_radius = 65.0
	hm.height = 22.0
	hm.material = _make_mat(Color(0.32, 0.48, 0.24), 0.9)
	hill_mesh.mesh = hm
	hill_mesh.position.y = 11.0
	hill.add_child(hill_mesh)
	# Secondary hill ridge
	var ridge = MeshInstance3D.new()
	var rdm = CylinderMesh.new()
	rdm.top_radius = 25.0
	rdm.bottom_radius = 35.0
	rdm.height = 8.0
	rdm.material = _make_mat(Color(0.35, 0.50, 0.26), 0.9)
	ridge.mesh = rdm
	ridge.position = Vector3(5, 25.0, -5)
	hill.add_child(ridge)
	# Hill collision
	var hill_col = CollisionShape3D.new()
	hill_col.shape = CylinderShape3D.new()
	hill_col.shape.radius = 55.0
	hill_col.shape.height = 22.0
	hill_col.position.y = 11.0
	hill.add_child(hill_col)
	add_child(hill)

	# Scrub bushes on hillside
	var bush_mat = _make_mat(Color(0.28, 0.42, 0.2), 0.9)
	var dark_bush = _make_mat(Color(0.22, 0.36, 0.16), 0.9)
	for bi in range(25):
		var bush = MeshInstance3D.new()
		var bsm = SphereMesh.new()
		bsm.radius = randf_range(1.0, 3.0)
		bsm.height = randf_range(1.5, 4.0)
		bsm.material = bush_mat if bi % 2 == 0 else dark_bush
		bush.mesh = bsm
		var angle = randf_range(0, TAU)
		var dist = randf_range(10, 45)
		bush.position = base + Vector3(cos(angle) * dist, randf_range(2, 18), sin(angle) * dist)
		add_child(bush)

	# Letter material — bright white with glow for distance visibility
	var letter_mat = StandardMaterial3D.new()
	letter_mat.albedo_color = Color(0.97, 0.97, 0.97)
	letter_mat.emission_enabled = true
	letter_mat.emission = Color(1.0, 1.0, 1.0)
	letter_mat.emission_energy_multiplier = 0.25
	letter_mat.roughness = 0.4

	# Steel support material
	var steel_mat = _make_mat(Color(0.45, 0.45, 0.47), 0.6, 0.5)

	# HOLLYWOOD letters — each built from BoxMesh pieces to form letter shapes
	# Letter dimensions: ~7m tall, ~4.5m wide, 0.4m thick
	var lh = 7.0   # letter height
	var lw = 4.5   # letter width
	var lt = 0.4   # letter thickness
	var bar = 1.2   # bar width (stroke)
	var sign_y = 24.0
	var sign_z = -18.0
	var rot_y = 0.3  # angle to face city
	var spacing = 5.5
	var start_x = -22.0

	# Helper: adds one box piece of a letter
	var _add_letter_piece = func(lx: float, pieces: Array):
		for p in pieces:
			var piece = MeshInstance3D.new()
			var pm = BoxMesh.new()
			pm.size = Vector3(p[3], p[4], lt)
			pm.material = letter_mat
			piece.mesh = pm
			piece.position = base + Vector3(start_x + lx + p[0], sign_y + p[1], sign_z + p[2])
			piece.rotation.y = rot_y
			add_child(piece)
			# Support pole behind each piece
			var pole = MeshInstance3D.new()
			var plm = CylinderMesh.new()
			plm.height = sign_y - 2.0
			plm.top_radius = 0.08
			plm.bottom_radius = 0.1
			plm.material = steel_mat
			pole.mesh = plm
			pole.position = base + Vector3(start_x + lx + p[0], (sign_y - 2.0) / 2.0 + 2.0, sign_z + p[2] - 0.4)
			pole.rotation.y = rot_y
			add_child(pole)

	# H — two vertical bars + horizontal cross bar
	_add_letter_piece.call(0, [
		[0, 0, 0, bar, lh],           # left vertical
		[lw - bar, 0, 0, bar, lh],    # right vertical
		[lw / 2, 0, 0, lw - bar * 2, bar],  # horizontal cross
	])
	# O — four bars forming rectangle (simplified O)
	_add_letter_piece.call(spacing, [
		[0, 0, 0, bar, lh],           # left
		[lw - bar, 0, 0, bar, lh],    # right
		[lw / 2, lh / 2 - bar / 2, 0, lw, bar],  # top
		[lw / 2, -lh / 2 + bar / 2, 0, lw, bar],  # bottom
	])
	# L — vertical bar + bottom horizontal
	_add_letter_piece.call(spacing * 2, [
		[0, 0, 0, bar, lh],           # vertical
		[lw / 2 - bar / 4, -lh / 2 + bar / 2, 0, lw - bar / 2, bar],  # bottom
	])
	# L — same as above
	_add_letter_piece.call(spacing * 3, [
		[0, 0, 0, bar, lh],
		[lw / 2 - bar / 4, -lh / 2 + bar / 2, 0, lw - bar / 2, bar],
	])
	# Y — two angled top arms + vertical bottom
	_add_letter_piece.call(spacing * 4, [
		[lw / 2, -lh / 4, 0, bar, lh / 2],  # bottom vertical
		[bar / 2, lh / 4, 0, bar, lh / 2],   # left arm
		[lw - bar / 2, lh / 4, 0, bar, lh / 2],  # right arm
	])
	# W — three vertical bars + two bottom connectors
	_add_letter_piece.call(spacing * 5, [
		[0, 0, 0, bar, lh],                   # left
		[lw / 2, -lh / 4, 0, bar, lh / 2],   # center bottom
		[lw - bar, 0, 0, bar, lh],            # right
		[lw / 4, -lh / 2 + bar / 2, 0, lw / 2, bar],  # bottom left connect
		[lw * 3 / 4, -lh / 2 + bar / 2, 0, lw / 2, bar],  # bottom right connect
	])
	# O — same as first O
	_add_letter_piece.call(spacing * 6, [
		[0, 0, 0, bar, lh],
		[lw - bar, 0, 0, bar, lh],
		[lw / 2, lh / 2 - bar / 2, 0, lw, bar],
		[lw / 2, -lh / 2 + bar / 2, 0, lw, bar],
	])
	# O — same
	_add_letter_piece.call(spacing * 7, [
		[0, 0, 0, bar, lh],
		[lw - bar, 0, 0, bar, lh],
		[lw / 2, lh / 2 - bar / 2, 0, lw, bar],
		[lw / 2, -lh / 2 + bar / 2, 0, lw, bar],
	])
	# D — vertical bar + curved right side (3 horizontal bars)
	_add_letter_piece.call(spacing * 8, [
		[0, 0, 0, bar, lh],                        # left vertical
		[lw - bar, 0, 0, bar, lh * 0.6],          # right vertical (shorter)
		[lw / 2, lh / 2 - bar / 2, 0, lw - bar, bar],  # top
		[lw / 2, -lh / 2 + bar / 2, 0, lw - bar, bar],  # bottom
		[lw - bar / 2, 0, 0, bar, bar],           # middle right connector
	])

	# Spotlight for night visibility
	var spot = SpotLight3D.new()
	spot.light_color = Color(0.95, 0.92, 0.85)
	spot.light_energy = 2.0
	spot.spot_range = 60.0
	spot.spot_angle = 40.0
	spot.position = base + Vector3(start_x + spacing * 4, sign_y + 15, sign_z + 20)
	spot.rotation.x = -0.6
	add_child(spot)

	# Register zone for overlap prevention
	_register_zone(base.x, base.z, 130, 130)

# ═══════════════════════ LA ESTABLISHMENTS ═══════════════════════
func _create_la_establishments():
	# Bars, strip clubs, nightclubs, pubs, liquor stores, diners, motels, laundromats, pawn shops
	var establishments = [
		["THE WHISKEY BAR", Vector3(-60, 0, 35), Color(0.25, 0.12, 0.08), Color(0.9, 0.7, 0.2), "bar"],
		["VENOM NIGHTCLUB", Vector3(65, 0, -35), Color(0.08, 0.05, 0.15), Color(0.8, 0.1, 0.9), "nightclub"],
		["PARADISE STRIP", Vector3(-35, 0, -60), Color(0.15, 0.05, 0.1), Color(1.0, 0.2, 0.6), "strip_club"],
		["SUNSET PUB", Vector3(40, 0, 65), Color(0.22, 0.15, 0.08), Color(0.85, 0.6, 0.15), "bar"],
		["NEON LOUNGE", Vector3(-85, 0, -25), Color(0.06, 0.06, 0.12), Color(0.2, 0.9, 0.9), "nightclub"],
		["LIQUOR KING", Vector3(90, 0, 25), Color(0.45, 0.35, 0.25), Color(0.9, 0.3, 0.1), "liquor"],
		["LUCKY PAWN", Vector3(-45, 0, 85), Color(0.35, 0.3, 0.25), Color(0.95, 0.85, 0.2), "pawn"],
		["WASH N DRY", Vector3(50, 0, -85), Color(0.7, 0.75, 0.8), Color(0.3, 0.6, 0.9), "laundromat"],
		["STARLIGHT MOTEL", Vector3(-120, 0, 50), Color(0.55, 0.45, 0.4), Color(0.9, 0.5, 0.7), "motel"],
		["MEL'S DINER", Vector3(120, 0, -50), Color(0.85, 0.25, 0.2), Color(0.95, 0.9, 0.5), "diner"],
		["COYOTE CANTINA", Vector3(-75, 0, -75), Color(0.6, 0.35, 0.15), Color(0.2, 0.8, 0.3), "bar"],
		["XXX PEEP SHOW", Vector3(75, 0, 75), Color(0.1, 0.05, 0.08), Color(0.95, 0.1, 0.3), "strip_club"],
	]
	for e in establishments:
		var epos = e[1]
		# Check overlap — shift position if needed (max 5 attempts)
		var placed = false
		for attempt in range(5):
			if _is_zone_free(epos.x, epos.z, 14, 12):
				_register_zone(epos.x, epos.z, 14, 12)
				_add_establishment(e[0], epos, e[2], e[3], e[4])
				placed = true
				break
			epos.x += 15.0  # shift along road
		if not placed:
			# Force place at original position as fallback
			_add_establishment(e[0], e[1], e[2], e[3], e[4])

func _add_establishment(est_name: String, pos: Vector3, wall_color: Color, sign_color: Color, est_type: String):
	var body = StaticBody3D.new()
	var bld_h = 6.0 if est_type != "motel" else 8.0
	body.position = pos + Vector3(0, bld_h / 2.0, 0)

	# Main building
	var main = MeshInstance3D.new()
	var mm = BoxMesh.new()
	mm.size = Vector3(10, bld_h, 8)
	mm.material = _make_mat(wall_color, 0.7)
	main.mesh = mm
	body.add_child(main)

	# Door
	var door = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(1.4, 2.6, 0.06)
	dm.material = _make_mat(Color(0.06, 0.04, 0.03))
	door.mesh = dm
	door.position = Vector3(0, -bld_h / 2.0 + 1.3, 4.03)
	body.add_child(door)

	# Neon sign (glowing)
	var sign_panel = MeshInstance3D.new()
	var spm = BoxMesh.new()
	spm.size = Vector3(8, 1.2, 0.12)
	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = sign_color
	sign_mat.emission_enabled = true
	sign_mat.emission = sign_color
	sign_mat.emission_energy_multiplier = 1.2
	spm.material = sign_mat
	sign_panel.mesh = spm
	sign_panel.position = Vector3(0, bld_h / 2.0 - 0.8, 4.08)
	body.add_child(sign_panel)

	# Type-specific decorations
	match est_type:
		"bar", "nightclub":
			# Bouncer light / spot
			var spot = MeshInstance3D.new()
			var spm2 = CylinderMesh.new()
			spm2.top_radius = 0.08
			spm2.bottom_radius = 0.12
			spm2.height = 0.5
			var spot_mat = StandardMaterial3D.new()
			spot_mat.albedo_color = sign_color
			spot_mat.emission_enabled = true
			spot_mat.emission = sign_color
			spot_mat.emission_energy_multiplier = 0.8
			spm2.material = spot_mat
			spot.mesh = spm2
			spot.position = Vector3(-3.5, -bld_h / 2.0 + 4.0, 4.1)
			body.add_child(spot)
			# Velvet rope posts
			for side in [-1, 1]:
				var post = MeshInstance3D.new()
				var ptm = CylinderMesh.new()
				ptm.top_radius = 0.04
				ptm.bottom_radius = 0.06
				ptm.height = 0.9
				ptm.material = _make_mat(Color(0.7, 0.6, 0.1), 0.3, 0.8)
				post.mesh = ptm
				post.position = Vector3(side * 1.2, -bld_h / 2.0 + 0.45, 5.0)
				body.add_child(post)
			# Rope between posts
			var rope = MeshInstance3D.new()
			var rp = CylinderMesh.new()
			rp.top_radius = 0.02
			rp.bottom_radius = 0.02
			rp.height = 2.4
			rp.material = _make_mat(Color(0.6, 0.05, 0.1))
			rope.mesh = rp
			rope.position = Vector3(0, -bld_h / 2.0 + 0.8, 5.0)
			rope.rotation.z = PI / 2
			body.add_child(rope)

		"strip_club":
			# Neon outline (pink/red tubes around entrance)
			for side in [-1, 1]:
				var tube = MeshInstance3D.new()
				var tbm = CylinderMesh.new()
				tbm.top_radius = 0.04
				tbm.bottom_radius = 0.04
				tbm.height = 3.5
				var neon_mat = StandardMaterial3D.new()
				neon_mat.albedo_color = Color(1.0, 0.1, 0.4)
				neon_mat.emission_enabled = true
				neon_mat.emission = Color(1.0, 0.15, 0.5)
				neon_mat.emission_energy_multiplier = 1.5
				tbm.material = neon_mat
				tube.mesh = tbm
				tube.position = Vector3(side * 2.0, -bld_h / 2.0 + 2.0, 4.08)
				body.add_child(tube)
			# Blacked out windows
			for wx in [-1, 1]:
				var bwin = MeshInstance3D.new()
				var bwm = BoxMesh.new()
				bwm.size = Vector3(2.0, 1.5, 0.06)
				bwm.material = _make_mat(Color(0.03, 0.02, 0.02))
				bwin.mesh = bwm
				bwin.position = Vector3(wx * 3.0, 0, 4.04)
				body.add_child(bwin)

		"liquor":
			# Iron bars on windows
			for wx in [-1, 1]:
				for bar_i in range(4):
					var bar = MeshInstance3D.new()
					var brm = CylinderMesh.new()
					brm.top_radius = 0.015
					brm.bottom_radius = 0.015
					brm.height = 1.8
					brm.material = _make_mat(Color(0.3, 0.3, 0.3), 0.5, 0.7)
					bar.mesh = brm
					bar.position = Vector3(wx * 3.0 - 0.6 + bar_i * 0.4, 0.3, 4.05)
					body.add_child(bar)

		"motel":
			# Second floor balcony/walkway
			var walkway = MeshInstance3D.new()
			var wm = BoxMesh.new()
			wm.size = Vector3(10.5, 0.15, 1.5)
			wm.material = _make_mat(Color(0.5, 0.48, 0.45), 0.8)
			walkway.mesh = wm
			walkway.position = Vector3(0, 0.5, 4.7)
			body.add_child(walkway)
			# Railing
			var railing = MeshInstance3D.new()
			var rlm = BoxMesh.new()
			rlm.size = Vector3(10.5, 0.8, 0.05)
			rlm.material = _make_mat(Color(0.4, 0.35, 0.3), 0.6, 0.4)
			railing.mesh = rlm
			railing.position = Vector3(0, 0.95, 5.4)
			body.add_child(railing)
			# Room doors (second floor)
			for di in range(3):
				var rdoor = MeshInstance3D.new()
				var rdm = BoxMesh.new()
				rdm.size = Vector3(0.9, 2.0, 0.05)
				rdm.material = _make_mat(Color(0.35, 0.25, 0.15))
				rdoor.mesh = rdm
				rdoor.position = Vector3(-3.0 + di * 3.0, 1.5, 4.04)
				body.add_child(rdoor)

		"diner":
			# Large front windows (like a classic diner)
			for wx in [-1, 0, 1]:
				var dwin = MeshInstance3D.new()
				var dwm = BoxMesh.new()
				dwm.size = Vector3(2.5, 2.2, 0.05)
				var gmat = StandardMaterial3D.new()
				gmat.albedo_color = Color(0.8, 0.85, 0.6, 0.5)
				gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				gmat.roughness = 0.05
				gmat.emission_enabled = true
				gmat.emission = Color(0.9, 0.85, 0.6)
				gmat.emission_energy_multiplier = 0.3
				dwm.material = gmat
				dwin.mesh = dwm
				dwin.position = Vector3(wx * 2.8, -0.5, 4.04)
				body.add_child(dwin)
			# Chrome trim
			var chrome_strip = MeshInstance3D.new()
			var csm = BoxMesh.new()
			csm.size = Vector3(10.5, 0.15, 0.08)
			csm.material = _make_mat(Color(0.8, 0.8, 0.82), 0.1, 0.9)
			chrome_strip.mesh = csm
			chrome_strip.position = Vector3(0, -bld_h / 2.0 + 3.5, 4.06)
			body.add_child(chrome_strip)

		"pawn":
			# Barred windows + "OPEN" neon
			var open_sign = MeshInstance3D.new()
			var osm = BoxMesh.new()
			osm.size = Vector3(2.0, 0.6, 0.08)
			var open_mat = StandardMaterial3D.new()
			open_mat.albedo_color = Color(0.1, 0.9, 0.2)
			open_mat.emission_enabled = true
			open_mat.emission = Color(0.1, 1.0, 0.2)
			open_mat.emission_energy_multiplier = 0.8
			osm.material = open_mat
			open_sign.mesh = osm
			open_sign.position = Vector3(2.5, -0.5, 4.06)
			body.add_child(open_sign)

	# Awning over entrance
	var awning = MeshInstance3D.new()
	var awm = BoxMesh.new()
	awm.size = Vector3(10.5, 0.1, 2.0)
	awm.material = _make_mat(sign_color.darkened(0.4), 0.7)
	awning.mesh = awm
	awning.position = Vector3(0, -bld_h / 2.0 + 3.2, 4.8)
	body.add_child(awning)

	# Collision
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(10, bld_h, 8)
	cs.shape = bs
	body.add_child(cs)

	add_child(body)

# ═══════════════════════ LA LANDMARKS ═══════════════════════
func _create_la_landmarks():
	_create_santa_monica_pier()
	_create_venice_beach()
	_create_griffith_observatory()
	_create_walk_of_fame()
	_create_rodeo_drive()
	_create_chinatown()
	_create_lax_control_tower()
	_create_beverly_hills_mansion()
	_create_dodger_stadium_sign()

func _create_santa_monica_pier():
	# Pier extending into ocean from the beach area
	var base = Vector3(0, 0, 160)
	_register_zone(base.x, base.z + 30, 20, 70)
	# Pier deck (wooden planks)
	var pier = StaticBody3D.new()
	pier.position = base + Vector3(0, 1.5, 30)
	var deck = MeshInstance3D.new()
	var dkm = BoxMesh.new()
	dkm.size = Vector3(12, 0.4, 60)
	dkm.material = _make_mat(Color(0.5, 0.35, 0.2), 0.9)
	deck.mesh = dkm
	pier.add_child(deck)
	var dk_col = CollisionShape3D.new()
	dk_col.shape = BoxShape3D.new()
	dk_col.shape.size = Vector3(12, 0.4, 60)
	pier.add_child(dk_col)
	add_child(pier)

	# Pier supports
	for pz in range(6):
		for side in [-1, 1]:
			var pil = MeshInstance3D.new()
			var plm = CylinderMesh.new()
			plm.height = 3.5
			plm.top_radius = 0.2
			plm.bottom_radius = 0.25
			plm.material = _make_mat(Color(0.35, 0.25, 0.15), 0.9)
			pil.mesh = plm
			pil.position = base + Vector3(side * 5, 0.0, 5 + pz * 10)
			add_child(pil)

	# Ferris wheel frame (circular structure)
	var fw_center = base + Vector3(0, 12, 40)
	var fw_radius = 8.0
	# Spokes
	for i in range(12):
		var angle = i * TAU / 12.0
		var spoke = MeshInstance3D.new()
		var skm = CylinderMesh.new()
		skm.top_radius = 0.06
		skm.bottom_radius = 0.06
		skm.height = fw_radius
		skm.material = _make_mat(Color(0.7, 0.1, 0.1), 0.4, 0.6)
		spoke.mesh = skm
		spoke.position = fw_center + Vector3(0, sin(angle) * fw_radius / 2.0, cos(angle) * fw_radius / 2.0)
		spoke.rotation.x = angle
		add_child(spoke)
	# Rim segments
	for i in range(24):
		var angle = i * TAU / 24.0
		var seg = MeshInstance3D.new()
		var sgm = BoxMesh.new()
		sgm.size = Vector3(0.5, 0.1, 2.2)
		sgm.material = _make_mat(Color(0.7, 0.1, 0.1), 0.4, 0.6)
		seg.mesh = sgm
		seg.position = fw_center + Vector3(0, sin(angle) * fw_radius, cos(angle) * fw_radius)
		seg.rotation.x = angle
		add_child(seg)
	# Gondola cars
	for i in range(8):
		var angle = i * TAU / 8.0
		var car = MeshInstance3D.new()
		var crm = BoxMesh.new()
		crm.size = Vector3(0.8, 1.0, 0.8)
		var car_colors = [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.9, 0.8, 0.1), Color(0.3, 0.8, 0.3)]
		crm.material = _make_mat(car_colors[i % car_colors.size()])
		car.mesh = crm
		car.position = fw_center + Vector3(0, sin(angle) * fw_radius - 0.5, cos(angle) * fw_radius)
		add_child(car)

	# Support structure
	for side in [-1, 1]:
		var leg = MeshInstance3D.new()
		var lgm = CylinderMesh.new()
		lgm.height = 14.0
		lgm.top_radius = 0.15
		lgm.bottom_radius = 0.25
		lgm.material = _make_mat(Color(0.5, 0.5, 0.52), 0.5, 0.6)
		leg.mesh = lgm
		leg.position = base + Vector3(side * 2, 7.0, 40)
		leg.rotation.z = side * 0.15
		add_child(leg)

func _create_venice_beach():
	# Muscle beach / boardwalk area near the main beach
	var base = Vector3(-60, 0, 155)
	_register_zone(base.x, base.z, 90, 20)
	# Boardwalk (concrete path)
	var bw = MeshInstance3D.new()
	var bwm = BoxMesh.new()
	bwm.size = Vector3(80, 0.15, 4)
	bwm.material = _make_mat(Color(0.6, 0.58, 0.55), 0.85)
	bw.mesh = bwm
	bw.position = base + Vector3(0, 0.08, 0)
	add_child(bw)

	# Street art walls (colorful murals)
	var mural_colors = [Color(0.9, 0.2, 0.3), Color(0.2, 0.7, 0.9), Color(0.9, 0.8, 0.1), Color(0.5, 0.2, 0.8), Color(0.2, 0.9, 0.4)]
	for mi_i in range(5):
		var wall = MeshInstance3D.new()
		var wm = BoxMesh.new()
		wm.size = Vector3(6, 3, 0.2)
		wm.material = _make_mat(mural_colors[mi_i])
		wall.mesh = wm
		wall.position = base + Vector3(-30 + mi_i * 15, 1.5, -3)
		add_child(wall)

	# Muscle Beach gym equipment (outdoor)
	var gym_base = base + Vector3(20, 0, 5)
	# Pull-up bar
	for side in [-1, 1]:
		var post = MeshInstance3D.new()
		var pm = CylinderMesh.new()
		pm.height = 2.5
		pm.top_radius = 0.04
		pm.bottom_radius = 0.05
		pm.material = _make_mat(Color(0.3, 0.3, 0.3), 0.4, 0.7)
		post.mesh = pm
		post.position = gym_base + Vector3(side * 1.2, 1.25, 0)
		add_child(post)
	var bar = MeshInstance3D.new()
	var brm = CylinderMesh.new()
	brm.height = 2.4
	brm.top_radius = 0.025
	brm.bottom_radius = 0.025
	brm.material = _make_mat(Color(0.6, 0.6, 0.6), 0.3, 0.8)
	bar.mesh = brm
	bar.position = gym_base + Vector3(0, 2.5, 0)
	bar.rotation.z = PI / 2
	add_child(bar)

	# Skate park ramp
	var ramp = MeshInstance3D.new()
	var rpm = BoxMesh.new()
	rpm.size = Vector3(6, 2, 4)
	rpm.material = _make_mat(Color(0.5, 0.48, 0.45), 0.85)
	ramp.mesh = rpm
	ramp.position = base + Vector3(-25, 1.0, 8)
	ramp.rotation.x = -0.3
	add_child(ramp)

func _create_griffith_observatory():
	# Iconic white domed observatory on a hill in the north
	var base = Vector3(-150, 0, -150)
	_register_zone(base.x, base.z, 110, 110)

	# Hill
	var hill = MeshInstance3D.new()
	var hlm = CylinderMesh.new()
	hlm.top_radius = 30.0
	hlm.bottom_radius = 50.0
	hlm.height = 18.0
	hlm.material = _make_mat(Color(0.3, 0.48, 0.25), 0.9)
	hill.mesh = hlm
	hill.position = base + Vector3(0, 9.0, 0)
	add_child(hill)

	# Main building (Art Deco white)
	var obs_pos = base + Vector3(0, 18.0, 0)
	var main_bldg = StaticBody3D.new()
	main_bldg.position = obs_pos + Vector3(0, 3, 0)
	var obs_main = MeshInstance3D.new()
	var obm = BoxMesh.new()
	obm.size = Vector3(25, 6, 12)
	obm.material = _make_mat(Color(0.92, 0.90, 0.85), 0.5, 0.1)
	obs_main.mesh = obm
	main_bldg.add_child(obs_main)
	var obs_col = CollisionShape3D.new()
	obs_col.shape = BoxShape3D.new()
	obs_col.shape.size = Vector3(25, 6, 12)
	main_bldg.add_child(obs_col)
	add_child(main_bldg)

	# Central dome (copper/green patina)
	var dome = MeshInstance3D.new()
	var dme = SphereMesh.new()
	dme.radius = 5.0
	dme.height = 5.5
	dme.material = _make_mat(Color(0.45, 0.6, 0.5), 0.6, 0.3)
	dome.mesh = dme
	dome.position = obs_pos + Vector3(0, 8.5, 0)
	add_child(dome)

	# Side domes (smaller)
	for side in [-1, 1]:
		var sdome = MeshInstance3D.new()
		var sdm = SphereMesh.new()
		sdm.radius = 3.0
		sdm.height = 3.5
		sdm.material = _make_mat(Color(0.45, 0.6, 0.5), 0.6, 0.3)
		sdome.mesh = sdm
		sdome.position = obs_pos + Vector3(side * 10, 7.5, 0)
		add_child(sdome)

	# Telescope tube on central dome
	var telescope = MeshInstance3D.new()
	var tlm = CylinderMesh.new()
	tlm.top_radius = 0.3
	tlm.bottom_radius = 0.5
	tlm.height = 3.0
	tlm.material = _make_mat(Color(0.5, 0.5, 0.52), 0.4, 0.6)
	telescope.mesh = tlm
	telescope.position = obs_pos + Vector3(0, 11.5, 0)
	telescope.rotation.x = -0.5
	add_child(telescope)

func _create_walk_of_fame():
	# Hollywood Walk of Fame — a decorated sidewalk stretch
	var base = Vector3(-30, 0, -35)
	_register_zone(base.x, base.z, 90, 10)
	# Pink terrazzo sidewalk
	var walk = MeshInstance3D.new()
	var wkm = BoxMesh.new()
	wkm.size = Vector3(80, 0.12, 4)
	wkm.material = _make_mat(Color(0.75, 0.55, 0.55), 0.8)
	walk.mesh = wkm
	walk.position = base + Vector3(0, 0.06, 0)
	add_child(walk)

	# Star markers (brass stars embedded in sidewalk)
	for i in range(16):
		var star = MeshInstance3D.new()
		var stm = CylinderMesh.new()
		stm.top_radius = 0.5
		stm.bottom_radius = 0.5
		stm.height = 0.04
		var star_mat = StandardMaterial3D.new()
		star_mat.albedo_color = Color(0.78, 0.62, 0.28)
		star_mat.roughness = 0.2
		star_mat.metallic = 0.8
		stm.material = star_mat
		star.mesh = stm
		star.position = base + Vector3(-35 + i * 4.5, 0.14, randf_range(-1.2, 1.2))
		add_child(star)

func _create_rodeo_drive():
	# Luxury shopping district — high-end storefronts
	var base = Vector3(130, 0, 40)
	_register_zone(base.x + 10, base.z, 25, 70)
	# Fancy sidewalk (marble-like)
	var walk = MeshInstance3D.new()
	var wkm = BoxMesh.new()
	wkm.size = Vector3(4, 0.12, 60)
	wkm.material = _make_mat(Color(0.88, 0.85, 0.82), 0.3, 0.1)
	walk.mesh = wkm
	walk.position = base + Vector3(8, 0.06, 0)
	add_child(walk)

	# Luxury storefronts
	var stores = [
		["GUCCI", Color(0.08, 0.08, 0.08), Color(0.85, 0.75, 0.35)],
		["PRADA", Color(0.15, 0.15, 0.15), Color(0.9, 0.9, 0.9)],
		["CHANEL", Color(0.05, 0.05, 0.05), Color(0.95, 0.92, 0.85)],
		["LV", Color(0.35, 0.2, 0.1), Color(0.9, 0.8, 0.5)],
		["TIFFANY", Color(0.45, 0.75, 0.78), Color(0.9, 0.9, 0.9)],
	]
	for si in range(stores.size()):
		var store = stores[si]
		var spos = base + Vector3(12, 3, -25 + si * 12)
		var sbody = StaticBody3D.new()
		sbody.position = spos
		var smi = MeshInstance3D.new()
		var sbm = BoxMesh.new()
		sbm.size = Vector3(8, 6, 10)
		sbm.material = _make_mat(store[1], 0.3, 0.15)
		smi.mesh = sbm
		sbody.add_child(smi)
		# Glass front
		var gf = MeshInstance3D.new()
		var gfm = BoxMesh.new()
		gfm.size = Vector3(0.06, 4, 8)
		var gmat = StandardMaterial3D.new()
		gmat.albedo_color = Color(0.7, 0.75, 0.8, 0.35)
		gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gmat.roughness = 0.02
		gmat.metallic = 0.4
		gfm.material = gmat
		gf.mesh = gfm
		gf.position = Vector3(-4.03, -0.5, 0)
		sbody.add_child(gf)
		# Name plaque (gold lettering)
		var plaque = MeshInstance3D.new()
		var pqm = BoxMesh.new()
		pqm.size = Vector3(0.08, 0.8, 4)
		var plq_mat = StandardMaterial3D.new()
		plq_mat.albedo_color = store[2]
		plq_mat.emission_enabled = true
		plq_mat.emission = store[2]
		plq_mat.emission_energy_multiplier = 0.4
		pqm.material = plq_mat
		plaque.mesh = pqm
		plaque.position = Vector3(-4.06, 2.0, 0)
		sbody.add_child(plaque)
		var scol = CollisionShape3D.new()
		scol.shape = BoxShape3D.new()
		scol.shape.size = Vector3(8, 6, 10)
		sbody.add_child(scol)
		add_child(sbody)

	# Decorative palm trees along the drive
	for i in range(6):
		_add_palm_tree(base + Vector3(5, 0, -28 + i * 10))

func _create_chinatown():
	# Chinatown gate and buildings — distinctive red/gold
	var base = Vector3(-130, 0, -40)
	_register_zone(base.x, base.z, 50, 30)

	# Ornamental Gate (paifang)
	var gate = Node3D.new()
	gate.position = base
	# Main pillars (red)
	for side in [-1, 1]:
		var pillar = MeshInstance3D.new()
		var plm = CylinderMesh.new()
		plm.height = 8.0
		plm.top_radius = 0.3
		plm.bottom_radius = 0.35
		plm.material = _make_mat(Color(0.75, 0.12, 0.1), 0.6)
		pillar.mesh = plm
		pillar.position = Vector3(side * 5, 4, 0)
		gate.add_child(pillar)
	# Cross beam (gold)
	var beam = MeshInstance3D.new()
	var bmm = BoxMesh.new()
	bmm.size = Vector3(12, 0.6, 0.8)
	bmm.material = _make_mat(Color(0.85, 0.7, 0.2), 0.4, 0.5)
	beam.mesh = bmm
	beam.position = Vector3(0, 7.5, 0)
	gate.add_child(beam)
	# Roof (pagoda style — tiered)
	for tier in range(2):
		var pg_roof = MeshInstance3D.new()
		var prm = BoxMesh.new()
		prm.size = Vector3(13 - tier * 3, 0.3, 3 - tier * 0.5)
		prm.material = _make_mat(Color(0.2, 0.55, 0.25), 0.7)
		pg_roof.mesh = prm
		pg_roof.position = Vector3(0, 8.0 + tier * 1.2, 0)
		gate.add_child(pg_roof)
	add_child(gate)

	# Chinatown buildings (red + gold trim)
	var ct_colors = [Color(0.7, 0.15, 0.12), Color(0.6, 0.12, 0.1), Color(0.65, 0.18, 0.12)]
	for i in range(4):
		var bpos = base + Vector3(-15 + i * 10, 0, -12)
		_add_building(bpos, Vector3(8, randf_range(8, 14), 8), ct_colors[i % ct_colors.size()])

	# Red lanterns
	for i in range(8):
		var lantern = MeshInstance3D.new()
		var lnm = SphereMesh.new()
		lnm.radius = 0.4
		lnm.height = 0.6
		var lan_mat = StandardMaterial3D.new()
		lan_mat.albedo_color = Color(0.9, 0.15, 0.1)
		lan_mat.emission_enabled = true
		lan_mat.emission = Color(0.95, 0.2, 0.1)
		lan_mat.emission_energy_multiplier = 0.5
		lnm.material = lan_mat
		lantern.mesh = lnm
		lantern.position = base + Vector3(-12 + i * 3.5, 5.5, randf_range(-3, 3))
		add_child(lantern)

func _create_lax_control_tower():
	# Airport control tower in the far south
	var base = Vector3(160, 0, 120)
	_register_zone(base.x + 15, base.z, 50, 130)

	# Tower base (wide pedestal)
	var pedestal = StaticBody3D.new()
	pedestal.position = base + Vector3(0, 3, 0)
	var ped = MeshInstance3D.new()
	var pdm = BoxMesh.new()
	pdm.size = Vector3(12, 6, 12)
	pdm.material = _make_mat(Color(0.7, 0.7, 0.72), 0.6, 0.1)
	ped.mesh = pdm
	pedestal.add_child(ped)
	var pcol = CollisionShape3D.new()
	pcol.shape = BoxShape3D.new()
	pcol.shape.size = Vector3(12, 6, 12)
	pedestal.add_child(pcol)
	add_child(pedestal)

	# Tower shaft
	var shaft = MeshInstance3D.new()
	var shm = CylinderMesh.new()
	shm.height = 25.0
	shm.top_radius = 2.0
	shm.bottom_radius = 2.5
	shm.material = _make_mat(Color(0.75, 0.75, 0.78), 0.5, 0.15)
	shaft.mesh = shm
	shaft.position = base + Vector3(0, 18.5, 0)
	add_child(shaft)

	# Control room (glass cab at top)
	var cab = MeshInstance3D.new()
	var cbm = CylinderMesh.new()
	cbm.top_radius = 5.0
	cbm.bottom_radius = 4.5
	cbm.height = 4.0
	var cab_mat = StandardMaterial3D.new()
	cab_mat.albedo_color = Color(0.5, 0.65, 0.8, 0.5)
	cab_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cab_mat.roughness = 0.05
	cab_mat.metallic = 0.3
	cbm.material = cab_mat
	cab.mesh = cbm
	cab.position = base + Vector3(0, 33, 0)
	add_child(cab)

	# Roof disc
	var roof = MeshInstance3D.new()
	var rfm = CylinderMesh.new()
	rfm.top_radius = 5.5
	rfm.bottom_radius = 5.5
	rfm.height = 0.5
	rfm.material = _make_mat(Color(0.6, 0.6, 0.62), 0.5, 0.2)
	roof.mesh = rfm
	roof.position = base + Vector3(0, 35.3, 0)
	add_child(roof)

	# Runway strip
	var runway = MeshInstance3D.new()
	var rwm = BoxMesh.new()
	rwm.size = Vector3(15, 0.1, 120)
	rwm.material = _make_mat(Color(0.18, 0.18, 0.2), 0.85)
	runway.mesh = rwm
	runway.position = base + Vector3(25, 0.05, 0)
	add_child(runway)
	# Runway markings
	for ri in range(10):
		var mark = MeshInstance3D.new()
		var mkm = BoxMesh.new()
		mkm.size = Vector3(1.5, 0.02, 4)
		mkm.material = _make_mat(Color(0.95, 0.95, 0.95))
		mark.mesh = mkm
		mark.position = base + Vector3(25, 0.12, -50 + ri * 10)
		add_child(mark)

func _create_beverly_hills_mansion():
	# Luxury mansion area in the hills
	var base = Vector3(-160, 0, -100)
	_register_zone(base.x, base.z, 60, 50)

	# Elevated terrain
	var terrain = MeshInstance3D.new()
	var trm = BoxMesh.new()
	trm.size = Vector3(50, 4, 40)
	trm.material = _make_mat(Color(0.2, 0.5, 0.2), 0.9)
	terrain.mesh = trm
	terrain.position = base + Vector3(0, 2, 0)
	add_child(terrain)

	# Main mansion
	var mansion = StaticBody3D.new()
	mansion.position = base + Vector3(0, 7, 0)
	var m_main = MeshInstance3D.new()
	var mmm = BoxMesh.new()
	mmm.size = Vector3(20, 6, 15)
	mmm.material = _make_mat(Color(0.92, 0.90, 0.85), 0.5, 0.08)
	m_main.mesh = mmm
	mansion.add_child(m_main)
	var mcol = CollisionShape3D.new()
	mcol.shape = BoxShape3D.new()
	mcol.shape.size = Vector3(20, 6, 15)
	mansion.add_child(mcol)
	add_child(mansion)

	# Columns (grand entrance)
	for ci in range(4):
		var col = MeshInstance3D.new()
		var clm = CylinderMesh.new()
		clm.height = 5.0
		clm.top_radius = 0.25
		clm.bottom_radius = 0.3
		clm.material = _make_mat(Color(0.9, 0.88, 0.82), 0.4, 0.2)
		col.mesh = clm
		col.position = base + Vector3(-4.5 + ci * 3, 6.5, 8)
		add_child(col)

	# Swimming pool
	var pool = MeshInstance3D.new()
	var plm = BoxMesh.new()
	plm.size = Vector3(8, 0.8, 5)
	var pool_mat = StandardMaterial3D.new()
	pool_mat.albedo_color = Color(0.2, 0.5, 0.8, 0.75)
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.roughness = 0.02
	plm.material = pool_mat
	pool.mesh = plm
	pool.position = base + Vector3(0, 4.0, -12)
	add_child(pool)

	# Pool edge (white tile)
	var edge = MeshInstance3D.new()
	var edm = BoxMesh.new()
	edm.size = Vector3(9, 0.15, 6)
	edm.material = _make_mat(Color(0.9, 0.9, 0.88), 0.4)
	edge.mesh = edm
	edge.position = base + Vector3(0, 4.4, -12)
	add_child(edge)

	# Fountain in front
	var fb = MeshInstance3D.new()
	var fbm = CylinderMesh.new()
	fbm.top_radius = 1.8
	fbm.bottom_radius = 2.0
	fbm.height = 0.6
	fbm.material = _make_mat(Color(0.8, 0.78, 0.75), 0.4, 0.2)
	fb.mesh = fbm
	fb.position = base + Vector3(0, 4.6, 16)
	add_child(fb)

func _create_dodger_stadium_sign():
	# Big sign near the stadium area
	var base = Vector3(100, 0, 75)
	_register_zone(base.x, base.z, 20, 20)
	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_color = Color(0.1, 0.25, 0.6)
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(0.15, 0.3, 0.7)
	sign_mat.emission_energy_multiplier = 0.6

	var sign = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(15, 3, 0.3)
	sm.material = sign_mat
	sign.mesh = sm
	sign.position = base + Vector3(0, 10, -35)
	add_child(sign)

	# "DODGER STADIUM" letters (white blocks)
	var letter_mat = StandardMaterial3D.new()
	letter_mat.albedo_color = Color(0.95, 0.95, 0.95)
	letter_mat.emission_enabled = true
	letter_mat.emission = Color(1.0, 1.0, 1.0)
	letter_mat.emission_energy_multiplier = 0.3

	var letters = "DODGERSTADIUM"
	for i in range(letters.length()):
		var letter = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.9, 1.8, 0.15)
		lm.material = letter_mat
		letter.mesh = lm
		letter.position = base + Vector3(-6.5 + i * 1.05, 10, -34.7)
		add_child(letter)

# ═══ SAVE POINT MARKERS ═══
func create_save_point_markers():
	var save_positions = [
		[Vector3(-120, 0.02, 50), "STARLIGHT MOTEL — SAVE"],
		[Vector3(22, 0.02, 22), "SAFE HOUSE — SAVE"],
		[Vector3(120, 0.02, -50), "MEL'S DINER — SAVE"],
	]
	for sp in save_positions:
		var pos = sp[0]
		_create_save_marker(pos)

func _create_save_marker(pos: Vector3):
	# Glowing ground disc with rotating outer ring
	var marker = Node3D.new()
	marker.position = pos
	marker.add_to_group("save_point")
	add_child(marker)

	# Inner disc (golden glow)
	var disc = MeshInstance3D.new()
	var dm = CylinderMesh.new()
	dm.top_radius = 2.5
	dm.bottom_radius = 2.5
	dm.height = 0.05
	var disc_mat = StandardMaterial3D.new()
	disc_mat.albedo_color = Color(1.0, 0.7, 0.15)
	disc_mat.emission_enabled = true
	disc_mat.emission = Color(1.0, 0.6, 0.1)
	disc_mat.emission_energy_multiplier = 2.5
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color.a = 0.7
	dm.material = disc_mat
	disc.mesh = dm
	disc.position.y = 0.03
	marker.add_child(disc)

	# Outer ring
	var ring = MeshInstance3D.new()
	var rm = TorusMesh.new()
	rm.inner_radius = 2.3
	rm.outer_radius = 2.8
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.5, 0.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.4, 0.0)
	ring_mat.emission_energy_multiplier = 1.8
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color.a = 0.5
	rm.material = ring_mat
	ring.mesh = rm
	ring.position.y = 0.2
	ring.rotation.x = deg_to_rad(90)
	marker.add_child(ring)

	# Floating floppy disk icon above
	var floppy = MeshInstance3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(0.8, 0.8, 0.15)
	var floppy_mat = StandardMaterial3D.new()
	floppy_mat.albedo_color = Color(1.0, 0.6, 0.1)
	floppy_mat.emission_enabled = true
	floppy_mat.emission = Color(1.0, 0.5, 0.0)
	floppy_mat.emission_energy_multiplier = 3.0
	fm.material = floppy_mat
	floppy.mesh = fm
	floppy.position.y = 2.5
	marker.add_child(floppy)

	# Light column
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.1)
	light.light_energy = 2.5
	light.omni_range = 8.0
	light.position.y = 1.5
	marker.add_child(light)
