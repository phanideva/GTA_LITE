# player_controller.gd
# Modern GTA-style player controller with realistic movement and physics
# Completely redesigned for AAA-quality gameplay
extends CharacterBody3D

class_name PlayerController

# Movement constants (realistic GTA-style)
const WALK_SPEED := 2.5  # m/s
const JOG_SPEED := 4.5  # m/s
const SPRINT_SPEED := 7.5  # m/s
const CROUCH_SPEED := 1.8  # m/s
const ACCELERATION := 12.0  # m/s²
const DECELERATION := 15.0  # m/s²
const AIR_CONTROL := 0.3
const ROTATION_SPEED := 10.0

# Jump physics
const JUMP_VELOCITY := 5.5  # m/s
const GRAVITY := -18.0  # m/s² (slightly less than real for gameplay)
const FALL_MULTIPLIER := 1.5  # Faster falling
const MAX_FALL_SPEED := 50.0

# Camera settings
const CAMERA_DISTANCE := 4.0
const CAMERA_HEIGHT := 1.8
const CAMERA_SMOOTH := 8.0
const AIM_CAMERA_DISTANCE := 2.5
const AIM_CAMERA_HEIGHT := 1.6

# Health/Combat
@export var max_health := 200.0
@export var max_armor := 100.0
var current_health := 200.0
var current_armor := 0.0
var is_invincible := false
var invincibility_timer := 0.0

# State tracking
enum PlayerState { IDLE, WALKING, JOGGING, SPRINTING, JUMPING, FALLING, CROUCHING, AIMING, IN_VEHICLE, RAGDOLL, DEAD }
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# Movement tracking
var target_velocity := Vector3.ZERO
var current_speed := 0.0
var move_direction := Vector3.ZERO
var facing_direction := Vector3.FORWARD
var is_grounded := true
var was_grounded := true
var fall_start_height := 0.0

# Camera tracking
var camera_rotation := Vector2.ZERO  # x = yaw, y = pitch
var mouse_sensitivity := 0.002
var camera_target_position := Vector3.ZERO

# Combat
var is_aiming := false
var current_weapon_index := 0
var weapons: Array[Dictionary] = []

# Vehicle interaction
var nearby_vehicle: Node3D = null
var current_vehicle: Node3D = null
var is_driver := false

# Animation
var animation_blend := 0.0
var walk_cycle := 0.0

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var character_mesh: Node3D = $CharacterMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ground_ray: RayCast3D = $GroundRay
@onready var interaction_ray: RayCast3D = $InteractionRay

# Signals
signal state_changed(new_state: PlayerState, old_state: PlayerState)
signal health_changed(current: float, maximum: float)
signal armor_changed(current: float, maximum: float)
signal weapon_changed(weapon_data: Dictionary)
signal entered_vehicle(vehicle: Node3D)
signal exited_vehicle(vehicle: Node3D)

func _ready() -> void:
	# Setup camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialize weapons (melee default)
	weapons = [
		{"name": "Fists", "type": "melee", "damage": 15, "ammo": -1, "max_ammo": -1, "fire_rate": 2.0},
		{"name": "Pistol", "type": "pistol", "damage": 25, "ammo": 17, "max_ammo": 170, "fire_rate": 5.0},
		{"name": "SMG", "type": "smg", "damage": 18, "ammo": 30, "max_ammo": 300, "fire_rate": 12.0},
		{"name": "Rifle", "type": "rifle", "damage": 35, "ammo": 30, "max_ammo": 300, "fire_rate": 8.0},
		{"name": "Shotgun", "type": "shotgun", "damage": 12, "ammo": 8, "max_ammo": 80, "fire_rate": 1.5}
	]
	
	# Register with game manager
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").register_player(self)
		get_node("/root/GameManager").register_camera(camera)
	
	# Add to player group
	add_to_group("player")
	
	_setup_character()

func _setup_character() -> void:
	# Create realistic humanoid mesh if not exists
	if not has_node("CharacterMesh"):
		character_mesh = Node3D.new()
		character_mesh.name = "CharacterMesh"
		add_child(character_mesh)
		_build_realistic_character()

