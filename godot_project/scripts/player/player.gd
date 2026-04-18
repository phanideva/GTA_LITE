extends CharacterBody3D
# Player Controller — 3rd Person GTA Style
# Camera orbits independently; player model faces movement direction

@export var walk_speed = 8.0
@export var sprint_speed = 18.0
@export var jump_force = 8.0
@export var mouse_sensitivity = 0.003

const GRAVITY = -20.0
const BULLET_SCENE = preload("res://scenes/player/bullet.tscn")

# State
var health = 200
var max_health = 200
var armor = 0
var max_armor = 100
var is_sprinting = false
var is_in_vehicle = false
var current_vehicle: Node3D = null
var is_dead = false
var death_timer = 0.0
var invincibility_timer = 0.0
var footstep_timer = 0.0

# Weapon system
enum Weapon { MELEE, PISTOL, RIFLE, SHOTGUN }
var current_weapon: int = Weapon.PISTOL
var ammo = { Weapon.PISTOL: 60, Weapon.RIFLE: 120, Weapon.SHOTGUN: 30 }
var weapon_damage = { Weapon.PISTOL: 25, Weapon.RIFLE: 40, Weapon.SHOTGUN: 80 }
var weapon_fire_rate = { Weapon.PISTOL: 0.3, Weapon.RIFLE: 0.1, Weapon.SHOTGUN: 0.7 }
var fire_cooldown = 0.0

# Camera — independent orbit (NOT attached to player rotation)
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

# Camera angles (independent from player body)
var cam_yaw = 0.0    # Horizontal orbit angle
var cam_pitch = 0.0  # Vertical tilt

# Character model
var char_model: Node3D
var model_root: Node3D
var model_target_angle = 0.0  # Smoothly rotate model to face movement

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Globals.player = self
	add_to_group("player")
	_build_player_model()
	# Reparent camera pivot to scene root so it doesn't inherit player rotation
	await get_tree().process_frame
	var pivot = camera_pivot
	var parent = get_parent()
	if pivot and parent:
		remove_child(pivot)
		parent.add_child(pivot)
		pivot.global_position = global_position + Vector3(0, 1.6, 0)

func _build_player_model():
	model_root = Node3D.new()
	model_root.name = "PlayerModel"
	add_child(model_root)

	var CharModel = load("res://scripts/utils/character_model.gd")
	char_model = Node3D.new()
	char_model.set_script(CharModel)
	char_model.skin_color = Color(0.85, 0.7, 0.55)
	char_model.shirt_color = Color(0.1, 0.1, 0.1)
	char_model.pants_color = Color(0.15, 0.15, 0.2)
	char_model.shoe_color = Color(0.2, 0.1, 0.05)
	char_model.hair_color = Color(0.1, 0.07, 0.03)
	char_model.accessory_type = "gun"
	model_root.add_child(char_model)
	char_model.build()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Camera orbits freely — does NOT rotate CharacterBody3D
		cam_yaw -= event.relative.x * mouse_sensitivity
		cam_pitch -= event.relative.y * mouse_sensitivity
		cam_pitch = clamp(cam_pitch, -PI / 4.0, PI / 3.0)

func _physics_process(delta):
	if Globals.game_state != "playing":
		return

	fire_cooldown -= delta
	invincibility_timer -= delta

	# Update camera orbit position (independent of body)
	camera_pivot.global_position = global_position + Vector3(0, 1.6, 0)
	camera_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)

	# Handle death
	if is_dead:
		death_timer -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		if death_timer <= 0:
			_respawn()
		return

	if is_in_vehicle:
		if current_vehicle:
			# Player position follows vehicle so camera tracks it
			global_position = current_vehicle.global_position + Vector3(0, 0.5, 0)
		if model_root:
			model_root.visible = false
		# Handle exit from inside vehicle
		if Input.is_action_just_pressed("interact") and current_vehicle:
			current_vehicle.exit_vehicle()
		return
	else:
		if model_root:
			model_root.visible = true

	handle_gravity(delta)
	handle_movement(delta)
	handle_jump()
	handle_combat()
	handle_interaction()
	handle_weapon_switch()
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0

