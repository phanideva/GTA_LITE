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
