# civilian_ai.gd
# GTA-style civilian AI with realistic wandering, fleeing, and reaction behaviors
extends NPCBase

class_name CivilianAI

# Civilian states
enum CivilianState { IDLE, WANDERING, WALKING_TO_DESTINATION, FLEEING, COWERING, CALLING_POLICE }

var current_state: CivilianState = CivilianState.IDLE

# Wander settings
@export var wander_radius := 30.0
@export var wander_wait_time := 3.0
@export var panic_duration := 15.0

# State timers
var state_timer := 0.0
var wander_timer := 0.0
var panic_timer := 0.0

# Destinations
var home_position := Vector3.ZERO
var wander_points: Array[Vector3] = []

# Reactions
var witnessed_crime := false
var reporting_crime := false
var flee_direction := Vector3.ZERO

func _ready() -> void:
	super._ready()
	npc_type = NPCType.CIVILIAN
	
	# Store spawn position as "home"
	home_position = global_position
	
	# Generate wander points
	_generate_wander_points()
	
	# Start wandering after a brief delay
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	_change_state(CivilianState.WANDERING)

func _generate_wander_points() -> void:
	wander_points.clear()
	
	for i in range(5):
		var angle = randf() * TAU
		var distance = randf_range(5, wander_radius)
		var point = home_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		wander_points.append(point)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	super._physics_process(delta)
	_update_civilian_state(delta)

func _update_civilian_state(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		CivilianState.IDLE:
			_process_idle(delta)
		CivilianState.WANDERING:
			_process_wandering(delta)
		CivilianState.WALKING_TO_DESTINATION:
			_process_walking(delta)
		CivilianState.FLEEING:
			_process_fleeing(delta)
		CivilianState.COWERING:
			_process_cowering(delta)
		CivilianState.CALLING_POLICE:
			_process_calling_police(delta)

func _process_idle(delta: float) -> void:
	wander_timer += delta
	
	if wander_timer > wander_wait_time:
		wander_timer = 0.0
		_change_state(CivilianState.WANDERING)
	
	# Random idle animations (look around, etc.)
	if randf() < 0.01:
		character_mesh.rotation.y += randf_range(-0.5, 0.5)

func _process_wandering(delta: float) -> void:
	# Pick a random wander point
	if not is_moving:
		if wander_points.size() > 0:
			var target_point = wander_points[randi() % wander_points.size()]
			move_to(target_point)
		else:
			_change_state(CivilianState.IDLE)
	
	# Check if reached destination
	if navigation_agent and navigation_agent.is_navigation_finished():
		stop_moving()
		_change_state(CivilianState.IDLE)

func _process_walking(delta: float) -> void:
	if navigation_agent and navigation_agent.is_navigation_finished():
		stop_moving()
		_change_state(CivilianState.IDLE)

func _process_fleeing(delta: float) -> void:
	panic_timer += delta
	
	# Keep running
	if not is_moving or (navigation_agent and navigation_agent.is_navigation_finished()):
		_find_flee_destination()
	
	# Stop fleeing after panic wears off
	if panic_timer > panic_duration:
		panic_timer = 0.0
		is_fleeing = false
		stop_moving()
		
		# Return home or wander
		if randf() < 0.5:
			move_to(home_position)
			_change_state(CivilianState.WALKING_TO_DESTINATION)
		else:
			_change_state(CivilianState.WANDERING)

func _process_cowering(delta: float) -> void:
	panic_timer += delta
	
	# Cower animation - crouch down
	character_mesh.scale.y = 0.7
	character_mesh.position.y = -0.2
	
	# Stop cowering after a while
	if panic_timer > panic_duration * 0.5:
		character_mesh.scale.y = 1.0
		character_mesh.position.y = 0.0
		panic_timer = 0.0
		_change_state(CivilianState.FLEEING)

func _process_calling_police(delta: float) -> void:
	# Simulate calling police
	if state_timer > 3.0:  # Call duration
		reporting_crime = false
		
		# Increase wanted level if player nearby
		if GameManager:
			GameManager.add_wanted_level(1)
		
		# Then flee
		_change_state(CivilianState.FLEEING)

func _change_state(new_state: CivilianState) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		CivilianState.FLEEING:
			is_fleeing = true
			_find_flee_destination()
		CivilianState.COWERING:
			stop_moving()
		CivilianState.CALLING_POLICE:
			stop_moving()
			reporting_crime = true

func _find_flee_destination() -> void:
	if not target:
		# Random direction
		flee_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	else:
		# Away from threat
		flee_direction = (global_position - target.global_position).normalized()
		flee_direction.y = 0
	
	var flee_distance = randf_range(20, 40)
	var flee_point = global_position + flee_direction * flee_distance
	move_to(flee_point)

# Reaction to events
func react_to_gunshot(source: Vector3) -> void:
	if is_dead:
		return
	
	var distance = global_position.distance_to(source)
	if distance < hearing_range * 2:  # Extended hearing for gunshots
		last_known_target_position = source
		
		# Different reactions based on distance and personality
		var reaction_roll = randf()
		
		if distance < 10:
			# Very close - immediate panic
			if reaction_roll < 0.7:
				_change_state(CivilianState.FLEEING)
			else:
				_change_state(CivilianState.COWERING)
		elif distance < 30:
			# Medium distance - mostly flee
			if reaction_roll < 0.5:
				_change_state(CivilianState.FLEEING)
			elif reaction_roll < 0.7:
				_change_state(CivilianState.CALLING_POLICE)
			else:
				_change_state(CivilianState.COWERING)
		else:
			# Far - alert but not panicking
			alert_level += 30
			witnessed_crime = true

func react_to_crime(crime_position: Vector3, crime_type: String) -> void:
	if is_dead:
		return
	
	var distance = global_position.distance_to(crime_position)
	
	if distance < vision_range:
		witnessed_crime = true
		last_known_target_position = crime_position
		
		# Decide reaction
		if crime_type == "murder" or crime_type == "assault":
			if randf() < 0.6:
				_change_state(CivilianState.FLEEING)
			else:
				_change_state(CivilianState.CALLING_POLICE)
		elif crime_type == "vehicle_theft":
			if randf() < 0.4:
				_change_state(CivilianState.CALLING_POLICE)
			else:
				alert_level += 40

func react_to_player_wanted(player: Node3D, wanted_level: int) -> void:
	if is_dead or wanted_level == 0:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance < vision_range:
		if wanted_level >= 3:
			# High wanted level - flee immediately
			target = player
			_change_state(CivilianState.FLEEING)
		elif wanted_level >= 1:
			# Low wanted level - alert and maybe call police
			alert_level += 20 * wanted_level
			if randf() < 0.2 * wanted_level:
				_change_state(CivilianState.CALLING_POLICE)

# Override parent perception to not attack
func _on_spotted_player(player: Node3D) -> void:
	# Civilians don't attack, but might react to wanted level
	if GameManager:
		var wanted = GameManager.get_wanted_level()
		if wanted > 0:
			react_to_player_wanted(player, wanted)

# Override take_damage to add civilian-specific reactions
func take_damage(amount: float, attacker: Node3D, damage_type: String = "bullet") -> void:
	super.take_damage(amount, attacker, damage_type)
	
	if not is_dead and current_state != CivilianState.FLEEING:
		target = attacker
		_change_state(CivilianState.FLEEING)
