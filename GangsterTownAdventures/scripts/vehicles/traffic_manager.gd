# traffic_manager.gd
# GTA-style traffic system managing AI vehicles on roads
extends Node

class_name TrafficManager

# Traffic settings
@export var max_traffic_vehicles := 20
@export var spawn_radius := 100.0
@export var despawn_radius := 150.0
@export var min_spawn_distance := 30.0

# Road network
var road_nodes: Array[Vector3] = []
var road_connections: Dictionary = {}  # node_index -> [connected_indices]
var lane_width := 3.5

# Active traffic
var traffic_vehicles: Array[Node3D] = []
var spawn_timer := 0.0
var spawn_interval := 2.0

# Vehicle scenes (will be created procedurally)
var vehicle_types := ["sedan", "suv", "sports", "truck"]

# Reference to player
var player: Node3D = null

signal vehicle_spawned(vehicle: Node3D)
signal vehicle_despawned(vehicle: Node3D)

func _ready() -> void:
	# Find player
	await get_tree().create_timer(0.5).timeout
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Generate road network
	_generate_road_network()

func _process(delta: float) -> void:
	if not player:
		return
	
	spawn_timer += delta
	
	# Spawn new vehicles
	if spawn_timer >= spawn_interval and traffic_vehicles.size() < max_traffic_vehicles:
		spawn_timer = 0.0
		_spawn_traffic_vehicle()
	
	# Update and despawn distant vehicles
	_update_traffic(delta)

func _generate_road_network() -> void:
	# Create a grid-based road network
	# This should match the city generation in environment
	
	road_nodes.clear()
	road_connections.clear()
	
	var grid_size := 500.0
	var road_spacing := 50.0
	
	# Generate nodes at intersections
	var node_index := 0
	var position_to_index: Dictionary = {}
	
	# Main roads (N-S and E-W through center)
	var main_roads_x := [0.0]
	var main_roads_z := [0.0]
	
	# Grid roads
	var grid_start := -grid_size * 0.4
	var grid_end := grid_size * 0.4
	
	var current_pos := grid_start
	while current_pos <= grid_end:
		if abs(current_pos) > 10:  # Skip center (main road)
			main_roads_x.append(current_pos)
			main_roads_z.append(current_pos)
		current_pos += road_spacing
	
	# Create intersection nodes
	for x in main_roads_x:
		for z in main_roads_z:
			var pos = Vector3(x, 0.1, z)
			road_nodes.append(pos)
			position_to_index[_pos_key(pos)] = node_index
			node_index += 1
	
	# Connect adjacent nodes
	for i in range(road_nodes.size()):
		road_connections[i] = []
		var pos = road_nodes[i]
		
		# Find neighbors (nodes within road_spacing distance)
		for j in range(road_nodes.size()):
			if i == j:
				continue
			var other_pos = road_nodes[j]
			var dist = pos.distance_to(other_pos)
			if dist < road_spacing * 1.5:
				road_connections[i].append(j)

func _pos_key(pos: Vector3) -> String:
	return str(int(pos.x)) + "," + str(int(pos.z))

func _spawn_traffic_vehicle() -> void:
	if road_nodes.is_empty():
		return
	
	# Find a spawn point near but not too close to player
	var spawn_point := Vector3.ZERO
	var spawn_direction := Vector3.FORWARD
	var valid_spawn := false
	
	for _attempt in range(10):
		# Pick a random road node
		var node_index = randi() % road_nodes.size()
		var node_pos = road_nodes[node_index]
		
		if not player:
			spawn_point = node_pos
			valid_spawn = true
			break
		
		var distance = node_pos.distance_to(player.global_position)
		
		if distance > min_spawn_distance and distance < spawn_radius:
			# Check if player can see this point
			var to_player = (player.global_position - node_pos).normalized()
			var player_forward = -player.global_transform.basis.z
			var angle = rad_to_deg(to_player.angle_to(player_forward))
			
			if angle > 90:  # Behind player
				spawn_point = node_pos
				
				# Determine direction based on road connections
				if road_connections.has(node_index) and road_connections[node_index].size() > 0:
					var next_node = road_connections[node_index][randi() % road_connections[node_index].size()]
					spawn_direction = (road_nodes[next_node] - node_pos).normalized()
				
				valid_spawn = true
				break
	
	if not valid_spawn:
		return
	
	# Create traffic vehicle
	var vehicle = _create_traffic_vehicle()
	if vehicle:
		vehicle.global_position = spawn_point + Vector3.UP * 0.5
		
		# Face the direction
		if spawn_direction.length() > 0.1:
			vehicle.look_at(spawn_point + spawn_direction, Vector3.UP)
		
		get_tree().current_scene.add_child(vehicle)
		traffic_vehicles.append(vehicle)
		vehicle_spawned.emit(vehicle)

