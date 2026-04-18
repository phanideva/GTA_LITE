# city_generator.gd
# Procedural city generation system for GTA-style open world
extends Node3D

class_name CityGenerator

# City dimensions
@export var city_size := Vector2(500, 500)  # Width x Depth in meters
@export var block_size := 40.0  # Size of city blocks
@export var road_width := 12.0  # Width of main roads
@export var sidewalk_width := 3.0

# District definitions
enum DistrictType { DOWNTOWN, RESIDENTIAL, INDUSTRIAL, COMMERCIAL, HARBOR, PARK }

var districts: Dictionary = {}
var buildings: Array[Node3D] = []
var props: Array[Node3D] = []

# Materials
var ground_material: StandardMaterial3D
var road_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var building_materials: Array[StandardMaterial3D] = []
var glass_material: StandardMaterial3D
var grass_material: StandardMaterial3D

# Generation state
var is_generated := false

signal generation_started()
signal generation_progress(percent: float, message: String)
signal generation_completed()

func _ready() -> void:
	_create_materials()

func _create_materials() -> void:
	# Ground (under everything)
	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.2, 0.25, 0.2)
	ground_material.roughness = 0.95
	
	# Road
	road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color(0.15, 0.15, 0.18)
	road_material.roughness = 0.9
	
	# Sidewalk
	sidewalk_material = StandardMaterial3D.new()
	sidewalk_material.albedo_color = Color(0.6, 0.58, 0.55)
	sidewalk_material.roughness = 0.85
	
	# Grass
	grass_material = StandardMaterial3D.new()
	grass_material.albedo_color = Color(0.25, 0.45, 0.2)
	grass_material.roughness = 0.95
	
	# Glass
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.3, 0.4, 0.5, 0.4)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.2
	glass_material.roughness = 0.1
	
	# Building materials (various)
	var building_colors = [
		Color(0.7, 0.68, 0.65),  # Concrete
		Color(0.5, 0.35, 0.25),  # Brick
		Color(0.8, 0.75, 0.7),   # Stone
		Color(0.4, 0.4, 0.42),   # Dark concrete
		Color(0.85, 0.82, 0.75), # Light stone
	]
	
	for color in building_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.8
		building_materials.append(mat)

func generate_city() -> void:
	if is_generated:
		clear_city()
	
	generation_started.emit()
	
	# Step 1: Define districts
	generation_progress.emit(5.0, "Defining districts...")
	_define_districts()
	
	# Step 2: Create ground
	generation_progress.emit(10.0, "Creating terrain...")
	_create_ground()
	
	# Step 3: Create road network
	generation_progress.emit(20.0, "Building roads...")
	_create_roads()
	
	# Step 4: Create sidewalks
	generation_progress.emit(30.0, "Adding sidewalks...")
	_create_sidewalks()
	
	# Step 5: Generate buildings
	generation_progress.emit(40.0, "Constructing buildings...")
	_generate_buildings()
	
	# Step 6: Add street props
	generation_progress.emit(70.0, "Placing street furniture...")
	_add_street_props()
	
	# Step 7: Add vegetation
	generation_progress.emit(85.0, "Planting vegetation...")
	_add_vegetation()
	
	# Step 8: Setup navigation
	generation_progress.emit(95.0, "Setting up navigation...")
	_setup_navigation()
	
	is_generated = true
	generation_progress.emit(100.0, "City generation complete!")
	generation_completed.emit()

func clear_city() -> void:
	for child in get_children():
		child.queue_free()
	
	buildings.clear()
	props.clear()
	is_generated = false

