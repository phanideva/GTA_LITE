extends CharacterBody3D
# NPC/Pedestrian — humanoid civilian with LA social behaviors

@export var speed = 4.0
@export var health = 50

const GRAVITY = -20.0
var is_dead = false
var wander_timer = 0.0
var wander_direction = Vector3.ZERO
var flee_target: Node3D = null
var char_model: Node3D

# Social behavior system
enum SocialState { WALKING, IDLE, TALKING, ARGUING, FIGHTING, KISSING, PHONE_CALL, SITTING }
var social_state: SocialState = SocialState.WALKING
var social_timer: float = 0.0
var social_partner: Node3D = null
var social_anim_phase: float = 0.0
var social_cooldown: float = 0.0  # Time before next social interaction
var _audio_player: AudioStreamPlayer3D
var _voice_timer: float = 0.0

# LA-style civilian clothing — diverse US West Coast fashion
var SHIRT_COLORS = [
	Color(0.9, 0.9, 0.9), Color(0.1, 0.1, 0.1), Color(0.2, 0.5, 0.8),
	Color(0.8, 0.2, 0.2), Color(0.9, 0.7, 0.1), Color(0.3, 0.7, 0.3),
	Color(0.7, 0.4, 0.1), Color(0.5, 0.5, 0.5), Color(0.15, 0.25, 0.45),
	Color(0.65, 0.55, 0.45), Color(0.85, 0.75, 0.6), Color(0.4, 0.6, 0.7),
]
var PANTS_COLORS = [
	Color(0.15, 0.15, 0.3), Color(0.2, 0.18, 0.15), Color(0.1, 0.1, 0.1),
	Color(0.35, 0.32, 0.28), Color(0.22, 0.22, 0.22), Color(0.5, 0.45, 0.38),
	Color(0.15, 0.2, 0.35),
]
var SKIN_TONES = [
	Color(0.95, 0.82, 0.68), Color(0.87, 0.72, 0.55), Color(0.72, 0.55, 0.40),
	Color(0.55, 0.38, 0.26), Color(0.40, 0.28, 0.18), Color(0.82, 0.68, 0.50),
	Color(0.92, 0.78, 0.62),
]

func _ready():
	add_to_group("npc")
	# Remove old MeshInstance3D if present
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_model()
	choose_new_direction()
	social_cooldown = randf_range(8.0, 25.0)
	# 3D audio for social sounds
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.max_distance = 30.0
	_audio_player.unit_size = 6.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)
	_voice_timer = randf_range(3.0, 8.0)

func _build_model():
	char_model = CharacterModel.create_random_civilian()
	add_child(char_model)
	char_model.build()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	# Social cooldown countdown
	if social_cooldown > 0:
		social_cooldown -= delta

	# Handle social interactions
	if social_state != SocialState.WALKING and social_state != SocialState.IDLE:
		_process_social(delta)
		_update_voice_sounds(delta)
		move_and_slide()
		return

	# Check for new social interaction
	if social_state == SocialState.WALKING and social_cooldown <= 0 and flee_target == null:
		_try_start_social()

	var is_moving = false

	if flee_target and is_instance_valid(flee_target):
		var flee_dir = (global_position - flee_target.global_position).normalized()
		velocity.x = flee_dir.x * speed * 2.5
		velocity.z = flee_dir.z * speed * 2.5
		is_moving = true
		rotation.y = atan2(flee_dir.x, flee_dir.z)
	else:
		flee_target = null
		wander_timer -= delta
		if wander_timer <= 0:
			choose_new_direction()
		velocity.x = wander_direction.x * speed
		velocity.z = wander_direction.z * speed
		is_moving = wander_direction.length() > 0.1
		if is_moving:
			rotation.y = atan2(wander_direction.x, wander_direction.z)

	if char_model and is_moving:
		char_model.animate_walk(delta, 4.0)
	elif char_model:
		char_model.reset_pose()

	move_and_slide()

