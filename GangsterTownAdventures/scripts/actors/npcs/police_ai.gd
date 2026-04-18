# police_ai.gd
# GTA-style police AI with wanted level response, pursuit, and combat
extends NPCBase

class_name PoliceAI

# Police states
enum PoliceState { PATROLLING, INVESTIGATING, PURSUING, IN_COMBAT, ARRESTING, CALLING_BACKUP }

var current_state: PoliceState = PoliceState.PATROLLING

# Police settings
@export var patrol_radius := 50.0
@export var pursue_speed := 7.0
@export var shoot_range := 25.0
@export var arrest_range := 2.0
@export var backup_call_threshold := 3  # Wanted level to call backup

# State tracking
var patrol_points: Array[Vector3] = []
var current_patrol_index := 0
var pursuit_timer := 0.0
var last_seen_timer := 0.0
var backup_called := false

# Combat
var shoot_cooldown := 0.0
var shots_fired := 0
var reload_timer := 0.0
var is_reloading := false

# Arrest
var arrest_progress := 0.0

# Wanted level reference
var current_wanted_level := 0

func _ready() -> void:
	super._ready()
	npc_type = NPCType.POLICE
	max_health = 150.0
	current_health = 150.0
	damage = 25.0
	vision_range = 50.0
	
	# Generate patrol route
	_generate_patrol_route()
	
	# Start patrolling
	_change_state(PoliceState.PATROLLING)

func _generate_patrol_route() -> void:
	patrol_points.clear()
	var spawn_pos = global_position
	
	# Create a patrol loop
	for i in range(4):
		var angle = (TAU / 4.0) * i + randf_range(-0.3, 0.3)
		var distance = randf_range(patrol_radius * 0.5, patrol_radius)
		var point = spawn_pos + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		patrol_points.append(point)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	super._physics_process(delta)
	
	# Update wanted level reference
	if GameManager:
		current_wanted_level = GameManager.get_wanted_level()
	
	_update_police_state(delta)
	_update_combat(delta)

func _update_police_state(delta: float) -> void:
	match current_state:
		PoliceState.PATROLLING:
			_process_patrolling(delta)
		PoliceState.INVESTIGATING:
			_process_investigating(delta)
		PoliceState.PURSUING:
			_process_pursuing(delta)
		PoliceState.IN_COMBAT:
			_process_combat(delta)
		PoliceState.ARRESTING:
			_process_arresting(delta)
		PoliceState.CALLING_BACKUP:
			_process_calling_backup(delta)

func _process_patrolling(delta: float) -> void:
	# Check for wanted player
	if current_wanted_level > 0:
		var player = _find_player()
		if player and _can_see(player):
			target = player
			if current_wanted_level >= 2:
				_change_state(PoliceState.PURSUING)
			else:
				_change_state(PoliceState.INVESTIGATING)
			return
	
	# Continue patrol
	if navigation_agent and navigation_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		if patrol_points.size() > 0:
			move_to(patrol_points[current_patrol_index])

func _process_investigating(delta: float) -> void:
	last_seen_timer += delta
	
	if target and _can_see(target):
		last_seen_timer = 0.0
		last_known_target_position = target.global_position
		
		# Escalate if wanted level high
		if current_wanted_level >= 2:
			_change_state(PoliceState.PURSUING)
			return
		
		# Move towards suspect
		var distance = global_position.distance_to(target.global_position)
		if distance > arrest_range * 3:
			move_to(target.global_position)
		else:
			stop_moving()
			# Face the suspect
			var direction = (target.global_position - global_position).normalized()
			rotation.y = atan2(direction.x, direction.z)
	else:
		# Lost sight
		if last_seen_timer > 10.0:
			target = null
			_change_state(PoliceState.PATROLLING)
		else:
			move_to(last_known_target_position)

func _process_pursuing(delta: float) -> void:
	pursuit_timer += delta
	
	if target:
		if _can_see(target):
			last_seen_timer = 0.0
			last_known_target_position = target.global_position
			
			var distance = global_position.distance_to(target.global_position)
			
			# Call backup at high wanted levels
			if current_wanted_level >= backup_call_threshold and not backup_called:
				_change_state(PoliceState.CALLING_BACKUP)
				return
			
			# Engage in combat if in range and wanted level is high enough
			if distance < shoot_range and current_wanted_level >= 3:
				_change_state(PoliceState.IN_COMBAT)
				return
			
			# Try to arrest if close and low wanted
			if distance < arrest_range * 2 and current_wanted_level < 3:
				_change_state(PoliceState.ARRESTING)
				return
			
			# Chase
			move_to(target.global_position)
		else:
			last_seen_timer += delta
			
			# Go to last known position
			move_to(last_known_target_position)
			
			# Lost pursuit
			if last_seen_timer > 20.0:
				target = null
				_change_state(PoliceState.PATROLLING)
				
				# Decrease wanted level since player escaped
				if GameManager and current_wanted_level > 0:
					# This should be handled by a wanted system, but basic implementation here
					pass
	else:
		_change_state(PoliceState.PATROLLING)