func _define_districts() -> void:
	districts.clear()
	
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	
	# Downtown - center
	districts["downtown"] = {
		"type": DistrictType.DOWNTOWN,
		"bounds": Rect2(-half_width * 0.3, -half_depth * 0.3, half_width * 0.6, half_depth * 0.6),
		"building_height_min": 20,
		"building_height_max": 80,
		"density": 0.9
	}
	
	# Commercial - around downtown
	districts["commercial_north"] = {
		"type": DistrictType.COMMERCIAL,
		"bounds": Rect2(-half_width * 0.5, -half_depth * 0.7, half_width, half_depth * 0.4),
		"building_height_min": 8,
		"building_height_max": 25,
		"density": 0.7
	}
	
	districts["commercial_south"] = {
		"type": DistrictType.COMMERCIAL,
		"bounds": Rect2(-half_width * 0.5, half_depth * 0.3, half_width, half_depth * 0.4),
		"building_height_min": 8,
		"building_height_max": 25,
		"density": 0.7
	}
	
	# Residential - outer areas
	districts["residential_east"] = {
		"type": DistrictType.RESIDENTIAL,
		"bounds": Rect2(half_width * 0.3, -half_depth * 0.5, half_width * 0.5, half_depth),
		"building_height_min": 3,
		"building_height_max": 12,
		"density": 0.6
	}
	
	districts["residential_west"] = {
		"type": DistrictType.RESIDENTIAL,
		"bounds": Rect2(-half_width * 0.8, -half_depth * 0.5, half_width * 0.5, half_depth),
		"building_height_min": 3,
		"building_height_max": 12,
		"density": 0.6
	}
	
	# Industrial - one corner
	districts["industrial"] = {
		"type": DistrictType.INDUSTRIAL,
		"bounds": Rect2(half_width * 0.4, half_depth * 0.4, half_width * 0.4, half_depth * 0.4),
		"building_height_min": 5,
		"building_height_max": 15,
		"density": 0.5
	}
	
	# Park - open area
	districts["central_park"] = {
		"type": DistrictType.PARK,
		"bounds": Rect2(-half_width * 0.15, -half_depth * 0.15, half_width * 0.3, half_depth * 0.3),
		"building_height_min": 0,
		"building_height_max": 0,
		"density": 0.0
	}

func _create_ground() -> void:
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(city_size.x * 1.2, city_size.y * 1.2)
	ground.mesh = mesh
	ground.material_override = ground_material
	
	# Add collision
	var collision = ground.create_trimesh_collision()
	
	add_child(ground)

func _create_roads() -> void:
	var roads_parent = Node3D.new()
	roads_parent.name = "Roads"
	add_child(roads_parent)
	
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	
	# Main roads (cross through center)
	_create_road_segment(roads_parent, Vector3(-half_width, 0.02, 0), Vector3(half_width, 0.02, 0), road_width)
	_create_road_segment(roads_parent, Vector3(0, 0.02, -half_depth), Vector3(0, 0.02, half_depth), road_width)
	
	# Grid roads
	var grid_spacing = block_size + road_width
	var start = -half_width + grid_spacing
	
	# N-S roads
	var x = start
	while x < half_width - grid_spacing:
		if abs(x) > road_width:  # Skip center (main road)
			_create_road_segment(roads_parent, 
				Vector3(x, 0.02, -half_depth * 0.8), 
				Vector3(x, 0.02, half_depth * 0.8), 
				road_width * 0.7)
		x += grid_spacing
	
	# E-W roads
	var z = start
	while z < half_depth - grid_spacing:
		if abs(z) > road_width:  # Skip center
			_create_road_segment(roads_parent, 
				Vector3(-half_width * 0.8, 0.02, z), 
				Vector3(half_width * 0.8, 0.02, z), 
				road_width * 0.7)
		z += grid_spacing

func _create_road_segment(parent: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var road = MeshInstance3D.new()
	
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var center = (from + to) * 0.5
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(width, 0.05, length)
	road.mesh = mesh
	road.material_override = road_material
	
	road.position = center
	road.look_at(to, Vector3.UP)
	road.rotation.x = 0
	
	# Add collision
	var collision = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, 0.1, length)
	col_shape.shape = box
	collision.add_child(col_shape)
	road.add_child(collision)
	
	parent.add_child(road)
	
	# Add lane markings
	_add_lane_markings(road, length, width)

func _add_lane_markings(road: MeshInstance3D, length: float, width: float) -> void:
	var marking_material = StandardMaterial3D.new()
	marking_material.albedo_color = Color(0.9, 0.85, 0.3)  # Yellow
	marking_material.emission_enabled = true
	marking_material.emission = Color(0.5, 0.45, 0.1)
	marking_material.emission_energy_multiplier = 0.1
	
	# Center line (dashed)
	var dash_length = 3.0
	var gap_length = 2.0
	var z = -length * 0.5 + dash_length * 0.5
	
	while z < length * 0.5:
		var dash = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.15, 0.02, dash_length)
		dash.mesh = mesh
		dash.material_override = marking_material
		dash.position = Vector3(0, 0.03, z)
		road.add_child(dash)
		
		z += dash_length + gap_length

