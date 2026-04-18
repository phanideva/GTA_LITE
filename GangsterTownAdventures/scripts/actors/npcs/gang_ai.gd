# gang_ai.gd
# GTA-style gang member AI with territory defense, combat, and group behavior
extends NPCBase

class_name GangAI

# Gang states
enum GangState { IDLE, GUARDING, PATROLLING, HOSTILE, IN_COMBAT, FLEEING, DEAD }

var current_state: GangState = GangState.IDLE

# Gang settings
@export var gang_name: String = "Grove Street"
@export var gang_color: Color = Color(0.1, 0.6, 0.1)  # Default green
@export var territory_center: Vector3 = Vector3.ZERO
@export var territory_radius: float = 50.0

# Combat settings
@export var aggression_level: float = 0.5  # 0-1, how likely to start fights
@export var courage_level: float = 0.5  # 0-1, how likely to flee when hurt

# State tracking
var patrol_points: Array[Vector3] = []
var current_patrol_index := 0
var provoked := false
var provocation_timer := 0.0

# Combat
var shoot_cooldown := 0.0
var shots_fired := 0
var reload_timer := 0.0
var is_reloading := false
var cover_position: Vector3 = Vector3.ZERO
var in_cover := false

# Group behavior
var nearby_allies: Array[Node3D] = []
var group_alert := false

func _ready() -> void:
	super._ready()
	npc_type = NPCType.GANG_MEMBER
	max_health = 80.0
	current_health = 80.0
	damage = 20.0
	vision_range = 40.0
	
	# Set gang appearance
	_apply_gang_colors()
	
	# Set territory
	if territory_center == Vector3.ZERO:
		territory_center = global_position
	
	# Generate patrol route
	_generate_patrol_route()
	
	# Start idle/guarding
	_change_state(GangState.GUARDING if randf() < 0.5 else GangState.PATROLLING)

func _apply_gang_colors() -> void:
	# Find shirt mesh and apply gang color
	for child in character_mesh.get_children():
		if child is MeshInstance3D:
			var mat = child.material_override as StandardMaterial3D
			if mat and mat.albedo_color.g < 0.5 and mat.albedo_color.b < 0.5:
				# This is likely the shirt - apply gang color
				mat.albedo_color = gang_color
				break

func _generate_patrol_route() -> void:
	patrol_points.clear()
	
	# Patrol within territory
	for i in range(4):
		var angle = (TAU / 4.0) * i + randf_range(-0.5, 0.5)
		var distance = randf_range(territory_radius * 0.3, territory_radius * 0.8)
		var point = territory_center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		patrol_points.append(point)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	super._physics_process(delta)
	
	_update_gang_state(delta)
	_update_combat(delta)
	_update_group_awareness(delta)
	
	# Provocation decay
	if provoked and provocation_timer > 0:
		provocation_timer -= delta
		if provocation_timer <= 0:
			provoked = false

func _update_gang_state(delta: float) -> void:
	match current_state:
		GangState.IDLE:
			_process_idle(delta)
		GangState.GUARDING:
			_process_guarding(delta)
		GangState.PATROLLING:
			_process_patrolling(delta)
		GangState.HOSTILE:
			_process_hostile(delta)
		GangState.IN_COMBAT:
			_process_combat(delta)
		GangState.FLEEING:
			_process_fleeing(delta)

func _process_idle(delta: float) -> void:
	# Random chance to start patrolling or guarding
	if randf() < 0.01:
		if randf() < 0.5:
			_change_state(GangState.PATROLLING)
		else:
			_change_state(GangState.GUARDING)

func _process_guarding(delta: float) -> void:
	# Stay in place, watch for intruders
	stop_moving()
	
	# Look around occasionally
	if randf() < 0.005:
		character_mesh.rotation.y += randf_range(-0.5, 0.5)
	
	# Check for player in territory
	var player = _find_player()
	if player:
		var distance = global_position.distance_to(player.global_position)
		var in_territory = territory_center.distance_to(player.global_position) < territory_radius
		
		if in_territory and _can_see(player):
			# React based on aggression and provocation
			if provoked:
				target = player
				_change_state(GangState.IN_COMBAT)
			elif randf() < aggression_level * 0.1:
				# Random chance to become hostile
				target = player
				_change_state(GangState.HOSTILE)

func _process_patrolling(delta: float) -> void:
	# Check for player
	var player = _find_player()
	if player and _can_see(player):
		var in_territory = territory_center.distance_to(player.global_position) < territory_radius
		
		if in_territory and (provoked or randf() < aggression_level * 0.05):
			target = player
			_change_state(GangState.HOSTILE)
			return
	
	# Continue patrol
	if navigation_agent and navigation_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % max(1, patrol_points.size())
		if patrol_points.size() > 0:
			move_to(patrol_points[current_patrol_index])
		else:
			_change_state(GangState.GUARDING)