func _try_start_social():
	# Look for nearby NPCs to interact with
	var nearby = get_tree().get_nodes_in_group("npc")
	for npc in nearby:
		if npc == self or not is_instance_valid(npc):
			continue
		if npc.is_dead:
			continue
		var dist = global_position.distance_to(npc.global_position)
		if dist > 5.0 or dist < 1.0:
			continue
		# Check if the other NPC is also walking and available
		if npc.social_state != SocialState.WALKING:
			continue
		if npc.social_cooldown > 0:
			continue

		# Start a random social interaction
		var roll = randf()
		if roll < 0.30:
			_start_social(SocialState.TALKING, npc, randf_range(5.0, 12.0))
		elif roll < 0.48:
			_start_social(SocialState.ARGUING, npc, randf_range(4.0, 8.0))
		elif roll < 0.58:
			_start_social(SocialState.FIGHTING, npc, randf_range(3.0, 6.0))
		elif roll < 0.68:
			_start_social(SocialState.KISSING, npc, randf_range(3.0, 7.0))
		elif roll < 0.82:
			# Phone call (solo — no partner needed)
			social_state = SocialState.PHONE_CALL
			social_timer = randf_range(5.0, 15.0)
			social_partner = null
			velocity = Vector3.ZERO
		else:
			# Sitting (solo)
			social_state = SocialState.SITTING
			social_timer = randf_range(8.0, 20.0)
			social_partner = null
			velocity = Vector3.ZERO
		break

func _start_social(state: SocialState, partner: Node3D, duration: float):
	social_state = state
	social_partner = partner
	social_timer = duration
	social_anim_phase = 0.0
	velocity = Vector3.ZERO

	# Play social sound via 3D audio
	match state:
		SocialState.TALKING:
			_play_3d_sfx("npc_chatter", 0.15)
		SocialState.ARGUING:
			_play_3d_sfx("npc_argue", 0.25)
		SocialState.FIGHTING:
			_play_3d_sfx("npc_grunt", 0.3)

	# Partner also enters the social state
	if partner and partner.has_method("_join_social"):
		partner._join_social(state, self, duration)

	# Face each other
	var dir = (partner.global_position - global_position).normalized()
	rotation.y = atan2(dir.x, dir.z)

func _join_social(state: SocialState, initiator: Node3D, duration: float):
	social_state = state
	social_partner = initiator
	social_timer = duration
	social_anim_phase = 0.0
	velocity = Vector3.ZERO
	# Face the initiator
	var dir = (initiator.global_position - global_position).normalized()
	rotation.y = atan2(dir.x, dir.z)

func _process_social(delta: float):
	social_timer -= delta
	social_anim_phase += delta

	# Check if partner is still valid
	if social_partner and not is_instance_valid(social_partner):
		_end_social()
		return

	velocity = Vector3.ZERO

	match social_state:
		SocialState.TALKING:
			_animate_talking(delta)
		SocialState.ARGUING:
			_animate_arguing(delta)
		SocialState.FIGHTING:
			_animate_fighting(delta)
		SocialState.KISSING:
			_animate_kissing(delta)
		SocialState.PHONE_CALL:
			_animate_phone_call(delta)
		SocialState.SITTING:
			_animate_sitting(delta)

	if social_timer <= 0:
		_end_social()

func _end_social():
	social_state = SocialState.WALKING
	social_cooldown = randf_range(15.0, 35.0)
	social_partner = null
	social_anim_phase = 0.0
	if char_model:
		char_model.reset_pose()
	choose_new_direction()

func _animate_talking(delta: float):
	if not char_model:
		return
	# Head nod + subtle hand gestures
	if char_model.head_node:
		char_model.head_node.rotation.x = sin(social_anim_phase * 2.5) * 0.08
		char_model.head_node.rotation.y = sin(social_anim_phase * 1.2) * 0.06
	# One arm gesticulates
	if char_model.arm_r:
		char_model.arm_r.rotation.x = -0.5 + sin(social_anim_phase * 3.0) * 0.2
		char_model.arm_r.rotation.z = sin(social_anim_phase * 2.0) * 0.1
	if char_model.arm_l:
		char_model.arm_l.rotation.x = 0.0
	# Slight body sway
	if char_model.body_node:
		char_model.body_node.rotation.z = sin(social_anim_phase * 1.5) * 0.02