func _create_sidewalks() -> void:
	var sidewalks_parent = Node3D.new()
	sidewalks_parent.name = "Sidewalks"
	add_child(sidewalks_parent)
	
	# Sidewalks are created alongside roads during building generation
	# This creates the main sidewalks along major roads
	
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	
	# Main road sidewalks
	_create_sidewalk_segment(sidewalks_parent, 
		Vector3(-half_width, 0.08, road_width * 0.5 + sidewalk_width * 0.5),
		Vector3(half_width, 0.08, road_width * 0.5 + sidewalk_width * 0.5),
		sidewalk_width)
	
	_create_sidewalk_segment(sidewalks_parent, 
		Vector3(-half_width, 0.08, -road_width * 0.5 - sidewalk_width * 0.5),
		Vector3(half_width, 0.08, -road_width * 0.5 - sidewalk_width * 0.5),
		sidewalk_width)

func _create_sidewalk_segment(parent: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var sidewalk = MeshInstance3D.new()
	
	var length = from.distance_to(to)
	var center = (from + to) * 0.5
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(length, 0.15, width)
	sidewalk.mesh = mesh
	sidewalk.material_override = sidewalk_material
	sidewalk.position = center
	
	# Collision
	var collision = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(length, 0.15, width)
	col_shape.shape = box
	collision.add_child(col_shape)
	sidewalk.add_child(collision)
	
	parent.add_child(sidewalk)

func _generate_buildings() -> void:
	var buildings_parent = Node3D.new()
	buildings_parent.name = "Buildings"
	add_child(buildings_parent)
	
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	var grid_spacing = block_size + road_width
	
	# Generate buildings in grid cells
	var x = -half_width + grid_spacing
	while x < half_width - grid_spacing:
		var z = -half_depth + grid_spacing
		while z < half_depth - grid_spacing:
			var pos = Vector3(x, 0, z)
			var district = _get_district_at(pos)
			
			if district and district.type != DistrictType.PARK:
				if randf() < district.density:
					_create_building(buildings_parent, pos, district)
			
			z += grid_spacing
		x += grid_spacing

func _create_building(parent: Node3D, position: Vector3, district: Dictionary) -> void:
	var building = Node3D.new()
	building.name = "Building"
	
	# Random building dimensions based on district
	var width = randf_range(block_size * 0.4, block_size * 0.8)
	var depth = randf_range(block_size * 0.4, block_size * 0.8)
	var height = randf_range(district.building_height_min, district.building_height_max)
	
	# Offset from center of block
	var offset = Vector3(
		randf_range(-5, 5),
		0,
		randf_range(-5, 5)
	)
	
	building.position = position + offset
	
	# Main body
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(width, height, depth)
	body.mesh = body_mesh
	body.material_override = building_materials[randi() % building_materials.size()]
	body.position.y = height * 0.5
	building.add_child(body)
	
	# Windows
	_add_windows(building, width, height, depth)
	
	# Roof details for tall buildings
	if height > 30:
		_add_roof_details(building, width, height, depth)
	
	# Collision
	var collision = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	col_shape.shape = box
	col_shape.position.y = height * 0.5
	collision.add_child(col_shape)
	building.add_child(collision)
	
	parent.add_child(building)
	buildings.append(building)

func _add_windows(building: Node3D, width: float, height: float, depth: float) -> void:
	var window_spacing = 3.0
	var window_size = Vector2(1.5, 2.0)
	
	# Front and back windows
	for side in [-1, 1]:
		var z_pos = (depth * 0.5 + 0.05) * side
		var x = -width * 0.5 + window_spacing
		
		while x < width * 0.5 - window_spacing:
			var y = 3.0
			while y < height - 3.0:
				var window = MeshInstance3D.new()
				var mesh = BoxMesh.new()
				mesh.size = Vector3(window_size.x, window_size.y, 0.1)
				window.mesh = mesh
				window.material_override = glass_material
				window.position = Vector3(x, y, z_pos)
				building.add_child(window)
				
				y += window_spacing
			x += window_spacing
	
	# Side windows
	for side in [-1, 1]:
		var x_pos = (width * 0.5 + 0.05) * side
		var z = -depth * 0.5 + window_spacing
		
		while z < depth * 0.5 - window_spacing:
			var y = 3.0
			while y < height - 3.0:
				var window = MeshInstance3D.new()
				var mesh = BoxMesh.new()
				mesh.size = Vector3(0.1, window_size.y, window_size.x)
				window.mesh = mesh
				window.material_override = glass_material
				window.position = Vector3(x_pos, y, z)
				building.add_child(window)
				
				y += window_spacing
			z += window_spacing

func _add_roof_details(building: Node3D, width: float, height: float, depth: float) -> void:
	# AC units, water tanks, etc.
	var detail_mat = StandardMaterial3D.new()
	detail_mat.albedo_color = Color(0.4, 0.4, 0.42)
	
	# AC unit
	var ac = MeshInstance3D.new()
	var ac_mesh = BoxMesh.new()
	ac_mesh.size = Vector3(3, 2, 3)
	ac.mesh = ac_mesh
	ac.material_override = detail_mat
	ac.position = Vector3(width * 0.3, height + 1, depth * 0.3)
	building.add_child(ac)
	
	# Antenna (for some buildings)
	if randf() < 0.3:
		var antenna = MeshInstance3D.new()
		var antenna_mesh = CylinderMesh.new()
		antenna_mesh.height = 8
		antenna_mesh.top_radius = 0.1
		antenna_mesh.bottom_radius = 0.2
		antenna.mesh = antenna_mesh
		antenna.material_override = detail_mat
		antenna.position = Vector3(0, height + 4, 0)
		building.add_child(antenna)

func _get_district_at(position: Vector3) -> Dictionary:
	for district_name in districts:
		var district = districts[district_name]
		var bounds = district.bounds as Rect2
		
		if bounds.has_point(Vector2(position.x, position.z)):
			return district
	
	return {}

func _add_street_props() -> void:
	var props_parent = Node3D.new()
	props_parent.name = "StreetProps"
	add_child(props_parent)
	
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	
	# Street lights along main roads
	var light_spacing = 25.0
	
	# Along X axis road
	var x = -half_width + light_spacing
	while x < half_width - light_spacing:
		_create_street_light(props_parent, Vector3(x, 0, road_width * 0.5 + 2))
		_create_street_light(props_parent, Vector3(x, 0, -road_width * 0.5 - 2))
		x += light_spacing
	
	# Along Z axis road
	var z = -half_depth + light_spacing
	while z < half_depth - light_spacing:
		_create_street_light(props_parent, Vector3(road_width * 0.5 + 2, 0, z))
		_create_street_light(props_parent, Vector3(-road_width * 0.5 - 2, 0, z))
		z += light_spacing
	
	# Traffic lights at major intersections
	_create_traffic_light(props_parent, Vector3(road_width * 0.5 + 1, 0, road_width * 0.5 + 1))
	_create_traffic_light(props_parent, Vector3(-road_width * 0.5 - 1, 0, road_width * 0.5 + 1))
	_create_traffic_light(props_parent, Vector3(road_width * 0.5 + 1, 0, -road_width * 0.5 - 1))
	_create_traffic_light(props_parent, Vector3(-road_width * 0.5 - 1, 0, -road_width * 0.5 - 1))

func _create_street_light(parent: Node3D, position: Vector3) -> void:
	var light_node = Node3D.new()
	light_node.position = position
	
	# Pole
	var pole = MeshInstance3D.new()
	var pole_mesh = CylinderMesh.new()
	pole_mesh.height = 6
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.12
	pole.mesh = pole_mesh
	
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.3, 0.3, 0.32)
	pole.material_override = pole_mat
	pole.position.y = 3
	light_node.add_child(pole)
	
	# Lamp head
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.8, 0.3, 0.4)
	head.mesh = head_mesh
	head.material_override = pole_mat
	head.position = Vector3(0.3, 6, 0)
	light_node.add_child(head)
	
	# Light source
	var light = SpotLight3D.new()
	light.light_color = Color(1, 0.95, 0.8)
	light.light_energy = 2.0
	light.spot_range = 20
	light.spot_angle = 60
	light.position = Vector3(0.3, 5.9, 0)
	light.rotation_degrees.x = -90
	light_node.add_child(light)
	
	parent.add_child(light_node)
	props.append(light_node)

