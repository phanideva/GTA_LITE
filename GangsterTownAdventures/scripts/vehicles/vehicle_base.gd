# vehicle_base.gd
# Modern GTA-style vehicle controller using VehicleBody3D
# Realistic physics with arcade-friendly handling
extends VehicleBody3D

class_name VehicleBase

# Vehicle types
enum VehicleType { SEDAN, SPORTS, SUV, MUSCLE, TRUCK, MOTORCYCLE }

@export var vehicle_type: VehicleType = VehicleType.SEDAN
@export var vehicle_name: String = "Generic Car"

# Engine specs
@export_group("Engine")
@export var max_engine_force := 400.0
@export var max_brake_force := 50.0
@export var max_rpm := 7000.0
@export var idle_rpm := 800.0
@export var top_speed_kmh := 180.0  # km/h

# Handling
@export_group("Handling")
@export var steering_limit := 0.4  # radians
@export var steering_speed := 4.0
@export var traction_control := true
@export var drift_factor := 0.05

# Vehicle stats
@export_group("Stats")
@export var max_health := 1000.0
var current_health := 1000.0
var is_destroyed := false

# Damage zones
var front_damage := 0.0
var rear_damage := 0.0
var left_damage := 0.0
var right_damage := 0.0

# State
var current_driver: Node3D = null
var is_player_controlled := false
var is_ai_controlled := false
var engine_running := false
var current_rpm := 0.0
var current_gear := 1
var current_speed_kmh := 0.0

# Input tracking
var steering_input := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var handbrake_input := false

# Gear ratios (6-speed + reverse)
var gear_ratios := [-3.0, 0.0, 3.5, 2.5, 1.8, 1.3, 1.0, 0.8]
var final_drive := 3.7
var automatic_transmission := true

# Visual components
var body_mesh: MeshInstance3D
var wheel_meshes: Array[MeshInstance3D] = []
var headlights: Array[SpotLight3D] = []
var brake_lights: Array[OmniLight3D] = []

# Node references
@onready var front_left_wheel: VehicleWheel3D = $FrontLeftWheel if has_node("FrontLeftWheel") else null
@onready var front_right_wheel: VehicleWheel3D = $FrontRightWheel if has_node("FrontRightWheel") else null
@onready var rear_left_wheel: VehicleWheel3D = $RearLeftWheel if has_node("RearLeftWheel") else null
@onready var rear_right_wheel: VehicleWheel3D = $RearRightWheel if has_node("RearRightWheel") else null
@onready var driver_camera: Camera3D = $DriverCamera if has_node("DriverCamera") else null
@onready var entry_point: Marker3D = $EntryPoint if has_node("EntryPoint") else null

# Signals
signal health_changed(current: float, maximum: float)
signal destroyed()
signal player_entered(player: Node3D)
signal player_exited(player: Node3D)
signal gear_changed(gear: int)
signal horn_honked()

func _ready() -> void:
	add_to_group("vehicle")
	current_health = max_health
	
	# Setup physics
	mass = _get_vehicle_mass()
	
	# Create vehicle visuals if none exist
	if not has_node("BodyMesh"):
		_create_vehicle_mesh()
	
	# Setup wheels if they don't exist
	_setup_wheels()
	
	# Setup lights
	_setup_lights()
	
	# Start engine sound (placeholder)
	engine_running = true

func _get_vehicle_mass() -> float:
	match vehicle_type:
		VehicleType.SEDAN: return 1500.0
		VehicleType.SPORTS: return 1300.0
		VehicleType.SUV: return 2200.0
		VehicleType.MUSCLE: return 1800.0
		VehicleType.TRUCK: return 4000.0
		VehicleType.MOTORCYCLE: return 200.0
	return 1500.0