func _process_combat(delta: float) -> void:
	if not target or is_dead:
		_change_state(PoliceState.PATROLLING)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if _can_see(target):
		last_seen_timer = 0.0
		last_known_target_position = target.global_position
		
		# Face target
		var direction = (target.global_position - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)
		
		# Take cover or advance based on wanted level
		if distance > shoot_range:
			move_to(target.global_position)
		elif distance < 5.0:
			# Too close, back up
			var away = (global_position - target.global_position).normalized()
			move_to(global_position + away * 10)
		else:
			stop_moving()
	else:
		last_seen_timer += delta
		move_to(last_known_target_position)
		
		if last_seen_timer > 15.0:
			_change_state(PoliceState.PURSUING)

func _process_arresting(delta: float) -> void:
	if not target:
		_change_state(PoliceState.PATROLLING)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance > arrest_range * 3:
		# Target fled
		_change_state(PoliceState.PURSUING)
		return
	
	if distance > arrest_range:
		move_to(target.global_position)
	else:
		stop_moving()
		arrest_progress += delta
		
		# Arrest complete
		if arrest_progress > 3.0:
			if EventBus:
				EventBus.player_arrested.emit()
			arrest_progress = 0.0
			_change_state(PoliceState.PATROLLING)

func _process_calling_backup(delta: float) -> void:
	# Simulate radio call
	stop_moving()
	
	if pursuit_timer > 2.0:
		backup_called = true
		
		# Spawn additional police (would be handled by a spawner system)
		if EventBus:
			EventBus.emit_notification("Police backup called!", 3.0, "warning")
		
		_change_state(PoliceState.PURSUING)

func _update_combat(delta: float) -> void:
	if current_state != PoliceState.IN_COMBAT or not target:
		return
	
	# Reload
	if is_reloading:
		reload_timer += delta
		if reload_timer > 2.0:
			is_reloading = false
			reload_timer = 0.0
			shots_fired = 0
		return
	
	# Shooting
	shoot_cooldown -= delta
	
	if shoot_cooldown <= 0 and _can_see(target):
		var distance = global_position.distance_to(target.global_position)
		if distance < shoot_range:
			_shoot_at_target()
			shoot_cooldown = 0.3 + randf() * 0.2  # Vary fire rate
			
			# Reload after magazine
			shots_fired += 1
			if shots_fired >= 15:
				is_reloading = true

func _shoot_at_target() -> void:
	if not target:
		return
	
	# Spawn bullet
	var bullet_scene = preload("res://scenes/player/bullet.tscn") if ResourceLoader.exists("res://scenes/player/bullet.tscn") else null
	
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		var shoot_position = global_position + Vector3.UP * 1.5
		var direction = (target.global_position + Vector3.UP * 1.0 - shoot_position).normalized()
		
		# Add some inaccuracy based on distance and wanted level
		var inaccuracy = 0.05 - (current_wanted_level * 0.005)  # More accurate at high wanted
		direction.x += randf_range(-inaccuracy, inaccuracy)
		direction.y += randf_range(-inaccuracy, inaccuracy)
		direction.z += randf_range(-inaccuracy, inaccuracy)
		
		bullet.global_position = shoot_position
		bullet.global_transform.basis = Basis.looking_at(direction)
		bullet.damage = damage
		bullet.owner_node = self
		get_tree().current_scene.add_child(bullet)
		
		if EventBus:
			EventBus.shot_fired.emit(self, "pistol", shoot_position, direction)

func _change_state(new_state: PoliceState) -> void:
	var old_state = current_state
	current_state = new_state
	pursuit_timer = 0.0
	
	match new_state:
		PoliceState.PATROLLING:
			is_in_combat = false
			target = null
			backup_called = false
			if patrol_points.size() > 0:
				move_to(patrol_points[current_patrol_index])
		PoliceState.PURSUING:
			walk_speed = pursue_speed
		PoliceState.IN_COMBAT:
			is_in_combat = true
		PoliceState.ARRESTING:
			arrest_progress = 0.0

func _find_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player is Node3D:
			return player
	return null

# Respond to alerts
func respond_to_crime(crime_position: Vector3, crime_type: String) -> void:
	if is_dead or current_state == PoliceState.IN_COMBAT:
		return
	
	last_known_target_position = crime_position
	
	if current_state == PoliceState.PATROLLING:
		_change_state(PoliceState.INVESTIGATING)
		move_to(crime_position)

# Override damage to potentially increase wanted level
func take_damage(amount: float, attacker: Node3D, damage_type: String = "bullet") -> void:
	super.take_damage(amount, attacker, damage_type)
	
	# Attacking police increases wanted level
	if attacker and attacker.is_in_group("player"):
		if GameManager:
			GameManager.add_wanted_level(1)
		target = attacker
		
		if current_state != PoliceState.IN_COMBAT:
			_change_state(PoliceState.IN_COMBAT)

# Override to handle police death
func _die(killer: Node3D) -> void:
	# Killing police greatly increases wanted level
	if killer and killer.is_in_group("player"):
		if GameManager:
			GameManager.add_wanted_level(2)
	
	super._die(killer)