func _build_realistic_character() -> void:
	# Create a realistic humanoid character model
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.3, 0.3, 0.35)  # Dark jacket
	body_material.roughness = 0.8
	
	var skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = Color(0.87, 0.72, 0.62)  # Skin tone
	skin_material.roughness = 0.6
	
	var pants_material = StandardMaterial3D.new()
	pants_material.albedo_color = Color(0.15, 0.15, 0.2)  # Dark jeans
	pants_material.roughness = 0.9
	
	var shoe_material = StandardMaterial3D.new()
	shoe_material.albedo_color = Color(0.1, 0.1, 0.1)  # Black shoes
	shoe_material.roughness = 0.7
	
	var hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = Color(0.1, 0.08, 0.06)  # Dark hair
	hair_material.roughness = 0.95
	
	# Body measurements (realistic adult male - 1.8m tall)
	var total_height := 1.8
	var torso_height := 0.55
	var leg_height := 0.9
	var head_height := 0.24
	var shoulder_width := 0.46
	var hip_width := 0.36
	var arm_length := 0.65
	
	# Create body parts
	
	# TORSO (chest + abs)
	var torso = MeshInstance3D.new()
	var torso_mesh = BoxMesh.new()
	torso_mesh.size = Vector3(shoulder_width, torso_height, 0.25)
	torso.mesh = torso_mesh
	torso.material_override = body_material
	torso.position = Vector3(0, leg_height + torso_height * 0.5, 0)
	character_mesh.add_child(torso)
	
	# HIPS
	var hips = MeshInstance3D.new()
	var hips_mesh = BoxMesh.new()
	hips_mesh.size = Vector3(hip_width, 0.15, 0.22)
	hips.mesh = hips_mesh
	hips.material_override = pants_material
	hips.position = Vector3(0, leg_height + 0.05, 0)
	character_mesh.add_child(hips)
	
	# NECK
	var neck = MeshInstance3D.new()
	var neck_mesh = CylinderMesh.new()
	neck_mesh.height = 0.1
	neck_mesh.top_radius = 0.06
	neck_mesh.bottom_radius = 0.07
	neck.mesh = neck_mesh
	neck.material_override = skin_material
	neck.position = Vector3(0, leg_height + torso_height + 0.05, 0)
	character_mesh.add_child(neck)
	
	# HEAD
	var head = MeshInstance3D.new()
	var head_mesh = CapsuleMesh.new()
	head_mesh.height = head_height
	head_mesh.radius = 0.09
	head.mesh = head_mesh
	head.material_override = skin_material
	head.position = Vector3(0, leg_height + torso_height + 0.1 + head_height * 0.5, 0)
	character_mesh.add_child(head)
	
	# HAIR
	var hair = MeshInstance3D.new()
	var hair_mesh = CapsuleMesh.new()
	hair_mesh.height = 0.12
	hair_mesh.radius = 0.095
	hair.mesh = hair_mesh
	hair.material_override = hair_material
	hair.position = Vector3(0, leg_height + torso_height + 0.22, 0)
	character_mesh.add_child(hair)
	
	# LEFT ARM
	_create_arm(character_mesh, Vector3(-shoulder_width * 0.5 - 0.04, leg_height + torso_height * 0.85, 0), 
				arm_length, skin_material, body_material, false)
	
	# RIGHT ARM
	_create_arm(character_mesh, Vector3(shoulder_width * 0.5 + 0.04, leg_height + torso_height * 0.85, 0), 
				arm_length, skin_material, body_material, true)
	
	# LEFT LEG
	_create_leg(character_mesh, Vector3(-hip_width * 0.25, 0, 0), leg_height, 
				pants_material, shoe_material, skin_material)
	
	# RIGHT LEG
	_create_leg(character_mesh, Vector3(hip_width * 0.25, 0, 0), leg_height, 
				pants_material, shoe_material, skin_material)

func _create_arm(parent: Node3D, start_pos: Vector3, length: float, 
				 skin_mat: Material, clothes_mat: Material, is_right: bool) -> void:
	var upper_arm = MeshInstance3D.new()
	var upper_mesh = CapsuleMesh.new()
	upper_mesh.height = length * 0.45
	upper_mesh.radius = 0.045
	upper_arm.mesh = upper_mesh
	upper_arm.material_override = clothes_mat
	upper_arm.rotation_degrees.z = 5 if is_right else -5
	upper_arm.position = start_pos + Vector3(0, -length * 0.2, 0)
	parent.add_child(upper_arm)
	
	var lower_arm = MeshInstance3D.new()
	var lower_mesh = CapsuleMesh.new()
	lower_mesh.height = length * 0.4
	lower_mesh.radius = 0.035
	lower_arm.mesh = lower_mesh
	lower_arm.material_override = skin_mat
	lower_arm.position = start_pos + Vector3(0, -length * 0.55, 0)
	parent.add_child(lower_arm)
	
	var hand = MeshInstance3D.new()
	var hand_mesh = BoxMesh.new()
	hand_mesh.size = Vector3(0.08, 0.12, 0.03)
	hand.mesh = hand_mesh
	hand.material_override = skin_mat
	hand.position = start_pos + Vector3(0, -length * 0.85, 0)
	parent.add_child(hand)

