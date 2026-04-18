extends CharacterBody3D
# Police AI — humanoid cop with blue uniform and badge

@export var speed = 12.0
@export var detect_range = 80.0
@export var health = 120

const GRAVITY = -20.0
var is_dead = false
var target: Node3D = null
var patrol_dir = Vector3.ZERO
var patrol_timer = 0.0
var shoot_cooldown = 0.0
var sight_blocked_timer = 0.0
var char_model: Node3D

func _ready():
	add_to_group("police")
	# Remove old cylinder mesh
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_model()
	patrol_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func _build_model():
	var CharModel = load("res://scripts/utils/character_model.gd")
	char_model = Node3D.new()
	char_model.set_script(CharModel)
	char_model.skin_color = Color(0.87, 0.72, 0.58)
	char_model.shirt_color = Color(0.1, 0.15, 0.45)   # Dark blue uniform
	char_model.pants_color = Color(0.08, 0.1, 0.3)    # Navy pants
	char_model.shoe_color = Color(0.05, 0.05, 0.05)   # Black boots
	char_model.hair_color = Color(0.15, 0.1, 0.05)
	char_model.hat_color = Color(0.1, 0.15, 0.45)     # Police cap
	char_model.accessory_type = "badge"
	add_child(char_model)
	char_model.build()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	shoot_cooldown -= delta
	update_target()

	var is_moving = false

	if target and Globals.wanted_level > 0:
		chase_target(delta)
		is_moving = true
		if Globals.wanted_level >= 3 and shoot_cooldown <= 0:
			shoot_at_player()
	else:
		patrol(delta)
		is_moving = velocity.length() > 0.5
		if Globals.wanted_level > 0:
			sight_blocked_timer += delta
			if sight_blocked_timer >= 10.0:
				Globals.wanted_level = max(0, Globals.wanted_level - 1)
				sight_blocked_timer = 0.0
		else:
			sight_blocked_timer = 0.0

	if char_model:
		if is_moving:
			char_model.animate_walk(delta, 5.0)
		else:
			char_model.reset_pose()

	move_and_slide()

func update_target():
	var player = Globals.player
	if player and player.global_position.distance_to(global_position) < detect_range:
		target = player
		sight_blocked_timer = 0.0
	else:
		target = null

func chase_target(_delta):
	if not target:
		return
	var direction = (target.global_position - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	rotation.y = atan2(direction.x, direction.z)
	if global_position.distance_to(target.global_position) < 2.0:
		arrest_player()

func shoot_at_player():
	if not target:
		return
	var bullet = preload("res://scenes/player/bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 1.5, 0)
	var dir = (target.global_position - global_position).normalized()
	bullet.launch(dir, 80.0)
	bullet.damage = 15
	shoot_cooldown = 1.5

func patrol(delta):
	patrol_timer -= delta
	if patrol_timer <= 0:
		patrol_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		patrol_timer = randf_range(3.0, 8.0)
	velocity.x = patrol_dir.x * (speed * 0.3)
	velocity.z = patrol_dir.z * (speed * 0.3)
	if patrol_dir.length() > 0.1:
		rotation.y = atan2(patrol_dir.x, patrol_dir.z)

func arrest_player():
	if target and target.has_method("take_damage"):
		Globals.wanted_level = 0
		target.take_damage(10)

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true
	Globals.kills += 1
	Globals.add_wanted_level(2)
	queue_free()
