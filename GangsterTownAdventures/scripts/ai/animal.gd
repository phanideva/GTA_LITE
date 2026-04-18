extends CharacterBody3D
# Animal AI — dogs and cats that roam the city

@export var animal_type: String = "dog"  # "dog" or "cat"
@export var speed: float = 5.0
@export var health: int = 30

const GRAVITY = -20.0
var is_dead = false
var wander_dir = Vector3.ZERO
var wander_timer = 0.0
var flee_target: Node3D = null
var flee_timer = 0.0

func _ready():
	add_to_group("animal")
	_build_model()
	wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_timer = randf_range(2.0, 5.0)

func _build_model():
	if animal_type == "dog":
		_build_dog()
	else:
		_build_cat()

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat

func _build_dog():
	speed = 6.0
	var body_color = [Color(0.6, 0.4, 0.2), Color(0.3, 0.2, 0.1), Color(0.8, 0.7, 0.5), Color(0.15, 0.1, 0.08)][randi() % 4]

	# Body (horizontal box)
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.25, 0.22, 0.55)
	bm.material = _make_mat(body_color)
	body.mesh = bm
	body.position = Vector3(0, 0.3, 0)
	add_child(body)

	# Head
	var head = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.18, 0.16, 0.2)
	hm.material = _make_mat(body_color)
	head.mesh = hm
	head.position = Vector3(0, 0.38, 0.35)
	add_child(head)

	# Snout
	var snout = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.1, 0.08, 0.12)
	sm.material = _make_mat(body_color.darkened(0.2))
	snout.mesh = sm
	snout.position = Vector3(0, 0.34, 0.46)
	add_child(snout)

	# Nose
	var nose = MeshInstance3D.new()
	var nm = SphereMesh.new()
	nm.radius = 0.025
	nm.height = 0.04
	nm.material = _make_mat(Color(0.05, 0.02, 0.02))
	nose.mesh = nm
	nose.position = Vector3(0, 0.35, 0.52)
	add_child(nose)

	# Eyes
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.02
		em.height = 0.035
		em.material = _make_mat(Color(0.08, 0.05, 0.02))
		eye.mesh = em
		eye.position = Vector3(side * 0.06, 0.42, 0.42)
		add_child(eye)

	# Ears
	for side in [-1, 1]:
		var ear = MeshInstance3D.new()
		var earm = BoxMesh.new()
		earm.size = Vector3(0.06, 0.1, 0.04)
		earm.material = _make_mat(body_color.darkened(0.15))
		ear.mesh = earm
		ear.position = Vector3(side * 0.08, 0.48, 0.3)
		ear.rotation.z = side * 0.3
		add_child(ear)

	# Legs (4)
	for x_off in [-0.08, 0.08]:
		for z_off in [-0.18, 0.18]:
			var leg = MeshInstance3D.new()
			var lm = CylinderMesh.new()
			lm.top_radius = 0.035
			lm.bottom_radius = 0.03
			lm.height = 0.22
			lm.material = _make_mat(body_color)
			leg.mesh = lm
			leg.position = Vector3(x_off, 0.11, z_off)
			add_child(leg)

	# Tail
	var tail = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.02
	tm.bottom_radius = 0.015
	tm.height = 0.2
	tm.material = _make_mat(body_color)
	tail.mesh = tm
	tail.position = Vector3(0, 0.4, -0.3)
	tail.rotation.x = -0.8
	add_child(tail)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.35, 0.6)
	col.shape = shape
	col.position = Vector3(0, 0.25, 0)
	add_child(col)

func _build_cat():
	speed = 5.0
	var body_color = [Color(0.9, 0.5, 0.1), Color(0.2, 0.2, 0.2), Color(0.95, 0.95, 0.9), Color(0.4, 0.3, 0.2)][randi() % 4]

	# Body (smaller than dog)
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.16, 0.14, 0.35)
	bm.material = _make_mat(body_color)
	body.mesh = bm
	body.position = Vector3(0, 0.2, 0)
	add_child(body)

	# Head (rounder)
	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.09
	hm.height = 0.16
	hm.material = _make_mat(body_color)
	head.mesh = hm
	head.position = Vector3(0, 0.28, 0.22)
	add_child(head)

	# Eyes (green/yellow cat eyes)
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.018
		em.height = 0.025
		var eye_mat = _make_mat(Color(0.4, 0.8, 0.1))
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(0.2, 0.5, 0.05)
		eye_mat.emission_energy_multiplier = 0.2
		em.material = eye_mat
		eye.mesh = em
		eye.position = Vector3(side * 0.04, 0.3, 0.3)
		add_child(eye)

	# Ears (triangular-ish)
	for side in [-1, 1]:
		var ear = MeshInstance3D.new()
		var earm = CylinderMesh.new()
		earm.top_radius = 0.005
		earm.bottom_radius = 0.03
		earm.height = 0.06
		earm.material = _make_mat(body_color)
		ear.mesh = earm
		ear.position = Vector3(side * 0.055, 0.37, 0.2)
		ear.rotation.z = side * 0.2
		add_child(ear)

	# Legs (4 thin)
	for x_off in [-0.05, 0.05]:
		for z_off in [-0.12, 0.12]:
			var leg = MeshInstance3D.new()
			var lm = CylinderMesh.new()
			lm.top_radius = 0.025
			lm.bottom_radius = 0.02
			lm.height = 0.16
			lm.material = _make_mat(body_color)
			leg.mesh = lm
			leg.position = Vector3(x_off, 0.08, z_off)
			add_child(leg)

	# Tail (curved up)
	var tail = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.015
	tm.bottom_radius = 0.012
	tm.height = 0.25
	tm.material = _make_mat(body_color)
	tail.mesh = tm
	tail.position = Vector3(0, 0.28, -0.22)
	tail.rotation.x = -1.0
	add_child(tail)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.2, 0.25, 0.4)
	col.shape = shape
	col.position = Vector3(0, 0.18, 0)
	add_child(col)

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	flee_timer -= delta

	# Check for nearby player — flee if too close
	if Globals.player and global_position.distance_to(Globals.player.global_position) < 5.0:
		flee_target = Globals.player
		flee_timer = 3.0

	if flee_target and flee_timer > 0 and is_instance_valid(flee_target):
		var flee_dir = (global_position - flee_target.global_position).normalized()
		velocity.x = flee_dir.x * speed * 2.0
		velocity.z = flee_dir.z * speed * 2.0
		rotation.y = atan2(flee_dir.x, flee_dir.z)
	else:
		flee_target = null
		wander_timer -= delta
		if wander_timer <= 0:
			wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			wander_timer = randf_range(3.0, 8.0)
		velocity.x = wander_dir.x * speed * 0.5
		velocity.z = wander_dir.z * speed * 0.5
		if wander_dir.length() > 0.1:
			rotation.y = atan2(wander_dir.x, wander_dir.z)

	move_and_slide()

func take_damage(amount: int):
	health -= amount
	flee_target = Globals.player
	flee_timer = 5.0
	if health <= 0:
		die()

func die():
	is_dead = true
	queue_free()