func _create_vehicle_mesh() -> void:
	# Create realistic car body based on vehicle type
	var dimensions = _get_vehicle_dimensions()
	
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "BodyMesh"
	
	# Main body
	var body_shape = BoxMesh.new()
	body_shape.size = Vector3(dimensions.width, dimensions.height * 0.4, dimensions.length)
	body_mesh.mesh = body_shape
	
	# Random color
	var colors = [
		Color(0.1, 0.1, 0.1),    # Black
		Color(0.9, 0.9, 0.9),    # White
		Color(0.7, 0.1, 0.1),    # Red
		Color(0.1, 0.2, 0.5),    # Blue
		Color(0.3, 0.3, 0.3),    # Gray
		Color(0.6, 0.5, 0.2),    # Gold
		Color(0.1, 0.4, 0.2),    # Green
	]
	
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = colors[randi() % colors.size()]
	body_material.metallic = 0.8
	body_material.roughness = 0.3
	body_mesh.material_override = body_material
	body_mesh.position.y = dimensions.height * 0.3
	add_child(body_mesh)
	
	# Cabin/Windows
	var cabin = MeshInstance3D.new()
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(dimensions.width * 0.9, dimensions.height * 0.35, dimensions.length * 0.5)
	cabin.mesh = cabin_mesh
	
	var glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.2, 0.25, 0.3, 0.5)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.1
	glass_material.roughness = 0.1
	cabin.material_override = glass_material
	cabin.position = Vector3(0, dimensions.height * 0.55, -dimensions.length * 0.1)
	add_child(cabin)
	
	# Hood
	var hood = MeshInstance3D.new()
	var hood_mesh = BoxMesh.new()
	hood_mesh.size = Vector3(dimensions.width * 0.95, 0.15, dimensions.length * 0.35)
	hood.mesh = hood_mesh
	hood.material_override = body_material
	hood.position = Vector3(0, dimensions.height * 0.45, dimensions.length * 0.28)
	add_child(hood)
	
	# Trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(dimensions.width * 0.95, 0.2, dimensions.length * 0.25)
	trunk.mesh = trunk_mesh
	trunk.material_override = body_material
	trunk.position = Vector3(0, dimensions.height * 0.4, -dimensions.length * 0.35)
	add_child(trunk)
	
	# Bumpers
	var bumper_mat = StandardMaterial3D.new()
	bumper_mat.albedo_color = Color(0.15, 0.15, 0.15)
	bumper_mat.metallic = 0.5
	bumper_mat.roughness = 0.6
	
	var front_bumper = MeshInstance3D.new()
	var bumper_mesh = BoxMesh.new()
	bumper_mesh.size = Vector3(dimensions.width, 0.15, 0.15)
	front_bumper.mesh = bumper_mesh
	front_bumper.material_override = bumper_mat
	front_bumper.position = Vector3(0, 0.2, dimensions.length * 0.5)
	add_child(front_bumper)
	
	var rear_bumper = MeshInstance3D.new()
	rear_bumper.mesh = bumper_mesh
	rear_bumper.material_override = bumper_mat
	rear_bumper.position = Vector3(0, 0.2, -dimensions.length * 0.5)
	add_child(rear_bumper)

func _get_vehicle_dimensions() -> Dictionary:
	match vehicle_type:
		VehicleType.SEDAN:
			return {"length": 4.8, "width": 1.8, "height": 1.4, "wheelbase": 2.8}
		VehicleType.SPORTS:
			return {"length": 4.4, "width": 2.0, "height": 1.2, "wheelbase": 2.5}
		VehicleType.SUV:
			return {"length": 5.0, "width": 2.0, "height": 1.9, "wheelbase": 3.0}
		VehicleType.MUSCLE:
			return {"length": 4.9, "width": 1.9, "height": 1.35, "wheelbase": 2.9}
		VehicleType.TRUCK:
			return {"length": 6.5, "width": 2.4, "height": 2.8, "wheelbase": 4.0}
		VehicleType.MOTORCYCLE:
			return {"length": 2.2, "width": 0.8, "height": 1.1, "wheelbase": 1.5}
	return {"length": 4.8, "width": 1.8, "height": 1.4, "wheelbase": 2.8}

