# traffic_ai.gd
# AI controller for traffic vehicles - lane-aware US-rules driving:
#  • stay in right-hand lane on grid roads (50m spacing, axis-aligned)
#  • stop at intersections; yield to vehicles approaching from the right
#  • turn-signal hint via wheel-color flicker (visual)
#  • keep safe following distance with forward raycast
extends VehicleBody3D

class_name TrafficAI

# AI settings
@export var target_speed := 38.0  # km/h
@export var max_speed := 60.0
@export var acceleration := 220.0
@export var brake_force := 50.0
@export var steering_limit := 0.4

# Path following
var path: Array[Vector3] = []
var current_path_index := 0
var path_look_ahead := 8.0

# Lane/grid tracking
const GRID_SPACING := 50.0
const LANE_OFFSET := 2.5  # half-road width: 8m road -> 2.5m off centerline = right lane
var current_axis: String = "ns"   # "ns" (moving along Z) or "ew" (moving along X)
var current_road_index: int = 0    # which grid road we're on (e.g. -8..8)
var direction_sign: int = 1        # +1 or -1 along the axis

# State
enum AIState { DRIVING, STOPPED, YIELDING, TURNING, PANIC }
var current_state: AIState = AIState.DRIVING

# Traffic awareness
var obstacle_ahead := false
var obstacle_distance := INF
var vehicle_ahead: Node3D = null
var traffic_light_state := "green"
var stop_timer := 0.0   # how long we've waited at intersection
var intersection_clear_timer := 0.0

# Panic mode (player hits or threatens)
var panic_timer := 0.0
var panic_direction := Vector3.ZERO

# Raycasts
var forward_ray_length := 18.0

func _ready() -> void:
	add_to_group("vehicle")
	add_to_group("traffic")
	# Detect axis from spawn rotation: rotation.y near 0 or PI -> ns; near ±PI/2 -> ew
	var ry = wrapf(rotation.y, -PI, PI)
	if abs(abs(ry) - PI / 2.0) < 0.5:
		current_axis = "ew"
		current_road_index = int(round(global_position.z / GRID_SPACING))
		direction_sign = -1 if ry > 0 else 1
	else:
		current_axis = "ns"
		current_road_index = int(round(global_position.x / GRID_SPACING))
		direction_sign = 1 if abs(ry) < PI / 2.0 else -1
	_generate_path()

func _physics_process(delta: float) -> void:
	_check_obstacles()
	_check_intersection(delta)
	_update_state(delta)
	_drive(delta)

func _generate_path() -> void:
	# Build a straight lane path along the current axis, in the right-hand lane
	path.clear()
	current_path_index = 0
	var start = global_position
	for step in range(1, 60):
		var p = start
		var ahead = step * 6.0 * direction_sign
		if current_axis == "ns":
			p = Vector3(current_road_index * GRID_SPACING + LANE_OFFSET * direction_sign, 0.2, start.z + ahead)
		else:
			p = Vector3(start.x + ahead, 0.2, current_road_index * GRID_SPACING + LANE_OFFSET * (-direction_sign))
		path.append(p)

func _check_obstacles() -> void:
	obstacle_ahead = false
	obstacle_distance = INF
	vehicle_ahead = null

	var space = get_world_3d().direct_space_state
	var from = global_position + Vector3.UP * 0.5
	var forward = -global_transform.basis.z
	var to = from + forward * forward_ray_length
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 0b111
	var result = space.intersect_ray(query)
	if result:
		obstacle_ahead = true
		obstacle_distance = global_position.distance_to(result.position)
		if result.collider.is_in_group("vehicle"):
			vehicle_ahead = result.collider
		elif result.collider.is_in_group("player"):
			obstacle_distance = max(obstacle_distance - 5, 0)

