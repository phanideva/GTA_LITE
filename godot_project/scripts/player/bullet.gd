extends CharacterBody3D
# Bullet with tracer visual

@export var damage = 10
@export var speed_val = 100.0
@export var lifetime = 3.0

var direction = Vector3.ZERO

func _ready():
	add_to_group("bullet")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	_build_tracer()

func _build_tracer():
	# Elongated yellow tracer mesh
	var tracer = MeshInstance3D.new()
	var tm = BoxMesh.new()
	tm.size = Vector3(0.03, 0.03, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2)
	mat.emission_energy_multiplier = 1.5
	tm.material = mat
	tracer.mesh = tm
	add_child(tracer)

	# Collision shape
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.05
	col.shape = shape
	add_child(col)

func launch(dir: Vector3, spd: float = 100.0):
	direction = dir.normalized()
	velocity = direction * spd
	# Orient tracer along direction
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(_delta):
	var collision = move_and_collide(velocity * get_physics_process_delta_time())
	if collision:
		var collider = collision.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage)
			_spawn_hit_effect(collision.get_position())
		queue_free()

func _spawn_hit_effect(pos: Vector3):
	var scene = get_tree().current_scene
	if not scene:
		return
	var flash = OmniLight3D.new()
	scene.add_child(flash)
	flash.global_position = pos
	flash.omni_range = 3.0
	flash.light_energy = 2.0
	flash.light_color = Color(1.0, 0.2, 0.1)
	get_tree().create_timer(0.1).timeout.connect(flash.queue_free)