func _setup_wheels() -> void:
	var dims = _get_vehicle_dimensions()
	var wheel_radius = 0.35
	var wheel_width = 0.22
	
	# Create wheel mesh for visual
	var wheel_mesh = CylinderMesh.new()
	wheel_mesh.height = wheel_width
	wheel_mesh.top_radius = wheel_radius
	wheel_mesh.bottom_radius = wheel_radius
	
	var tire_material = StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.15, 0.15, 0.15)
	tire_material.roughness = 0.9
	
	# Front Left Wheel
	if not front_left_wheel:
		front_left_wheel = VehicleWheel3D.new()
		front_left_wheel.name = "FrontLeftWheel"
		front_left_wheel.use_as_steering = true
		front_left_wheel.position = Vector3(-dims.width * 0.45, 0, dims.wheelbase * 0.4)
		front_left_wheel.wheel_radius = wheel_radius
		front_left_wheel.wheel_rest_length = 0.15
		front_left_wheel.suspension_stiffness = 50.0
		front_left_wheel.damping_compression = 2.0
		front_left_wheel.damping_relaxation = 3.0
		front_left_wheel.wheel_friction_slip = 1.2
		add_child(front_left_wheel)
		
		var fl_mesh = MeshInstance3D.new()
		fl_mesh.mesh = wheel_mesh
		fl_mesh.material_override = tire_material
		fl_mesh.rotation_degrees.z = 90
		front_left_wheel.add_child(fl_mesh)
	
	# Front Right Wheel
	if not front_right_wheel:
		front_right_wheel = VehicleWheel3D.new()
		front_right_wheel.name = "FrontRightWheel"
		front_right_wheel.use_as_steering = true
		front_right_wheel.position = Vector3(dims.width * 0.45, 0, dims.wheelbase * 0.4)
		front_right_wheel.wheel_radius = wheel_radius
		front_right_wheel.wheel_rest_length = 0.15
		front_right_wheel.suspension_stiffness = 50.0
		front_right_wheel.damping_compression = 2.0
		front_right_wheel.damping_relaxation = 3.0
		front_right_wheel.wheel_friction_slip = 1.2
		add_child(front_right_wheel)
		
		var fr_mesh = MeshInstance3D.new()
		fr_mesh.mesh = wheel_mesh
		fr_mesh.material_override = tire_material
		fr_mesh.rotation_degrees.z = 90
		front_right_wheel.add_child(fr_mesh)
	
	# Rear Left Wheel
	if not rear_left_wheel:
		rear_left_wheel = VehicleWheel3D.new()
		rear_left_wheel.name = "RearLeftWheel"
		rear_left_wheel.use_as_traction = true
		rear_left_wheel.position = Vector3(-dims.width * 0.45, 0, -dims.wheelbase * 0.4)
		rear_left_wheel.wheel_radius = wheel_radius
		rear_left_wheel.wheel_rest_length = 0.15
		rear_left_wheel.suspension_stiffness = 55.0
		rear_left_wheel.damping_compression = 2.5
		rear_left_wheel.damping_relaxation = 3.5
		rear_left_wheel.wheel_friction_slip = 1.0
		add_child(rear_left_wheel)
		
		var rl_mesh = MeshInstance3D.new()
		rl_mesh.mesh = wheel_mesh
		rl_mesh.material_override = tire_material
		rl_mesh.rotation_degrees.z = 90
		rear_left_wheel.add_child(rl_mesh)
	
	# Rear Right Wheel
	if not rear_right_wheel:
		rear_right_wheel = VehicleWheel3D.new()
		rear_right_wheel.name = "RearRightWheel"
		rear_right_wheel.use_as_traction = true
		rear_right_wheel.position = Vector3(dims.width * 0.45, 0, -dims.wheelbase * 0.4)
		rear_right_wheel.wheel_radius = wheel_radius
		rear_right_wheel.wheel_rest_length = 0.15
		rear_right_wheel.suspension_stiffness = 55.0
		rear_right_wheel.damping_compression = 2.5
		rear_right_wheel.damping_relaxation = 3.5
		rear_right_wheel.wheel_friction_slip = 1.0
		add_child(rear_right_wheel)
		
		var rr_mesh = MeshInstance3D.new()
		rr_mesh.mesh = wheel_mesh
		rr_mesh.material_override = tire_material
		rr_mesh.rotation_degrees.z = 90
		rear_right_wheel.add_child(rr_mesh)