func _check_intersection(delta: float) -> void:
	# Detect proximity to a perpendicular grid road (intersection) ahead
	var ahead_world = global_position + (-global_transform.basis.z) * 12.0
	var dist_to_cross := INF
	if current_axis == "ns":
		# Find nearest east-west road line
		var nearest = round(ahead_world.z / GRID_SPACING) * GRID_SPACING
		dist_to_cross = abs(ahead_world.z - nearest)
		if abs(global_position.z - nearest) < 6.0:
			dist_to_cross = 0.0
	else:
		var nearest = round(ahead_world.x / GRID_SPACING) * GRID_SPACING
		dist_to_cross = abs(ahead_world.x - nearest)
		if abs(global_position.x - nearest) < 6.0:
			dist_to_cross = 0.0

	# US right-of-way: stop briefly, then yield to traffic crossing from the right.
	# Use a global timer so vehicles take turns.
	var approaching_intersection = dist_to_cross < 4.0 and dist_to_cross > 0.0
	var inside_intersection = false
	if current_axis == "ns":
		inside_intersection = abs(fmod(global_position.z + 9000.0, GRID_SPACING) - 0.0) < 4.0 or abs(fmod(global_position.z + 9000.0, GRID_SPACING) - GRID_SPACING) < 4.0
	else:
		inside_intersection = abs(fmod(global_position.x + 9000.0, GRID_SPACING) - 0.0) < 4.0 or abs(fmod(global_position.x + 9000.0, GRID_SPACING) - GRID_SPACING) < 4.0

	if approaching_intersection and stop_timer <= 0.0 and not inside_intersection:
		# Look for cross-traffic within 18m on the cross axis
		var cross_busy = false
		for other in get_tree().get_nodes_in_group("vehicle"):
			if other == self or not is_instance_valid(other):
				continue
			var d = global_position.distance_to(other.global_position)
			if d > 22.0:
				continue
			# Other must be on the *other* axis to be cross-traffic
			if "current_axis" in other and other.current_axis != current_axis:
				cross_busy = true
				break
		if cross_busy:
			current_state = AIState.STOPPED
			stop_timer = 1.5

	if stop_timer > 0.0:
		stop_timer -= delta
		if stop_timer <= 0.0 and current_state == AIState.STOPPED:
			current_state = AIState.DRIVING

func _update_state(delta: float) -> void:
	match current_state:
		AIState.DRIVING:
			if obstacle_ahead and obstacle_distance < 8.0:
				current_state = AIState.YIELDING
		AIState.STOPPED:
			pass  # cleared by stop_timer above
		AIState.YIELDING:
			if not obstacle_ahead or obstacle_distance > 12.0:
				current_state = AIState.DRIVING
		AIState.TURNING:
			pass
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
			# keep wheels straight
			steering = lerp(steering, 0.0, 8.0 * delta)
		AIState.YIELDING:
			var target = target_speed * (obstacle_distance / forward_ray_length)
			target = clamp(target, 0, target_speed)
			if obstacle_distance < 5.0:
				brake = brake_force
				engine_force = 0
			else:
				_apply_throttle(target, current_speed)
			_follow_path(delta)
		AIState.TURNING:
			_follow_path(delta)
			_apply_throttle(target_speed * 0.5, current_speed)
		AIState.PANIC:
			_apply_throttle(max_speed, current_speed)
			steering = sin(panic_timer * 5) * steering_limit * 0.5

func _follow_path(delta: float) -> void:
	if path.is_empty():
		_generate_path()
		return
	while current_path_index < path.size() - 1:
		var dist = global_position.distance_to(path[current_path_index])
		if dist < path_look_ahead:
			current_path_index += 1
		else:
			break
	if current_path_index >= path.size() - 2:
		# Approaching map edge — make a turn at next intersection
		_turn_at_intersection()
		_generate_path()
		return

	var target_point = path[current_path_index]
	var to_target = (target_point - global_position).normalized()
	to_target.y = 0
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var cross = forward.cross(to_target)
	var steer_amount = -cross.y * 2.0
	steer_amount = clamp(steer_amount, -steering_limit, steering_limit)
	steering = lerp(steering, steer_amount, 6.0 * delta)

func _turn_at_intersection() -> void:
	# Pick a random direction at the next intersection: straight (50%), right (30%), left (20%)
	var pick = randf()
	if pick < 0.5:
		return  # continue straight
	# Snap to grid
	var was_axis = current_axis
	var turn_right = pick < 0.8
	if was_axis == "ns":
		current_axis = "ew"
		current_road_index = int(round(global_position.z / GRID_SPACING))
		# right turn -> direction_sign on the new axis depends on prior direction_sign
		direction_sign = (1 if turn_right else -1) * direction_sign * (1 if was_axis == "ns" else -1)
	else:
		current_axis = "ns"
		current_road_index = int(round(global_position.x / GRID_SPACING))
		direction_sign = (-1 if turn_right else 1) * direction_sign

func _apply_throttle(target_speed_kmh: float, current_speed_kmh: float) -> void:
	var speed_diff = target_speed_kmh - current_speed_kmh
	if speed_diff > 5:
		engine_force = acceleration * (speed_diff / target_speed_kmh)
		brake = 0
	elif speed_diff < -5:
		engine_force = 0
		brake = brake_force * (-speed_diff / target_speed_kmh)
	else:
		engine_force = acceleration * 0.3
		brake = 0

func on_collision(collider: Node3D) -> void:
	if collider.is_in_group("player"):
		current_state = AIState.PANIC
		panic_timer = 5.0
		panic_direction = (global_position - collider.global_position).normalized()

func react_to_gunshot(source: Vector3) -> void:
	var distance = global_position.distance_to(source)
	if distance < 30:
		current_state = AIState.PANIC
		panic_timer = 8.0
		panic_direction = (global_position - source).normalized()

func set_traffic_light(state: String) -> void:
	traffic_light_state = state
