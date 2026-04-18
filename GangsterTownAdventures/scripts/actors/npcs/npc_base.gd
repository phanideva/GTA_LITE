# npc_base.gd
# Base class for all NPCs with realistic GTA-style behavior
extends CharacterBody3D

class_name NPCBase

# NPC Types
enum NPCType { CIVILIAN, POLICE, GANG_MEMBER, SHOP_KEEPER, STORY_CHARACTER }

@export var npc_type: NPCType = NPCType.CIVILIAN
@export var npc_name: String = "NPC"

# Movement
@export_group("Movement")
@export var walk_speed := 1.8
@export var run_speed := 5.0
@export var sprint_speed := 7.0
@export var turn_speed := 6.0

# Combat stats
@export_group("Combat")
@export var max_health := 100.0
var current_health := 100.0
@export var damage := 15.0
@export var attack_range := 2.0
@export var attack_cooldown := 1.0

# Perception
@export_group("Perception")
@export var vision_range := 30.0
@export var vision_angle := 120.0  # degrees
@export var hearing_range := 20.0

# State
var is_dead := false
var is_alerted := false
var is_fleeing := false
var is_in_combat := false
var alert_level := 0.0  # 0-100
var target: Node3D = null
var last_known_target_position := Vector3.ZERO

# Movement
var current_destination := Vector3.ZERO
var path: PackedVector3Array = []
var path_index := 0
var is_moving := false
var move_direction := Vector3.ZERO
var facing_direction := Vector3.FORWARD

# Animation
var walk_cycle := 0.0

# Timers
var attack_timer := 0.0
var alert_decay_timer := 0.0
var reaction_timer := 0.0

# Node references
var character_mesh: Node3D
var collision_shape: CollisionShape3D
var navigation_agent: NavigationAgent3D

# Signals
signal health_changed(current: float, maximum: float)
signal died(killer: Node3D)
signal alerted(source: Vector3)
signal spotted_player(player: Node3D)
signal lost_target()

func _ready() -> void:
	current_health = max_health
	
	# Add to appropriate groups
	add_to_group("npc")
	match npc_type:
		NPCType.CIVILIAN:
			add_to_group("civilian")
		NPCType.POLICE:
			add_to_group("police")
			add_to_group("enemy")
		NPCType.GANG_MEMBER:
			add_to_group("gang")
			add_to_group("enemy")
	
	# Setup navigation
	_setup_navigation()
	
	# Create character mesh
	_create_character_mesh()
	
	# Setup collision
	_setup_collision()

func _setup_navigation() -> void:
	if not has_node("NavigationAgent3D"):
		navigation_agent = NavigationAgent3D.new()
		navigation_agent.name = "NavigationAgent3D"
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 1.0
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.4
		add_child(navigation_agent)
	else:
		navigation_agent = $NavigationAgent3D

func _setup_collision() -> void:
	if not has_node("CollisionShape3D"):
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var capsule = CapsuleShape3D.new()
		capsule.height = 1.8
		capsule.radius = 0.3
		collision_shape.shape = capsule
		collision_shape.position.y = 0.9
		add_child(collision_shape)
	else:
		collision_shape = $CollisionShape3D