func _create_traffic_light(parent: Node3D, position: Vector3) -> void:
	var light_node = Node3D.new()
	light_node.position = position
	
	# Pole
	var pole = MeshInstance3D.new()
	var pole_mesh = CylinderMesh.new()
	pole_mesh.height = 4
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.1
	pole.mesh = pole_mesh
	
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.2, 0.2, 0.22)
	pole.material_override = pole_mat
	pole.position.y = 2
	light_node.add_child(pole)
	
	# Light box
	var box = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.4, 1.0, 0.3)
	box.mesh = box_mesh
	box.material_override = pole_mat
	box.position.y = 4.5
	light_node.add_child(box)
	
	# Light colors
	var light_colors = [Color(1, 0, 0), Color(1, 0.8, 0), Color(0, 1, 0)]
	var light_y_offsets = [0.35, 0, -0.35]
	
	for i in range(3):
		var signal_light = MeshInstance3D.new()
		var light_mesh = CylinderMesh.new()
		light_mesh.height = 0.05
		light_mesh.top_radius = 0.1
		light_mesh.bottom_radius = 0.1
		signal_light.mesh = light_mesh
		signal_light.rotation_degrees.x = 90
		
		var light_mat = StandardMaterial3D.new()
		light_mat.albedo_color = light_colors[i] * 0.5
		light_mat.emission_enabled = true
		light_mat.emission = light_colors[i]
		light_mat.emission_energy_multiplier = 0.5 if i != 2 else 2.0  # Green active
		signal_light.material_override = light_mat
		
		signal_light.position = Vector3(0.22, 4.5 + light_y_offsets[i], 0)
		light_node.add_child(signal_light)
	
	parent.add_child(light_node)
	props.append(light_node)