func _process_hostile(delta: float) -> void:
	if not target:
		_change_state(GangState.GUARDING)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	# Approach and threaten
	if distance > 15.0:
		move_to(target.global_position)
	elif distance > 5.0:
		# Stop and face target menacingly
		stop_moving()
		var direction = (target.global_position - global_position).normalized()
		rotation.y = atan2(direction.x, direction.z)
		
		# Chance to escalate to combat
		if provoked or randf() < aggression_level * 0.02:
			_change_state(GangState.IN_COMBAT)
	else:
		# Too close - definitely fight
		_change_state(GangState.IN_COMBAT)

func _process_combat(delta: float) -> void:
	if not target:
		_change_state(GangState.GUARDING)
		return
	
	# Check health - might flee
	if current_health < max_health * 0.2 and randf() > courage_level:
		_change_state(GangState.FLEEING)
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if _can_see(target):
		last_known_target_position = target.global_position
		
		# Face target
		var direction = (target.global_position - global_position).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)
		
		# Combat positioning
		if distance > shoot_range:
			move_to(target.global_position)
		elif distance < 8.0 and not in_cover:
			# Find cover or strafe
			var strafe_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			move_to(global_position + strafe_dir * 5.0)
		else:
			stop_moving()
	else:
		# Lost sight - go to last known position
		move_to(last_known_target_position)
		
		if navigation_agent and navigation_agent.is_navigation_finished():
			# Lost them completely
			target = null
			_change_state(GangState.GUARDING)

func _process_fleeing(delta: float) -> void:
	is_fleeing = true
	
	if target:
		var away = (global_position - target.global_position).normalized()
		away.y = 0
		
		var flee_point = global_position + away * 30.0
		move_to(flee_point)
	
	# Stop fleeing after getting far enough
	if target and global_position.distance_to(target.global_position) > 50:
		is_fleeing = false
		target = null
		_change_state(GangState.GUARDING)

func _update_combat(delta: float) -> void:
	if current_state != GangState.IN_COMBAT or not target:
		return
	
	# Reload
	if is_reloading:
		reload_timer += delta
		if reload_timer > 1.5:
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
			shoot_cooldown = 0.25 + randf() * 0.3
			
			shots_fired += 1
			if shots_fired >= 12:
				is_reloading = true

func _shoot_at_target() -> void:
	if not target:
		return
	
	var bullet_scene = preload("res://scenes/player/bullet.tscn") if ResourceLoader.exists("res://scenes/player/bullet.tscn") else null
	
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		var shoot_position = global_position + Vector3.UP * 1.4
		var direction = (target.global_position + Vector3.UP * 0.8 - shoot_position).normalized()
		
		# Accuracy based on state and skill
		var inaccuracy = 0.08
		direction.x += randf_range(-inaccuracy, inaccuracy)
		direction.y += randf_range(-inaccuracy, inaccuracy)
		direction.z += randf_range(-inaccuracy, inaccuracy)
		
		bullet.global_position = shoot_position
		bullet.global_transform.basis = Basis.looking_at(direction)
		bullet.damage = damage
		bullet.owner_node = self
		get_tree().current_scene.add_child(bullet)

func _update_group_awareness(delta: float) -> void:
	# Find nearby gang members
	nearby_allies.clear()
	var all_gangs = get_tree().get_nodes_in_group("gang")
	
	for gang_member in all_gangs:
		if gang_member != self and gang_member is Node3D:
			var distance = global_position.distance_to(gang_member.global_position)
			if distance < 30.0:
				nearby_allies.append(gang_member)
	
	# Alert nearby allies when in combat
	if current_state == GangState.IN_COMBAT and target:
		for ally in nearby_allies:
			if ally.has_method("alert_to_threat"):
				ally.alert_to_threat(target)

func alert_to_threat(threat: Node3D) -> void:
	if is_dead or current_state == GangState.IN_COMBAT:
		return
	
	target = threat
	provoked = true
	provocation_timer = 30.0
	
	if current_state != GangState.HOSTILE:
		_change_state(GangState.HOSTILE)

func _change_state(new_state: GangState) -> void:
	current_state = new_state
	
	match new_state:
		GangState.IN_COMBAT:
			is_in_combat = true
		GangState.FLEEING:
			is_fleeing = true
			is_in_combat = false
		_:
			is_in_combat = false
			is_fleeing = false

func _find_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player is Node3D:
			return player
	return null

# Override damage handling
func take_damage(amount: float, attacker: Node3D, damage_type: String = "bullet") -> void:
	super.take_damage(amount, attacker, damage_type)
	
	if not is_dead:
		# Getting attacked provokes the gang
		provoked = true
		provocation_timer = 60.0
		
		if attacker:
			target = attacker
			
			if current_state != GangState.IN_COMBAT:
				_change_state(GangState.IN_COMBAT)
			
			# Alert nearby allies
			for ally in nearby_allies:
				if ally.has_method("alert_to_threat"):
					ally.alert_to_threat(attacker)

# Override perception for gang-specific behavior
func _on_spotted_player(player: Node3D) -> void:
	# Gangs only attack if provoked or player is in their territory
	var in_territory = territory_center.distance_to(player.global_position) < territory_radius
	
	if in_territory:
		if provoked:
			target = player
			_change_state(GangState.IN_COMBAT)
		elif randf() < aggression_level * 0.2:
			target = player
			_change_state(GangState.HOSTILE)
