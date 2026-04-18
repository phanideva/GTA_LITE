# traffic_ai.gd
# AI controller for traffic vehicles - follows roads and reacts to obstacles
extends VehicleBody3D

class_name TrafficAI

# AI settings
@export var target_speed := 40.0  # km/h
@export var max_speed := 60.0  # km/h
@export var acceleration := 200.0
@export var brake_force := 40.0
@export var steering_limit := 0.35

# Path following
var path: Array[Vector3] = []
var current_path_index := 0
var path_look_ahead := 10.0

# State
enum AIState { DRIVING, STOPPED, YIELDING, PANIC }
var current_state: AIState = AIState.DRIVING

# Traffic awareness
var obstacle_ahead := false
var obstacle_distance := INF
var vehicle_ahead: Node3D = null
var traffic_light_state := "green"

# Panic mode (player hits or threatens)
var panic_timer := 0.0
var panic_direction := Vector3.ZERO

# Raycasts
var forward_ray_length := 15.0

func _ready() -> void:
	add_to_group("vehicle")
	add_to_group("traffic")
	
	# Generate initial path
	_generate_path()

func _physics_process(delta: float) -> void:
	_check_obstacles()
	_update_state(delta)
	_drive(delta)

func _generate_path() -> void:
	# Get path from traffic manager if available
	var traffic_manager = get_node_or_null("/root/Main/TrafficManager")
	if traffic_manager and traffic_manager.has_method("get_path_to"):
		# Generate a path to a random destination
		var dest = global_position + global_transform.basis.z * -200  # Forward 200m
		path = traffic_manager.get_path_to(global_position, dest)
	
	# If no path, create a simple straight path
	if path.is_empty():
		for i in range(10):
			path.append(global_position + global_transform.basis.z * -(i * 20))

func _check_obstacles() -> void:
	obstacle_ahead = false
	obstacle_distance = INF
	vehicle_ahead = null
	
	# Raycast forward
	var space = get_world_3d().direct_space_state
	var from = global_position + Vector3.UP * 0.5
	var forward = -global_transform.basis.z
	var to = from + forward * forward_ray_length
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 0b111  # World, vehicles, NPCs
	
	var result = space.intersect_ray(query)
	if result:
		obstacle_ahead = true
		obstacle_distance = global_position.distance_to(result.position)
		
		if result.collider.is_in_group("vehicle"):
			vehicle_ahead = result.collider
		elif result.collider.is_in_group("player"):
			# Player in front - be careful
			obstacle_distance = max(obstacle_distance - 5, 0)

func _update_state(delta: float) -> void:
	match current_state:
		AIState.DRIVING:
			if obstacle_ahead and obstacle_distance < 8.0:
				current_state = AIState.YIELDING
			elif traffic_light_state == "red":
				current_state = AIState.STOPPED
		
		AIState.STOPPED:
			if traffic_light_state == "green":
				current_state = AIState.DRIVING
		
		AIState.YIELDING:
			if not obstacle_ahead or obstacle_distance > 12.0:
				current_state = AIState.DRIVING
		
		AIState.PANIC:
			panic_timer -= delta
			if panic_timer <= 0:
				current_state = AIState.DRIVING
				_generate_path()

func _drive(delta: float) -> void:
	var current_speed = linear_velocity.length() * 3.6  # m/s to km/h
	
	match current_state:
		AIState.DRIVING:
			_follow_path(delta)
			_apply_throttle(target_speed, current_speed)
		
		AIState.STOPPED:
			brake = brake_force
			engine_force = 0
		
		AIState.YIELDING:
			# Slow down based on obstacle distance
			var target = target_speed * (obstacle_distance / forward_ray_length)
			target = clamp(target, 0, target_speed)
			
			if obstacle_distance < 5.0:
				brake = brake_force
				engine_force = 0
			else:
				_apply_throttle(target, current_speed)
			
			_follow_path(delta)
		
		AIState.PANIC:
			# Drive erratically
			_apply_throttle(max_speed, current_speed)
			steering = sin(panic_timer * 5) * steering_limit * 0.5

func _follow_path(delta: float) -> void:
	if path.is_empty():
		_generate_path()
		return
	
	# Find target point on path
	while current_path_index < path.size() - 1:
		var dist = global_position.distance_to(path[current_path_index])
		if dist < path_look_ahead:
			current_path_index += 1
		else:
			break
	
	# Loop path if needed
	if current_path_index >= path.size():
		current_path_index = 0
		_generate_path()
		return
	
	var target_point = path[current_path_index]
	
	# Calculate steering
	var to_target = (target_point - global_position).normalized()
	to_target.y = 0
	
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	# Cross product gives steering direction
	var cross = forward.cross(to_target)
	var dot = forward.dot(to_target)
	
	# Calculate steering amount
	var steer_amount = -cross.y * 2.0
	steer_amount = clamp(steer_amount, -steering_limit, steering_limit)
	
	# Smooth steering
	steering = lerp(steering, steer_amount, 5.0 * delta)

func _apply_throttle(target_speed_kmh: float, current_speed_kmh: float) -> void:
	var speed_diff = target_speed_kmh - current_speed_kmh
	
	if speed_diff > 5:
		# Accelerate
		engine_force = acceleration * (speed_diff / target_speed_kmh)
		brake = 0
	elif speed_diff < -5:
		# Brake
		engine_force = 0
		brake = brake_force * (-speed_diff / target_speed_kmh)
	else:
		# Maintain speed
		engine_force = acceleration * 0.3
		brake = 0

# Called when hit by player or another vehicle
func on_collision(collider: Node3D) -> void:
	if collider.is_in_group("player"):
		# Enter panic mode
		current_state = AIState.PANIC
		panic_timer = 5.0
		
		# Try to drive away
		panic_direction = (global_position - collider.global_position).normalized()

# React to nearby threats
func react_to_gunshot(source: Vector3) -> void:
	var distance = global_position.distance_to(source)
	if distance < 30:
		current_state = AIState.PANIC
		panic_timer = 8.0
		panic_direction = (global_position - source).normalized()

func set_traffic_light(state: String) -> void:
	traffic_light_state = state