func _create_leg(parent: Node3D, start_pos: Vector3, length: float, 
				 pants_mat: Material, shoe_mat: Material, skin_mat: Material) -> void:
	var thigh = MeshInstance3D.new()
	var thigh_mesh = CapsuleMesh.new()
	thigh_mesh.height = length * 0.48
	thigh_mesh.radius = 0.07
	thigh.mesh = thigh_mesh
	thigh.material_override = pants_mat
	thigh.position = start_pos + Vector3(0, length * 0.76, 0)
	parent.add_child(thigh)
	
	var shin = MeshInstance3D.new()
	var shin_mesh = CapsuleMesh.new()
	shin_mesh.height = length * 0.45
	shin_mesh.radius = 0.05
	shin.mesh = shin_mesh
	shin.material_override = pants_mat
	shin.position = start_pos + Vector3(0, length * 0.32, 0)
	parent.add_child(shin)
	
	var foot = MeshInstance3D.new()
	var foot_mesh = BoxMesh.new()
	foot_mesh.size = Vector3(0.1, 0.08, 0.26)
	foot.mesh = foot_mesh
	foot.material_override = shoe_mat
	foot.position = start_pos + Vector3(0, 0.04, 0.04)
	parent.add_child(foot)

func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.x * mouse_sensitivity
		camera_rotation.y -= event.relative.y * mouse_sensitivity
		camera_rotation.y = clamp(camera_rotation.y, deg_to_rad(-80), deg_to_rad(80))
	
	# Escape to release mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Weapon switching
	if event.is_action_pressed("weapon_next"):
		_switch_weapon(1)
	elif event.is_action_pressed("weapon_prev"):
		_switch_weapon(-1)
	
	# Vehicle interaction
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_try_interact()

func _physics_process(delta: float) -> void:
	if current_state == PlayerState.IN_VEHICLE or current_state == PlayerState.DEAD:
		return
	
	_handle_movement(delta)
	_update_state()
	_update_camera(delta)
	_update_animation(delta)
	_handle_combat(delta)
	_check_nearby_vehicles()
	
	# Update invincibility
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

func _handle_movement(delta: float) -> void:
	# Get input direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")
	input_dir = input_dir.limit_length(1.0)
	
	# Convert input to world direction relative to camera
	var camera_basis = camera_pivot.global_transform.basis
	var forward = -camera_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = camera_basis.x
	right.y = 0
	right = right.normalized()
	
	move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	
	# Determine target speed
	var target_speed := 0.0
	if input_dir.length() > 0.1:
		if Input.is_action_pressed("sprint") and input_dir.y < 0:  # Only sprint forward
			target_speed = SPRINT_SPEED
		elif Input.is_action_pressed("crouch"):
			target_speed = CROUCH_SPEED
		elif input_dir.length() > 0.7:
			target_speed = JOG_SPEED
		else:
			target_speed = WALK_SPEED
	
	# Check ground
	was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	# Track fall height
	if not is_grounded and was_grounded:
		fall_start_height = global_position.y
	
	# Apply gravity
	if not is_grounded:
		var gravity_force = GRAVITY
		if velocity.y < 0:
			gravity_force *= FALL_MULTIPLIER  # Faster falling
		velocity.y += gravity_force * delta
		velocity.y = max(velocity.y, -MAX_FALL_SPEED)
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_grounded:
		velocity.y = JUMP_VELOCITY
		_change_state(PlayerState.JUMPING)
	
	# Calculate horizontal velocity
	var control_amount = ACCELERATION if is_grounded else ACCELERATION * AIR_CONTROL
	
	if input_dir.length() > 0.1:
		target_velocity = move_direction * target_speed
		
		# Smoothly rotate character to face movement direction
		if move_direction.length() > 0.1 and not is_aiming:
			facing_direction = facing_direction.lerp(move_direction, ROTATION_SPEED * delta)
			character_mesh.rotation.y = atan2(facing_direction.x, facing_direction.z)
	else:
		target_velocity = Vector3.ZERO
	
	# Apply acceleration/deceleration
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	if target_velocity.length() > horizontal_vel.length():
		horizontal_vel = horizontal_vel.move_toward(target_velocity, control_amount * delta)
	else:
		horizontal_vel = horizontal_vel.move_toward(target_velocity, DECELERATION * delta)
	
	velocity.x = horizontal_vel.x
	velocity.z = horizontal_vel.z
	
	current_speed = Vector2(velocity.x, velocity.z).length()
	
	move_and_slide()
	
	# Fall damage check
	if is_grounded and not was_grounded:
		var fall_height = fall_start_height - global_position.y
		if fall_height > 5.0:
			var damage = (fall_height - 5.0) * 15.0
			take_damage(damage, null, "fall")

