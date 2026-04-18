extends CharacterBody3D
# NPC/Pedestrian — humanoid civilian

@export var speed = 4.0
@export var health = 50

const GRAVITY = -20.0
var is_dead = false
var wander_timer = 0.0
var wander_direction = Vector3.ZERO
var flee_target: Node3D = null
var char_model: Node3D

# Randomize appearance
var SHIRT_COLORS = [
	Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.8), Color(0.9, 0.9, 0.3),
	Color(0.3, 0.7, 0.3), Color(0.7, 0.4, 0.1), Color(0.9, 0.5, 0.7),
	Color(0.5, 0.5, 0.5), Color(1.0, 1.0, 1.0), Color(0.6, 0.1, 0.6),
]
var PANTS_COLORS = [
	Color(0.15, 0.15, 0.3), Color(0.3, 0.2, 0.1), Color(0.1, 0.1, 0.1),
	Color(0.4, 0.35, 0.3), Color(0.2, 0.2, 0.2),
]
var SKIN_TONES = [
	Color(0.95, 0.82, 0.68), Color(0.87, 0.72, 0.55), Color(0.72, 0.55, 0.40),
	Color(0.55, 0.38, 0.26), Color(0.40, 0.28, 0.18),
]

func _ready():
	add_to_group("npc")
	# Remove old MeshInstance3D if present
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_model()
	choose_new_direction()

func _build_model():
	var CharModel = load("res://scripts/utils/character_model.gd")
	char_model = Node3D.new()
	char_model.set_script(CharModel)
	char_model.skin_color = SKIN_TONES[randi() % SKIN_TONES.size()]
	char_model.shirt_color = SHIRT_COLORS[randi() % SHIRT_COLORS.size()]
	char_model.pants_color = PANTS_COLORS[randi() % PANTS_COLORS.size()]
	char_model.shoe_color = Color(0.15, 0.1, 0.05)
	var hair_choices = [Color(0.1, 0.07, 0.03), Color(0.6, 0.4, 0.15), Color(0.8, 0.7, 0.3), Color(0.2, 0.1, 0.05)]
	char_model.hair_color = hair_choices[randi() % hair_choices.size()]
	add_child(char_model)
	char_model.build()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var is_moving = false

	if flee_target and is_instance_valid(flee_target):
		var flee_dir = (global_position - flee_target.global_position).normalized()
		velocity.x = flee_dir.x * speed * 2.5
		velocity.z = flee_dir.z * speed * 2.5
		is_moving = true
		# Face flee direction
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

func choose_new_direction():
	# Walk along sidewalks (parallel to road grid at offset of ~4 units from road center)
	# Roads run at multiples of 22, so sidewalks are at those positions +/- 4
	var pos = global_position
	# Snap to nearest road direction and walk along it
	var nearest_road_x = round(pos.x / 22.0) * 22.0
	var nearest_road_z = round(pos.z / 22.0) * 22.0
	var dist_to_x_road = abs(pos.x - nearest_road_x)
	var dist_to_z_road = abs(pos.z - nearest_road_z)

	if dist_to_x_road < dist_to_z_road:
		# Near an X-aligned road, walk north/south along it
		wander_direction = Vector3(0, 0, [-1.0, 1.0][randi() % 2])
	else:
		# Near a Z-aligned road, walk east/west along it
		wander_direction = Vector3([-1.0, 1.0][randi() % 2], 0, 0)

	# Keep within city bounds
	if abs(pos.x) > 80: wander_direction.x = -sign(pos.x)
	if abs(pos.z) > 80: wander_direction.z = -sign(pos.z)
	wander_direction = wander_direction.normalized()
	wander_timer = randf_range(4.0, 10.0)

func take_damage(amount: int):
	health -= amount
	# Flee from attacker
	if Globals.player:
		flee_target = Globals.player
	if health <= 0:
		die()

func die():
	is_dead = true
	Globals.kills += 1
	Globals.add_money(50)
	queue_free()
