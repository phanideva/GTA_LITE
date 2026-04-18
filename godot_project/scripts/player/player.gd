extends CharacterBody3D
# Player Controller — 3rd Person GTA 3D

@export var walk_speed = 8.0
@export var sprint_speed = 18.0
@export var jump_force = 8.0
@export var mouse_sensitivity = 0.003

const GRAVITY = -20.0
const BULLET_SCENE = preload("res://scenes/player/bullet.tscn")

# State
var health = 100
var max_health = 100
var is_sprinting = false
var is_in_vehicle = false
var current_vehicle: Node3D = null

# Weapon system
enum Weapon { MELEE, PISTOL, RIFLE, SHOTGUN }
var current_weapon: int = Weapon.PISTOL
var ammo = { Weapon.PISTOL: 60, Weapon.RIFLE: 120, Weapon.SHOTGUN: 30 }
var weapon_damage = { Weapon.PISTOL: 25, Weapon.RIFLE: 40, Weapon.SHOTGUN: 80 }
var weapon_fire_rate = { Weapon.PISTOL: 0.3, Weapon.RIFLE: 0.1, Weapon.SHOTGUN: 0.7 }
var fire_cooldown = 0.0

# Camera — 3rd person
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

# Character model
var char_model: Node3D
var model_root: Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Globals.player = self
	add_to_group("player")
	_build_player_model()

func _build_player_model():
	model_root = Node3D.new()
	model_root.name = "PlayerModel"
	add_child(model_root)

	var CharModel = load("res://scripts/utils/character_model.gd")
	char_model = Node3D.new()
	char_model.set_script(CharModel)
	char_model.skin_color = Color(0.85, 0.7, 0.55)
	char_model.shirt_color = Color(0.1, 0.1, 0.1)  # Black jacket like GTA protagonist
	char_model.pants_color = Color(0.15, 0.15, 0.2)
	char_model.shoe_color = Color(0.2, 0.1, 0.05)
	char_model.hair_color = Color(0.1, 0.07, 0.03)
	char_model.accessory_type = "gun"
	model_root.add_child(char_model)
	char_model.build()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Horizontal: rotate entire player body
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical: tilt camera pivot up/down
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 4.0, PI / 3.0)

func _physics_process(delta):
	if Globals.game_state != "playing":
		return

	fire_cooldown -= delta

	if is_in_vehicle:
		if model_root:
			model_root.visible = false
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
		var forward = -global_transform.basis.z
		var right   = global_transform.basis.x
		var move_dir = (forward * -input_dir.y + right * input_dir.x)
		move_dir.y = 0
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		# Animate walking
		if char_model:
			var anim_speed = 8.0 if is_sprinting else 5.0
			char_model.animate_walk(delta, anim_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, spd * 10 * delta)
		velocity.z = move_toward(velocity.z, 0, spd * 10 * delta)
		if char_model:
			char_model.reset_pose()

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
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 4.0
		query.shape = sphere
		query.transform.origin = global_position
		query.exclude = [get_rid()]
		var results = space_state.intersect_shape(query)
		for hit in results:
			if hit.collider.is_in_group("vehicle"):
				enter_vehicle(hit.collider)
				return

func shoot():
	if fire_cooldown > 0:
		return
	var ammo_key = current_weapon
	if ammo.get(ammo_key, 0) <= 0:
		print("Out of ammo!")
		return
	ammo[ammo_key] -= 1
	fire_cooldown = weapon_fire_rate.get(current_weapon, 0.3)

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
		return

	bullet.launch(dir, 120.0)
	_muzzle_flash()

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
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	query.shape = box
	query.transform.origin = global_position + (-global_transform.basis.z * 2)
	query.exclude = [get_rid()]
	var results = space_state.intersect_shape(query)
	for hit in results:
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(35)

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	health = 100
	Globals.player_money = max(0, Globals.player_money - 200)
	global_position = Vector3(0, 2, 0)
	Globals.wanted_level = 0
	print("Wasted! Respawned at hospital. Lost $200.")

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