func handle_movement(delta):
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):    input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):  input_dir.y += 1
	if Input.is_action_pressed("ui_left"):  input_dir.x -= 1
	if Input.is_action_pressed("ui_right"): input_dir.x += 1

	is_sprinting = Input.is_action_pressed("sprint")
	var spd = sprint_speed if is_sprinting else walk_speed
	var is_moving = input_dir != Vector2.ZERO

	if is_moving:
		input_dir = input_dir.normalized()
		# Movement is relative to CAMERA direction (not body)
		var cam_basis = camera_pivot.global_transform.basis
		var forward = -cam_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = cam_basis.x
		right.y = 0
		right = right.normalized()
		var move_dir = (forward * -input_dir.y + right * input_dir.x).normalized()

		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd

		# Rotate model to face movement direction (GTA-style smooth turn)
		model_target_angle = atan2(move_dir.x, move_dir.z)
		if model_root:
			model_root.rotation.y = lerp_angle(model_root.rotation.y, model_target_angle, delta * 12.0)

		# Walk animation
		if char_model:
			var anim_speed = 8.0 if is_sprinting else 5.0
			char_model.animate_walk(delta, anim_speed)
		
		# Footstep sounds
		footstep_timer -= delta
		if footstep_timer <= 0:
			SFX.play_sfx("footstep", 0.2)
			footstep_timer = 0.35 if is_sprinting else 0.5
	else:
		velocity.x = move_toward(velocity.x, 0, spd * 10 * delta)
		velocity.z = move_toward(velocity.z, 0, spd * 10 * delta)
		if char_model:
			char_model.reset_pose()
		footstep_timer = 0.0

func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

func handle_combat():
	if Input.is_action_just_pressed("shoot"):
		if current_weapon == Weapon.MELEE:
			melee_attack()
		else:
			shoot()
	if Input.is_action_just_pressed("melee"):
		melee_attack()

func handle_weapon_switch():
	if Input.is_action_just_pressed("weapon_1"): current_weapon = Weapon.MELEE
	if Input.is_action_just_pressed("weapon_2"): current_weapon = Weapon.PISTOL
	if Input.is_action_just_pressed("weapon_3"): current_weapon = Weapon.RIFLE
	if Input.is_action_just_pressed("weapon_4"): current_weapon = Weapon.SHOTGUN

func handle_interaction():
	if Input.is_action_just_pressed("interact"):
		if is_in_vehicle and current_vehicle:
			current_vehicle.exit_vehicle()
			return
		# Distance-based vehicle detection — XZ distance (ignore Y height difference)
		var closest_vehicle: Node3D = null
		var closest_dist = 7.0
		var p_xz = Vector2(global_position.x, global_position.z)
		# Check parked vehicles and motorcycles
		for v in get_tree().get_nodes_in_group("vehicle"):
			var v_xz = Vector2(v.global_position.x, v.global_position.z)
			var dist = p_xz.distance_to(v_xz)
			if dist < closest_dist:
				closest_dist = dist
				closest_vehicle = v
		# Check traffic cars (can be carjacked GTA-style!)
		for v in get_tree().get_nodes_in_group("traffic"):
			var v_xz = Vector2(v.global_position.x, v.global_position.z)
			var dist = p_xz.distance_to(v_xz)
			if dist < closest_dist:
				closest_dist = dist
				closest_vehicle = v
		if closest_vehicle and closest_vehicle.has_method("player_entered"):
			enter_vehicle(closest_vehicle)
			SFX.play_sfx("pickup")