func _create_character_mesh() -> void:
	# Create realistic humanoid mesh
	character_mesh = Node3D.new()
	character_mesh.name = "CharacterMesh"
	add_child(character_mesh)
	
	# Get appearance based on NPC type
	var appearance = _get_npc_appearance()
	
	# Materials
	var skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = appearance.skin_color
	skin_material.roughness = 0.6
	
	var shirt_material = StandardMaterial3D.new()
	shirt_material.albedo_color = appearance.shirt_color
	shirt_material.roughness = 0.8
	
	var pants_material = StandardMaterial3D.new()
	pants_material.albedo_color = appearance.pants_color
	pants_material.roughness = 0.9
	
	var shoe_material = StandardMaterial3D.new()
	shoe_material.albedo_color = Color(0.1, 0.1, 0.1)
	shoe_material.roughness = 0.7
	
	var hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = appearance.hair_color
	hair_material.roughness = 0.95
	
	# Body measurements (realistic adult)
	var total_height := 1.75 + randf_range(-0.1, 0.15)
	var torso_height := 0.52
	var leg_height := 0.88
	var head_height := 0.22
	var shoulder_width := 0.42 + randf_range(-0.02, 0.04)
	var hip_width := 0.34
	
	# TORSO
	var torso = MeshInstance3D.new()
	var torso_mesh = BoxMesh.new()
	torso_mesh.size = Vector3(shoulder_width, torso_height, 0.22)
	torso.mesh = torso_mesh
	torso.material_override = shirt_material
	torso.position = Vector3(0, leg_height + torso_height * 0.5, 0)
	character_mesh.add_child(torso)
	
	# HIPS
	var hips = MeshInstance3D.new()
	var hips_mesh = BoxMesh.new()
	hips_mesh.size = Vector3(hip_width, 0.12, 0.2)
	hips.mesh = hips_mesh
	hips.material_override = pants_material
	hips.position = Vector3(0, leg_height + 0.04, 0)
	character_mesh.add_child(hips)
	
	# NECK
	var neck = MeshInstance3D.new()
	var neck_mesh = CylinderMesh.new()
	neck_mesh.height = 0.08
	neck_mesh.top_radius = 0.05
	neck_mesh.bottom_radius = 0.06
	neck.mesh = neck_mesh
	neck.material_override = skin_material
	neck.position = Vector3(0, leg_height + torso_height + 0.04, 0)
	character_mesh.add_child(neck)
	
	# HEAD
	var head = MeshInstance3D.new()
	var head_mesh = CapsuleMesh.new()
	head_mesh.height = head_height
	head_mesh.radius = 0.085
	head.mesh = head_mesh
	head.material_override = skin_material
	head.position = Vector3(0, leg_height + torso_height + 0.08 + head_height * 0.5, 0)
	character_mesh.add_child(head)
	
	# HAIR
	var hair = MeshInstance3D.new()
	var hair_mesh = CapsuleMesh.new()
	hair_mesh.height = 0.1
	hair_mesh.radius = 0.09
	hair.mesh = hair_mesh
	hair.material_override = hair_material
	hair.position = Vector3(0, leg_height + torso_height + 0.2, 0)
	character_mesh.add_child(hair)
	
	# ARMS
	_create_arm(Vector3(-shoulder_width * 0.5 - 0.03, leg_height + torso_height * 0.82, 0), skin_material, shirt_material)
	_create_arm(Vector3(shoulder_width * 0.5 + 0.03, leg_height + torso_height * 0.82, 0), skin_material, shirt_material)
	
	# LEGS
	_create_leg(Vector3(-hip_width * 0.28, 0, 0), leg_height, pants_material, shoe_material)
	_create_leg(Vector3(hip_width * 0.28, 0, 0), leg_height, pants_material, shoe_material)

func _create_arm(start_pos: Vector3, skin_mat: Material, clothes_mat: Material) -> void:
	var arm_length := 0.58
	
	var upper_arm = MeshInstance3D.new()
	var upper_mesh = CapsuleMesh.new()
	upper_mesh.height = arm_length * 0.42
	upper_mesh.radius = 0.04
	upper_arm.mesh = upper_mesh
	upper_arm.material_override = clothes_mat
	upper_arm.position = start_pos + Vector3(0, -arm_length * 0.18, 0)
	character_mesh.add_child(upper_arm)
	
	var lower_arm = MeshInstance3D.new()
	var lower_mesh = CapsuleMesh.new()
	lower_mesh.height = arm_length * 0.38
	lower_mesh.radius = 0.032
	lower_arm.mesh = lower_mesh
	lower_arm.material_override = skin_mat
	lower_arm.position = start_pos + Vector3(0, -arm_length * 0.52, 0)
	character_mesh.add_child(lower_arm)
	
	var hand = MeshInstance3D.new()
	var hand_mesh = BoxMesh.new()
	hand_mesh.size = Vector3(0.07, 0.1, 0.025)
	hand.mesh = hand_mesh
	hand.material_override = skin_mat
	hand.position = start_pos + Vector3(0, -arm_length * 0.82, 0)
	character_mesh.add_child(hand)