func _create_traffic_vehicle() -> Node3D:
	# Create a simple AI-controlled vehicle
	var vehicle = VehicleBody3D.new()
	vehicle.name = "TrafficVehicle_" + str(randi())
	vehicle.add_to_group("vehicle")
	vehicle.add_to_group("traffic")
	
	# Set up physics
	vehicle.mass = 1500.0
	
	# Attach AI script
	var ai_script = load("res://scripts/vehicles/traffic_ai.gd") if ResourceLoader.exists("res://scripts/vehicles/traffic_ai.gd") else null
	if ai_script:
		vehicle.set_script(ai_script)
	
	# Create vehicle mesh
	_add_vehicle_mesh(vehicle)
	
	# Create wheels
	_add_vehicle_wheels(vehicle)
	
	# Create collision
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.8, 1.0, 4.5)
	collision.shape = box
	collision.position.y = 0.5
	vehicle.add_child(collision)
	
	return vehicle

func _add_vehicle_mesh(vehicle: Node3D) -> void:
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.8, 0.5, 4.5)
	body.mesh = body_mesh
	body.position.y = 0.4
	
	var colors = [
		Color(0.15, 0.15, 0.15),
		Color(0.9, 0.9, 0.9),
		Color(0.7, 0.15, 0.15),
		Color(0.15, 0.3, 0.6),
		Color(0.4, 0.4, 0.4),
		Color(0.1, 0.4, 0.2),
	]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colors[randi() % colors.size()]
	mat.metallic = 0.7
	mat.roughness = 0.3
	body.material_override = mat
	vehicle.add_child(body)
	
	# Cabin
	var cabin = MeshInstance3D.new()
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.6, 0.45, 2.0)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.85, -0.3)
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.2, 0.25, 0.3, 0.5)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin.material_override = glass_mat
	vehicle.add_child(cabin)

func _add_vehicle_wheels(vehicle: VehicleBody3D) -> void:
	var wheel_positions = [
		Vector3(-0.8, 0, 1.4),   # Front left
		Vector3(0.8, 0, 1.4),    # Front right
		Vector3(-0.8, 0, -1.4),  # Rear left
		Vector3(0.8, 0, -1.4),   # Rear right
	]
	
	var wheel_mesh = CylinderMesh.new()
	wheel_mesh.height = 0.2
	wheel_mesh.top_radius = 0.35
	wheel_mesh.bottom_radius = 0.35
	
	var tire_mat = StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.1, 0.1, 0.1)
	
	for i in range(4):
		var wheel = VehicleWheel3D.new()
		wheel.name = "Wheel" + str(i)
		wheel.position = wheel_positions[i]
		wheel.wheel_radius = 0.35
		wheel.wheel_rest_length = 0.1
		wheel.suspension_stiffness = 40.0
		wheel.damping_compression = 2.0
		wheel.damping_relaxation = 3.0
		
		if i < 2:  # Front wheels steer
			wheel.use_as_steering = true
		else:  # Rear wheels drive
			wheel.use_as_traction = true
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = wheel_mesh
		mesh_instance.material_override = tire_mat
		mesh_instance.rotation_degrees.z = 90
		wheel.add_child(mesh_instance)
		
		vehicle.add_child(wheel)

func _update_traffic(delta: float) -> void:
	var to_remove: Array[Node3D] = []
	
	for vehicle in traffic_vehicles:
		if not is_instance_valid(vehicle):
			to_remove.append(vehicle)
			continue
		
		# Despawn if too far from player
		if player:
			var distance = vehicle.global_position.distance_to(player.global_position)
			if distance > despawn_radius:
				to_remove.append(vehicle)
	
	# Remove despawned vehicles
	for vehicle in to_remove:
		traffic_vehicles.erase(vehicle)
		if is_instance_valid(vehicle):
			vehicle_despawned.emit(vehicle)
			vehicle.queue_free()

func get_nearest_road_node(position: Vector3) -> Vector3:
	var nearest := Vector3.ZERO
	var nearest_dist := INF
	
	for node in road_nodes:
		var dist = position.distance_to(node)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	
	return nearest

func get_path_to(from: Vector3, to: Vector3) -> Array[Vector3]:
	# Simple A* pathfinding on road network
	var path: Array[Vector3] = []
	
	var start_node := _get_nearest_node_index(from)
	var end_node := _get_nearest_node_index(to)
	
	if start_node < 0 or end_node < 0:
		return path
	
	# Basic path finding (BFS for simplicity)
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [start_node]
	visited[start_node] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current == end_node:
			# Reconstruct path
			var node = end_node
			while node != start_node:
				path.push_front(road_nodes[node])
				node = parent[node]
			path.push_front(road_nodes[start_node])
			break
		
		if road_connections.has(current):
			for neighbor in road_connections[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					parent[neighbor] = current
					queue.append(neighbor)
	
	return path

func _get_nearest_node_index(position: Vector3) -> int:
	var nearest_index := -1
	var nearest_dist := INF
	
	for i in range(road_nodes.size()):
		var dist = position.distance_to(road_nodes[i])
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_index = i
	
	return nearest_index