func _add_vegetation() -> void:
	var vegetation_parent = Node3D.new()
	vegetation_parent.name = "Vegetation"
	add_child(vegetation_parent)
	
	# Add trees along sidewalks and in parks
	var half_width = city_size.x * 0.5
	var half_depth = city_size.y * 0.5
	var tree_spacing = 20.0
	
	# Trees along main road
	var x = -half_width + tree_spacing
	while x < half_width - tree_spacing:
		if abs(x) > road_width + 5:  # Not at intersection
			_create_tree(vegetation_parent, Vector3(x, 0, road_width * 0.5 + sidewalk_width + 2))
			_create_tree(vegetation_parent, Vector3(x, 0, -road_width * 0.5 - sidewalk_width - 2))
		x += tree_spacing
	
	# Park trees
	for district_name in districts:
		var district = districts[district_name]
		if district.type == DistrictType.PARK:
			var bounds = district.bounds as Rect2
			for _i in range(20):
				var tree_x = randf_range(bounds.position.x, bounds.position.x + bounds.size.x)
				var tree_z = randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
				_create_tree(vegetation_parent, Vector3(tree_x, 0, tree_z))

func _create_tree(parent: Node3D, position: Vector3) -> void:
	var tree = Node3D.new()
	tree.position = position
	
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
	trunk_mat.roughness = 0.9
	
	var leaves_mat = StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.2, 0.5, 0.2)
	leaves_mat.roughness = 0.95
	
	# Trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	var height = randf_range(3, 6)
	trunk_mesh.height = height
	trunk_mesh.top_radius = 0.15
	trunk_mesh.bottom_radius = 0.25
	trunk.mesh = trunk_mesh
	trunk.material_override = trunk_mat
	trunk.position.y = height * 0.5
	tree.add_child(trunk)
	
	# Leaves (simple sphere for now)
	var leaves = MeshInstance3D.new()
	var leaves_mesh = SphereMesh.new()
	var leaves_size = randf_range(2, 4)
	leaves_mesh.radius = leaves_size
	leaves_mesh.height = leaves_size * 1.5
	leaves.mesh = leaves_mesh
	leaves.material_override = leaves_mat
	leaves.position.y = height + leaves_size * 0.5
	tree.add_child(leaves)
	
	parent.add_child(tree)
	props.append(tree)

func _setup_navigation() -> void:
	# Create navigation region for the city
	var nav_region = NavigationRegion3D.new()
	nav_region.name = "NavigationRegion"
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_height = 1.8
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.25
	
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	
	# Bake navigation mesh (may take time)
	nav_region.bake_navigation_mesh()