func _create_leg(start_pos: Vector3, length: float, pants_mat: Material, shoe_mat: Material) -> void:
	var thigh = MeshInstance3D.new()
	var thigh_mesh = CapsuleMesh.new()
	thigh_mesh.height = length * 0.45
	thigh_mesh.radius = 0.065
	thigh.mesh = thigh_mesh
	thigh.material_override = pants_mat
	thigh.position = start_pos + Vector3(0, length * 0.75, 0)
	character_mesh.add_child(thigh)
	
	var shin = MeshInstance3D.new()
	var shin_mesh = CapsuleMesh.new()
	shin_mesh.height = length * 0.42
	shin_mesh.radius = 0.045
	shin.mesh = shin_mesh
	shin.material_override = pants_mat
	shin.position = start_pos + Vector3(0, length * 0.32, 0)
	character_mesh.add_child(shin)
	
	var foot = MeshInstance3D.new()
	var foot_mesh = BoxMesh.new()
	foot_mesh.size = Vector3(0.09, 0.07, 0.24)
	foot.mesh = foot_mesh
	foot.material_override = shoe_mat
	foot.position = start_pos + Vector3(0, 0.035, 0.035)
	character_mesh.add_child(foot)

func _get_npc_appearance() -> Dictionary:
	# Return appearance based on NPC type
	var skin_tones = [
		Color(0.95, 0.82, 0.72),  # Light
		Color(0.87, 0.72, 0.62),  # Medium light
		Color(0.75, 0.58, 0.45),  # Medium
		Color(0.55, 0.38, 0.28),  # Medium dark
		Color(0.35, 0.22, 0.15),  # Dark
	]
	
	var hair_colors = [
		Color(0.1, 0.08, 0.06),   # Black
		Color(0.3, 0.2, 0.1),     # Brown
		Color(0.6, 0.4, 0.2),     # Light brown
		Color(0.8, 0.7, 0.5),     # Blonde
		Color(0.4, 0.15, 0.1),    # Auburn
		Color(0.5, 0.5, 0.55),    # Gray
	]
	
	var appearance = {
		"skin_color": skin_tones[randi() % skin_tones.size()],
		"hair_color": hair_colors[randi() % hair_colors.size()],
		"shirt_color": Color.WHITE,
		"pants_color": Color(0.2, 0.2, 0.25)
	}
	
	match npc_type:
		NPCType.CIVILIAN:
			var shirt_colors = [
				Color(0.9, 0.9, 0.9), Color(0.2, 0.4, 0.7), Color(0.7, 0.2, 0.2),
				Color(0.2, 0.6, 0.3), Color(0.8, 0.6, 0.2), Color(0.5, 0.3, 0.6),
				Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1)
			]
			appearance.shirt_color = shirt_colors[randi() % shirt_colors.size()]
		NPCType.POLICE:
			appearance.shirt_color = Color(0.1, 0.15, 0.35)  # Dark blue
			appearance.pants_color = Color(0.1, 0.15, 0.35)
		NPCType.GANG_MEMBER:
			var gang_colors = [
				Color(0.7, 0.1, 0.1),  # Red gang
				Color(0.1, 0.2, 0.7),  # Blue gang
				Color(0.1, 0.6, 0.2),  # Green gang
				Color(0.6, 0.4, 0.1),  # Yellow gang
			]
			appearance.shirt_color = gang_colors[randi() % gang_colors.size()]
	
	return appearance

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_update_timers(delta)
	_update_perception(delta)
	_update_movement(delta)
	_update_animation(delta)

