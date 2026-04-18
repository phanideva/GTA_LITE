extends CharacterBody3D
# Gangster/Enemy AI — humanoid thug with dark clothes and gun

@export var speed = 10.0
@export var detect_range = 60.0
@export var health = 75

const GRAVITY = -20.0
var is_dead = false
var target: Node3D = null
var shoot_cooldown = 0.0
var has_alerted = false
var wander_dir = Vector3.ZERO
var wander_timer = 0.0
var char_model: Node3D

var GANG_SHIRTS = [
	Color(0.7, 0.1, 0.1), Color(0.1, 0.1, 0.1), Color(0.5, 0.0, 0.5),
	Color(0.6, 0.3, 0.0), Color(0.15, 0.4, 0.15),
]

func _ready():
	add_to_group("enemy")
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_model()
	wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_timer = randf_range(2.0, 6.0)

func _build_model():
	var CharModel = load("res://scripts/utils/character_model.gd")
	char_model = Node3D.new()
	char_model.set_script(CharModel)
	char_model.skin_color = Color(0.72, 0.55, 0.40)
	char_model.shirt_color = GANG_SHIRTS[randi() % GANG_SHIRTS.size()]
	char_model.pants_color = Color(0.1, 0.1, 0.1)
	char_model.shoe_color = Color(0.15, 0.1, 0.05)
	char_model.hair_color = Color(0.08, 0.05, 0.02)
	char_model.accessory_type = "gun"
	add_child(char_model)
	char_model.build()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	update_target()
	shoot_cooldown -= delta

	var is_moving = false

	if target:
		engage_target(delta)
		is_moving = true
	else:
		# Wander when idle
		wander_timer -= delta
		if wander_timer <= 0:
			wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			wander_timer = randf_range(3.0, 7.0)
		velocity.x = wander_dir.x * speed * 0.3
		velocity.z = wander_dir.z * speed * 0.3
		is_moving = true
		if wander_dir.length() > 0.1:
			rotation.y = atan2(wander_dir.x, wander_dir.z)

	if char_model:
		if is_moving:
			char_model.animate_walk(delta, 5.0)
		else:
			char_model.reset_pose()

	move_and_slide()

func update_target():
	var player = Globals.player
	if player and player.global_position.distance_to(global_position) < detect_range:
		if not has_alerted:
			Globals.add_wanted_level(1)
			has_alerted = true
		target = player
	else:
		target = null

func engage_target(_delta):
	if not target:
		return
	var direction = (target.global_position - global_position).normalized()
	if global_position.distance_to(target.global_position) > 5.0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	rotation.y = atan2(direction.x, direction.z)
	if shoot_cooldown <= 0 and global_position.distance_to(target.global_position) < 40.0:
		shoot_at_target(direction)

func shoot_at_target(direction: Vector3):
	var bullet = preload("res://scenes/player/bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 1.5, 0)
	bullet.launch(direction, 80.0)
	bullet.damage = 20
	shoot_cooldown = 1.2

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true
	Globals.kills += 1
	Globals.add_money(150)
	queue_free()