func _setup_lights() -> void:
	var dims = _get_vehicle_dimensions()
	
	# Headlights
	for i in range(2):
		var headlight = SpotLight3D.new()
		headlight.name = "Headlight" + str(i)
		headlight.light_color = Color(1.0, 0.98, 0.9)
		headlight.light_energy = 3.0
		headlight.spot_range = 40.0
		headlight.spot_angle = 35.0
		headlight.position = Vector3(-0.5 + i, 0.5, dims.length * 0.48)
		headlight.rotation_degrees.x = -10
		headlight.visible = false  # Off by default
		headlights.append(headlight)
		add_child(headlight)
	
	# Brake lights
	for i in range(2):
		var brake_light = OmniLight3D.new()
		brake_light.name = "BrakeLight" + str(i)
		brake_light.light_color = Color(1.0, 0.1, 0.1)
		brake_light.light_energy = 0.0
		brake_light.omni_range = 3.0
		brake_light.position = Vector3(-0.6 + i * 1.2, 0.4, -dims.length * 0.48)
		brake_lights.append(brake_light)
		add_child(brake_light)

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	
	# Calculate current speed
	current_speed_kmh = linear_velocity.length() * 3.6  # m/s to km/h
	
	if is_player_controlled and current_driver:
		_handle_player_input()
	elif is_ai_controlled:
		_handle_ai_input()
	
	_apply_vehicle_physics(delta)
	_update_engine(delta)
	_update_lights()

func _handle_player_input() -> void:
	# Steering
	steering_input = Input.get_axis("steer_right", "steer_left")
	if steering_input == 0:
		steering_input = Input.get_axis("move_right", "move_left")
	
	# Throttle/Brake
	throttle_input = Input.get_axis("brake", "accelerate")
	if throttle_input == 0:
		throttle_input = -Input.get_axis("move_back", "move_forward")
	
	# Separate brake input
	brake_input = Input.get_action_strength("brake")
	if brake_input == 0:
		brake_input = Input.get_action_strength("move_back") if throttle_input >= 0 else 0.0
	
	# Handbrake
	handbrake_input = Input.is_action_pressed("handbrake") or Input.is_action_pressed("jump")
	
	# Horn
	if Input.is_action_just_pressed("horn"):
		horn_honked.emit()
	
	# Headlights toggle
	if Input.is_action_just_pressed("lights"):
		_toggle_headlights()
	
	# Exit vehicle
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		if current_speed_kmh < 10:  # Can only exit when slow enough
			_eject_driver()

func _handle_ai_input() -> void:
	# AI driving logic - simple for now
	# Will be expanded by traffic AI system
	pass

func _apply_vehicle_physics(delta: float) -> void:
	# Smooth steering
	var target_steering = steering_input * steering_limit
	steering = lerp(steering, target_steering, steering_speed * delta)
	
	# Engine force based on throttle and gear
	var drive_force = 0.0
	if throttle_input > 0:
		drive_force = throttle_input * max_engine_force
		
		# Limit force at high speeds
		var speed_factor = 1.0 - (current_speed_kmh / top_speed_kmh)
		speed_factor = clamp(speed_factor, 0.0, 1.0)
		drive_force *= speed_factor
		
		# Reverse gear
		if current_gear == 0:
			drive_force *= -0.5
	elif throttle_input < 0:
		# Reverse or brake
		if current_speed_kmh < 5:
			# Start reversing
			current_gear = 0
			drive_force = throttle_input * max_engine_force * 0.5
		else:
			# Brake
			brake_input = -throttle_input
	
	engine_force = drive_force
	
	# Braking
	var total_brake = brake_input * max_brake_force
	if handbrake_input:
		total_brake = max_brake_force
		# Reduce rear wheel grip for drifting
		if rear_left_wheel:
			rear_left_wheel.wheel_friction_slip = 0.4
		if rear_right_wheel:
			rear_right_wheel.wheel_friction_slip = 0.4
	else:
		# Restore grip
		if rear_left_wheel:
			rear_left_wheel.wheel_friction_slip = 1.0
		if rear_right_wheel:
			rear_right_wheel.wheel_friction_slip = 1.0
	
	brake = total_brake
	
	# Auto transmission
	if automatic_transmission and throttle_input > 0:
		_auto_shift()