func _animate_arguing(delta: float):
	if not char_model:
		return
	# Aggressive arm waving, leaning forward
	if char_model.arm_r:
		char_model.arm_r.rotation.x = -0.8 + sin(social_anim_phase * 4.0) * 0.35
	if char_model.arm_l:
		char_model.arm_l.rotation.x = -0.6 + sin(social_anim_phase * 3.5 + 1.0) * 0.25
	# Head forward (leaning in aggressively)
	if char_model.head_node:
		char_model.head_node.rotation.x = -0.15 + sin(social_anim_phase * 5.0) * 0.08
	# Body forward lean
	if char_model.body_node:
		char_model.body_node.rotation.x = -0.06
		char_model.body_node.rotation.z = sin(social_anim_phase * 3.0) * 0.04

func _animate_fighting(delta: float):
	if not char_model:
		return
	# Punch animations — alternating arms
	var punch_phase = fmod(social_anim_phase, 1.5)
	if punch_phase < 0.3:
		# Right punch
		if char_model.arm_r:
			char_model.arm_r.rotation.x = -1.2
		if char_model.arm_l:
			char_model.arm_l.rotation.x = -0.3
	elif punch_phase < 0.6:
		# Reset
		if char_model.arm_r:
			char_model.arm_r.rotation.x = -0.3
		if char_model.arm_l:
			char_model.arm_l.rotation.x = -0.3
	elif punch_phase < 0.9:
		# Left punch
		if char_model.arm_l:
			char_model.arm_l.rotation.x = -1.2
		if char_model.arm_r:
			char_model.arm_r.rotation.x = -0.3
	else:
		if char_model.arm_r:
			char_model.arm_r.rotation.x = -0.3
		if char_model.arm_l:
			char_model.arm_l.rotation.x = -0.3

	# Body bob (dodge/weave)
	if char_model.body_node:
		char_model.body_node.rotation.z = sin(social_anim_phase * 4.0) * 0.08
		char_model.body_node.position.y = abs(sin(social_anim_phase * 3.0)) * 0.03
	# Legs shift stance
	if char_model.leg_l:
		char_model.leg_l.rotation.x = sin(social_anim_phase * 2.0) * 0.15
	if char_model.leg_r:
		char_model.leg_r.rotation.x = -sin(social_anim_phase * 2.0) * 0.15

func _animate_kissing(delta: float):
	if not char_model:
		return
	# Head tilted, arms around partner
	if char_model.head_node:
		char_model.head_node.rotation.x = -0.12
		char_model.head_node.rotation.z = 0.15
	if char_model.arm_r:
		char_model.arm_r.rotation.x = -0.7
		char_model.arm_r.rotation.z = -0.3
	if char_model.arm_l:
		char_model.arm_l.rotation.x = -0.7
		char_model.arm_l.rotation.z = 0.3
	# Subtle body sway together
	if char_model.body_node:
		char_model.body_node.rotation.z = sin(social_anim_phase * 0.8) * 0.03
		char_model.body_node.position.y = 0.0

func _animate_phone_call(delta: float):
	if not char_model:
		return
	# Right arm raised to ear (holding phone)
	if char_model.arm_r:
		char_model.arm_r.rotation.x = -2.2
		char_model.arm_r.rotation.z = -0.3
	if char_model.arm_l:
		char_model.arm_l.rotation.x = 0.0
	# Head tilted to phone
	if char_model.head_node:
		char_model.head_node.rotation.z = 0.08
		char_model.head_node.rotation.x = sin(social_anim_phase * 2.0) * 0.04
	# Slight pacing
	if char_model.body_node:
		char_model.body_node.rotation.z = sin(social_anim_phase * 1.0) * 0.02
	# Slow walk in place
	if char_model.leg_l:
		char_model.leg_l.rotation.x = sin(social_anim_phase * 1.5) * 0.08
	if char_model.leg_r:
		char_model.leg_r.rotation.x = -sin(social_anim_phase * 1.5) * 0.08