func shoot():
	if fire_cooldown > 0:
		return
	var ammo_key = current_weapon
	if ammo.get(ammo_key, 0) <= 0:
		print("Out of ammo!")
		return
	ammo[ammo_key] -= 1
	fire_cooldown = weapon_fire_rate.get(current_weapon, 0.3)

	# Snap model to face camera direction when shooting
	if model_root:
		var cam_fwd = -camera_pivot.global_transform.basis.z
		cam_fwd.y = 0
		if cam_fwd.length() > 0.01:
			model_root.rotation.y = atan2(cam_fwd.x, cam_fwd.z)

	var bullet = BULLET_SCENE.instantiate()
	bullet.damage = weapon_damage.get(current_weapon, 25)
	get_parent().add_child(bullet)
	# Shoot from camera direction
	var shoot_origin = camera.global_position + (-camera.global_transform.basis.z * 1.5)
	bullet.global_position = shoot_origin
	var dir = -camera.global_transform.basis.z

	if current_weapon == Weapon.SHOTGUN:
		for i in range(6):
			var pellet = BULLET_SCENE.instantiate()
			pellet.damage = weapon_damage[Weapon.SHOTGUN] / 6
			get_parent().add_child(pellet)
			pellet.global_position = shoot_origin
			var spread = Vector3(randf_range(-0.1, 0.1), randf_range(-0.05, 0.05), 0)
			pellet.launch(dir + spread, 80.0)
		bullet.queue_free()
		_muzzle_flash()
		SFX.play_sfx("shotgun", 0.1)
		return

	bullet.launch(dir, 120.0)
	_muzzle_flash()
	# Play gunshot sound
	if current_weapon == Weapon.PISTOL:
		SFX.play_sfx("gunshot", 0.1)
	elif current_weapon == Weapon.RIFLE:
		SFX.play_sfx("gunshot", 0.2)
	elif current_weapon == Weapon.SHOTGUN:
		SFX.play_sfx("shotgun", 0.1)

func _muzzle_flash():
	var flash_pos = camera.global_position + (-camera.global_transform.basis.z * 1.2)

	var flash = OmniLight3D.new()
	flash.omni_range = 5.0
	flash.light_energy = 3.0
	flash.light_color = Color(1.0, 0.8, 0.3)
	get_parent().add_child(flash)
	flash.global_position = flash_pos
	get_tree().create_timer(0.06).timeout.connect(flash.queue_free)

	# Visual muzzle spark
	var spark = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.12
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 3.0
	sm.material = mat
	spark.mesh = sm
	get_parent().add_child(spark)
	spark.global_position = flash_pos + (-camera.global_transform.basis.z * 0.1)
	get_tree().create_timer(0.05).timeout.connect(spark.queue_free)

func melee_attack():
	SFX.play_sfx("melee", 0.15)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	query.shape = box
	query.transform.origin = global_position + (-camera_pivot.global_transform.basis.z.normalized() * 2)
	query.transform.origin.y = global_position.y
	query.exclude = [get_rid()]
	var results = space_state.intersect_shape(query)
	for hit in results:
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(35)

func take_damage(amount: int):
	if is_dead or invincibility_timer > 0:
		return
	# Armor absorbs damage first
	if armor > 0:
		var armor_absorb = min(armor, amount)
		armor -= armor_absorb
		amount -= armor_absorb
	health -= amount
	if health <= 0:
		health = 0
		die()

func die():
	if is_dead:
		return
	is_dead = true
	death_timer = 3.0  # Show WASTED for 3 seconds
	Globals.player_money = max(0, Globals.player_money - 200)
	Globals.wanted_level = 0
	SFX.play_sfx("death")
	# Notify HUD to show WASTED screen
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("show_wasted"):
			hud.show_wasted()
	print("WASTED!")

func _respawn():
	is_dead = false
	health = max_health
	armor = 0
	invincibility_timer = 5.0  # 5 seconds of invincibility after respawn
	# Respawn at nearest safe point (hospital locations near sidewalks)
	var spawn_points = [
		Vector3(22, 2, 22),
		Vector3(55, 2, 55),
		Vector3(-55, 2, -55),
	]
	var best = spawn_points[0]
	var best_dist = 9999.0
	for p in spawn_points:
		var d = p.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = p
	global_position = best
	# Dismiss WASTED screen
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("hide_wasted"):
			hud.hide_wasted()
	print("Respawned at hospital. Lost $200.")

func enter_vehicle(vehicle):
	is_in_vehicle = true
	current_vehicle = vehicle
	vehicle.player_entered(self)

func exit_vehicle():
	is_in_vehicle = false
	if current_vehicle:
		global_position = current_vehicle.global_position + Vector3(3, 1, 0)
		current_vehicle = null

func heal(amount: int):
	health = mini(health + amount, max_health)

func add_ammo(wtype: int, amount: int):
	ammo[wtype] = ammo.get(wtype, 0) + amount