func _auto_shift() -> void:
	var optimal_rpm = max_rpm * 0.7
	
	if current_rpm > max_rpm * 0.9 and current_gear < 6:
		current_gear += 1
		gear_changed.emit(current_gear)
	elif current_rpm < max_rpm * 0.3 and current_gear > 1:
		current_gear -= 1
		gear_changed.emit(current_gear)

func _update_engine(delta: float) -> void:
	if not engine_running:
		current_rpm = 0
		return
	
	# Calculate RPM based on wheel speed and gear
	var wheel_rpm = 0.0
	if rear_left_wheel and rear_right_wheel:
		wheel_rpm = (abs(rear_left_wheel.get_rpm()) + abs(rear_right_wheel.get_rpm())) * 0.5
	
	var gear_ratio = gear_ratios[current_gear + 1]  # +1 because index 0 is reverse
	if gear_ratio != 0:
		current_rpm = wheel_rpm * gear_ratio * final_drive
	
	current_rpm = clamp(current_rpm, idle_rpm, max_rpm)
	
	# Engine braking when not accelerating
	if throttle_input == 0 and current_speed_kmh > 5:
		engine_force = -current_speed_kmh * 0.5

func _update_lights() -> void:
	# Brake lights
	var brake_intensity = 0.0
	if brake_input > 0.1 or brake > 0.1:
		brake_intensity = 2.0
	
	for light in brake_lights:
		light.light_energy = brake_intensity

func _toggle_headlights() -> void:
	for light in headlights:
		light.visible = not light.visible

func player_entered(player: Node3D) -> void:
	current_driver = player
	is_player_controlled = true
	is_ai_controlled = false
	
	# Switch to vehicle camera
	if driver_camera:
		driver_camera.current = true
	elif has_node("/root/GameManager"):
		# Use chase camera
		var cam = get_node("/root/GameManager").get_camera()
		if cam:
			cam.get_parent().global_position = global_position + Vector3(0, 3, 8)
	
	player_entered.emit(player)
	print("[Vehicle] Player entered: ", vehicle_name)

func player_exited(player: Node3D) -> void:
	current_driver = null
	is_player_controlled = false
	
	# Reset inputs
	steering_input = 0
	throttle_input = 0
	brake_input = 0
	handbrake_input = false
	steering = 0
	engine_force = 0
	brake = max_brake_force * 0.5  # Park brake
	
	if driver_camera:
		driver_camera.current = false
	
	player_exited.emit(player)
	print("[Vehicle] Player exited: ", vehicle_name)

func _eject_driver() -> void:
	if current_driver and current_driver.has_method("_exit_vehicle"):
		current_driver._exit_vehicle()

func take_damage(amount: float, impact_point: Vector3 = Vector3.ZERO, damage_type: String = "collision") -> void:
	if is_destroyed:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	# Determine damage zone
	var local_impact = to_local(impact_point)
	if local_impact.z > 0:
		front_damage += amount * 0.5
	else:
		rear_damage += amount * 0.5
	
	if local_impact.x < 0:
		left_damage += amount * 0.5
	else:
		right_damage += amount * 0.5
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_destroy()

func _destroy() -> void:
	is_destroyed = true
	engine_running = false
	
	# Eject driver if present
	if current_driver:
		_eject_driver()
	
	# Visual damage
	if body_mesh:
		var mat = body_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.1, 0.1, 0.1)
	
	# Explosion effect placeholder
	destroyed.emit()
	
	if EventBus:
		EventBus.vehicle_destroyed.emit(self)

func repair(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	front_damage = max(0, front_damage - amount * 0.25)
	rear_damage = max(0, rear_damage - amount * 0.25)
	left_damage = max(0, left_damage - amount * 0.25)
	right_damage = max(0, right_damage - amount * 0.25)
	
	is_destroyed = false
	engine_running = true
	
	health_changed.emit(current_health, max_health)

# Getters
func get_speed_kmh() -> float:
	return current_speed_kmh

func get_speed_mph() -> float:
	return current_speed_kmh * 0.621371

func get_rpm() -> float:
	return current_rpm

func get_gear() -> int:
	return current_gear

func get_health_percent() -> float:
	return current_health / max_health

func is_occupied() -> bool:
	return current_driver != null

func get_driver() -> Node3D:
	return current_driver