func _update_state() -> void:
	var new_state = current_state
	
	if current_state == PlayerState.IN_VEHICLE or current_state == PlayerState.DEAD:
		return
	
	if not is_grounded:
		if velocity.y > 0:
			new_state = PlayerState.JUMPING
		else:
			new_state = PlayerState.FALLING
	elif is_aiming:
		new_state = PlayerState.AIMING
	elif Input.is_action_pressed("crouch"):
		new_state = PlayerState.CROUCHING
	elif current_speed < 0.5:
		new_state = PlayerState.IDLE
	elif current_speed < 3.0:
		new_state = PlayerState.WALKING
	elif current_speed < 5.5:
		new_state = PlayerState.JOGGING
	else:
		new_state = PlayerState.SPRINTING
	
	if new_state != current_state:
		_change_state(new_state)

func _change_state(new_state: PlayerState) -> void:
	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state, previous_state)

func _update_camera(delta: float) -> void:
	# Update camera pivot rotation
	camera_pivot.rotation.y = camera_rotation.x
	camera_pivot.rotation.x = camera_rotation.y
	
	# Adjust camera distance based on state
	var target_distance = CAMERA_DISTANCE
	var target_height = CAMERA_HEIGHT
	
	if is_aiming:
		target_distance = AIM_CAMERA_DISTANCE
		target_height = AIM_CAMERA_HEIGHT
	elif current_state == PlayerState.SPRINTING:
		target_distance = CAMERA_DISTANCE * 1.2
	
	camera_arm.spring_length = lerp(camera_arm.spring_length, target_distance, CAMERA_SMOOTH * delta)
	
	# Camera follows player smoothly
	camera_target_position = camera_target_position.lerp(global_position + Vector3.UP * target_height, CAMERA_SMOOTH * delta)
	camera_pivot.global_position = camera_target_position

func _update_animation(delta: float) -> void:
	# Simple procedural animation
	if current_speed > 0.5 and is_grounded:
		var speed_factor = current_speed / SPRINT_SPEED
		walk_cycle += delta * current_speed * 2.0
		
		# Bob character mesh slightly
		character_mesh.position.y = sin(walk_cycle * 2) * 0.02 * speed_factor
		
		# Slight lean when moving
		var lean_angle = sin(walk_cycle) * 2.0 * speed_factor
		character_mesh.rotation.z = deg_to_rad(lean_angle)
	else:
		character_mesh.position.y = lerp(character_mesh.position.y, 0.0, 10 * delta)
		character_mesh.rotation.z = lerp(character_mesh.rotation.z, 0.0, 10 * delta)

func _handle_combat(delta: float) -> void:
	# Aim mode
	is_aiming = Input.is_action_pressed("aim")
	
	if is_aiming:
		# Face camera direction when aiming
		var cam_forward = -camera.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		facing_direction = cam_forward
		character_mesh.rotation.y = atan2(facing_direction.x, facing_direction.z)
	
	# Shooting
	if Input.is_action_pressed("shoot"):
		_try_shoot()

func _try_shoot() -> void:
	if weapons.is_empty():
		return
	
	var weapon = weapons[current_weapon_index]
	if weapon["type"] == "melee":
		_do_melee_attack()
	else:
		if weapon["ammo"] != 0:  # -1 means infinite
			_fire_weapon()

func _do_melee_attack() -> void:
	# Melee hit detection
	var space = get_world_3d().direct_space_state
	var from = global_position + Vector3.UP * 1.2
	var to = from + facing_direction * 2.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 0b110  # NPCs and enemies
	
	var result = space.intersect_ray(query)
	if result and result.collider.has_method("take_damage"):
		result.collider.take_damage(weapons[current_weapon_index]["damage"], self, "melee")

func _fire_weapon() -> void:
	var weapon = weapons[current_weapon_index]
	
	# Spawn bullet from camera
	var bullet_scene = preload("res://scenes/player/bullet.tscn") if ResourceLoader.exists("res://scenes/player/bullet.tscn") else null
	
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = camera.global_position + camera.global_transform.basis.z * -0.5
		bullet.global_transform.basis = camera.global_transform.basis
		bullet.damage = weapon["damage"]
		bullet.owner_node = self
		get_tree().current_scene.add_child(bullet)
	
	# Reduce ammo
	if weapon["ammo"] > 0:
		weapon["ammo"] -= 1
		weapon_changed.emit(weapon)