func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	
	if alert_level > 0 and not is_alerted:
		alert_decay_timer += delta
		if alert_decay_timer > 1.0:
			alert_level = max(0, alert_level - 5.0)
			alert_decay_timer = 0.0

func _update_perception(delta: float) -> void:
	# Check for player
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player is Node3D:
			if _can_see(player):
				_on_spotted_player(player)
				return
	
	# Lost sight of target
	if target and not _can_see(target):
		last_known_target_position = target.global_position
		target = null
		lost_target.emit()

func _can_see(other: Node3D) -> bool:
	var to_other = other.global_position - global_position
	var distance = to_other.length()
	
	# Distance check
	if distance > vision_range:
		return false
	
	# Angle check
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_other.normalized()))
	if angle > vision_angle * 0.5:
		return false
	
	# Raycast check for obstacles
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.5,
		other.global_position + Vector3.UP * 1.0
	)
	query.exclude = [self]
	query.collision_mask = 1  # World only
	
	var result = space.intersect_ray(query)
	if result and result.collider != other:
		return false
	
	return true

func _on_spotted_player(player: Node3D) -> void:
	target = player
	alert_level = 100.0
	is_alerted = true
	spotted_player.emit(player)

func _update_movement(delta: float) -> void:
	if not navigation_agent:
		return
	
	if is_moving and not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		direction.y = 0
		
		move_direction = direction
		
		# Rotate to face movement direction
		if direction.length() > 0.1:
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, turn_speed * delta)
		
		# Apply movement
		var speed = run_speed if is_fleeing or is_in_combat else walk_speed
		velocity = direction * speed
		
		# Apply gravity
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		
		move_and_slide()
	else:
		velocity = velocity.lerp(Vector3.ZERO, 10 * delta)
		move_and_slide()

func _update_animation(delta: float) -> void:
	var speed = Vector2(velocity.x, velocity.z).length()
	
	if speed > 0.5:
		walk_cycle += delta * speed * 2.0
		
		# Simple bob animation
		character_mesh.position.y = sin(walk_cycle * 2) * 0.015
		character_mesh.rotation.z = sin(walk_cycle) * 0.02
	else:
		character_mesh.position.y = lerp(character_mesh.position.y, 0.0, 10 * delta)
		character_mesh.rotation.z = lerp(character_mesh.rotation.z, 0.0, 10 * delta)

func move_to(destination: Vector3) -> void:
	current_destination = destination
	if navigation_agent:
		navigation_agent.target_position = destination
		is_moving = true

func stop_moving() -> void:
	is_moving = false
	velocity = Vector3.ZERO

func take_damage(amount: float, attacker: Node3D, damage_type: String = "bullet") -> void:
	if is_dead:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	
	health_changed.emit(current_health, max_health)
	
	# Alert on damage
	if not is_alerted:
		alert_level = 100.0
		is_alerted = true
		if attacker:
			target = attacker
			last_known_target_position = attacker.global_position
		alerted.emit(attacker.global_position if attacker else global_position)
	
	if current_health <= 0:
		_die(attacker)

func _die(killer: Node3D) -> void:
	is_dead = true
	is_moving = false
	
	# Disable collision
	if collision_shape:
		collision_shape.disabled = true
	
	# Fall down animation
	if character_mesh:
		character_mesh.rotation.x = -PI * 0.5
		character_mesh.position.y = 0.3
	
	died.emit(killer)
	
	if EventBus:
		EventBus.npc_killed.emit(self, killer)
	
	# Remove after delay
	await get_tree().create_timer(10.0).timeout
	queue_free()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func alert_to(source_position: Vector3) -> void:
	if is_dead:
		return
	
	var distance = global_position.distance_to(source_position)
	if distance < hearing_range:
		alert_level = min(100, alert_level + (1.0 - distance / hearing_range) * 50)
		last_known_target_position = source_position
		alerted.emit(source_position)

# Getters
func get_health_percent() -> float:
	return current_health / max_health

func is_hostile() -> bool:
	return npc_type == NPCType.POLICE or npc_type == NPCType.GANG_MEMBER