func _animate_sitting(delta: float):
	if not char_model:
		return
	# Legs bent at 90 degrees
	if char_model.leg_l:
		char_model.leg_l.rotation.x = -1.57
	if char_model.leg_r:
		char_model.leg_r.rotation.x = -1.57
	# Arms resting on thighs
	if char_model.arm_l:
		char_model.arm_l.rotation.x = -0.3
	if char_model.arm_r:
		char_model.arm_r.rotation.x = -0.3
	# Subtle head movement (looking around)
	if char_model.head_node:
		char_model.head_node.rotation.y = sin(social_anim_phase * 0.5) * 0.3
		char_model.head_node.rotation.x = sin(social_anim_phase * 0.3) * 0.05

func choose_new_direction():
	# Walk along sidewalks (parallel to road grid at offset of ~6 units from road center)
	# Roads run at multiples of 50, so sidewalks are at those positions +/- 6
	var pos = global_position
	# Snap to nearest road direction and walk along it
	var nearest_road_x = round(pos.x / 50.0) * 50.0
	var nearest_road_z = round(pos.z / 50.0) * 50.0
	var dist_to_x_road = abs(pos.x - nearest_road_x)
	var dist_to_z_road = abs(pos.z - nearest_road_z)

	if dist_to_x_road < dist_to_z_road:
		# Near an X-aligned road, walk north/south along it
		wander_direction = Vector3(0, 0, [-1.0, 1.0][randi() % 2])
	else:
		# Near a Z-aligned road, walk east/west along it
		wander_direction = Vector3([-1.0, 1.0][randi() % 2], 0, 0)

	# Keep within expanded LA city bounds
	if abs(pos.x) > 400: wander_direction.x = -sign(pos.x)
	if abs(pos.z) > 400: wander_direction.z = -sign(pos.z)
	wander_direction = wander_direction.normalized()
	wander_timer = randf_range(4.0, 10.0)

func take_damage(amount: int):
	health -= amount
	_spawn_blood_burst(global_position + Vector3(0, 1.2, 0))
	SFX.play_sfx("pain", 0.2)
	# Flee from attacker
	if Globals.player:
		flee_target = Globals.player
	if health <= 0:
		die()

func _spawn_blood_burst(pos: Vector3):
	var scene = get_tree().current_scene
	if not scene:
		return
	for i in range(5):
		var drop = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.045
		sm.height = 0.09
		var bmat = StandardMaterial3D.new()
		bmat.albedo_color = Color(0.72, 0.05, 0.05)
		sm.material = bmat
		drop.mesh = sm
		var dir = Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized()
		drop.global_position = pos
		scene.add_child(drop)
		var tween = scene.create_tween()
		tween.tween_property(drop, "global_position", pos + dir * randf_range(0.2, 0.55), 0.22)
		tween.tween_callback(drop.queue_free)

func die():
	is_dead = true
	Globals.kills += 1
	Globals.add_money(50)
	queue_free()

# ─── 3D Positional Audio ───────────────────────────────
func _play_3d_sfx(sfx_name: String, vol: float = 0.2):
	if not _audio_player or _audio_player.playing:
		return
	if SFX and SFX.has_method("_generate_sound"):
		var stream = SFX._generate_sound(sfx_name)
		if stream:
			_audio_player.stream = stream
			_audio_player.volume_db = linear_to_db(vol)
			_audio_player.play()

func _update_voice_sounds(delta: float):
	if social_state == SocialState.WALKING or social_state == SocialState.IDLE:
		return
	_voice_timer -= delta
	if _voice_timer <= 0:
		match social_state:
			SocialState.TALKING, SocialState.PHONE_CALL:
				_play_3d_sfx("npc_chatter", 0.12)
				_voice_timer = randf_range(2.0, 5.0)
			SocialState.ARGUING:
				_play_3d_sfx("npc_argue", 0.2)
				_voice_timer = randf_range(1.5, 3.5)
			SocialState.FIGHTING:
				_play_3d_sfx("npc_grunt", 0.25)
				_voice_timer = randf_range(0.8, 2.0)
			_:
				_voice_timer = randf_range(3.0, 8.0)