func _switch_weapon(direction: int) -> void:
	current_weapon_index = wrapi(current_weapon_index + direction, 0, weapons.size())
	weapon_changed.emit(weapons[current_weapon_index])

func _check_nearby_vehicles() -> void:
	# Find nearby vehicles
	var vehicles = get_tree().get_nodes_in_group("vehicle")
	nearby_vehicle = null
	var closest_dist = 3.0  # Max interaction distance
	
	for vehicle in vehicles:
		if vehicle is Node3D:
			var dist = global_position.distance_to(vehicle.global_position)
			if dist < closest_dist:
				closest_dist = dist
				nearby_vehicle = vehicle

func _try_interact() -> void:
	if current_state == PlayerState.IN_VEHICLE:
		_exit_vehicle()
	elif nearby_vehicle:
		_enter_vehicle(nearby_vehicle)

func _enter_vehicle(vehicle: Node3D) -> void:
	if not vehicle:
		return
	
	current_vehicle = vehicle
	is_driver = true
	_change_state(PlayerState.IN_VEHICLE)
	
	# Hide player mesh
	character_mesh.visible = false
	collision_shape.disabled = true
	
	# Position player inside vehicle
	global_position = vehicle.global_position
	
	# Tell vehicle player entered
	if vehicle.has_method("player_entered"):
		vehicle.player_entered(self)
	
	entered_vehicle.emit(vehicle)
	
	if EventBus:
		EventBus.player_entered_vehicle.emit(vehicle)

func _exit_vehicle() -> void:
	if not current_vehicle:
		return
	
	var vehicle = current_vehicle
	
	# Find exit position
	var exit_offset = current_vehicle.global_transform.basis.x * -2.0
	var exit_position = current_vehicle.global_position + exit_offset
	exit_position.y += 0.5
	
	# Check for obstacles
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(current_vehicle.global_position + Vector3.UP, exit_position)
	query.exclude = [self, current_vehicle]
	
	var result = space.intersect_ray(query)
	if result:
		# Try other side
		exit_offset = current_vehicle.global_transform.basis.x * 2.0
		exit_position = current_vehicle.global_position + exit_offset
		exit_position.y += 0.5
	
	# Tell vehicle player is exiting
	if current_vehicle.has_method("player_exited"):
		current_vehicle.player_exited(self)
	
	# Reset player
	global_position = exit_position
	character_mesh.visible = true
	collision_shape.disabled = false
	velocity = Vector3.ZERO
	
	current_vehicle = null
	is_driver = false
	_change_state(PlayerState.IDLE)
	
	exited_vehicle.emit(vehicle)
	
	if EventBus:
		EventBus.player_exited_vehicle.emit(vehicle)

func take_damage(amount: float, attacker: Node3D, damage_type: String = "bullet") -> void:
	if is_invincible or current_state == PlayerState.DEAD:
		return
	
	# Armor absorbs damage
	var armor_absorbed = min(current_armor, amount * 0.5)
	current_armor -= armor_absorbed
	var health_damage = amount - armor_absorbed
	
	current_health -= health_damage
	current_health = max(0, current_health)
	
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)
	
	if EventBus:
		EventBus.damage_dealt.emit(attacker, self, amount, damage_type)
	
	if current_health <= 0:
		_die(attacker)
	else:
		# Brief invincibility
		is_invincible = true
		invincibility_timer = 0.2

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func add_armor(amount: float) -> void:
	current_armor = min(current_armor + amount, max_armor)
	armor_changed.emit(current_armor, max_armor)

func _die(killer: Node3D) -> void:
	_change_state(PlayerState.DEAD)
	
	if EventBus:
		EventBus.entity_killed.emit(killer, self)
		EventBus.player_died.emit(self)
	
	# Trigger game over after delay
	await get_tree().create_timer(3.0).timeout
	
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").change_state(get_node("/root/GameManager").GameState.GAME_OVER)

func respawn(position: Vector3) -> void:
	global_position = position
	current_health = max_health
	current_armor = 0
	velocity = Vector3.ZERO
	_change_state(PlayerState.IDLE)
	
	character_mesh.visible = true
	collision_shape.disabled = false
	
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)

# Getters
func get_current_weapon() -> Dictionary:
	if weapons.size() > 0:
		return weapons[current_weapon_index]
	return {}

func get_health_percent() -> float:
	return current_health / max_health

func get_armor_percent() -> float:
	return current_armor / max_armor

func is_in_vehicle() -> bool:
	return current_state == PlayerState.IN_VEHICLE

func get_vehicle() -> Node3D:
	return current_vehicle
