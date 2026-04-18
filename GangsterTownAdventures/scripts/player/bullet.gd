extends CharacterBody3D
# Bullet with tracer visual

@export var damage = 10
@export var speed_val = 100.0
@export var lifetime = 3.0

var direction = Vector3.ZERO
var shooter: Node3D = null  # Set by whoever fires; bullet won't damage its owner
var spawn_immunity_time = 0.05  # Brief immunity period after spawn to prevent self-hits
var spawn_timer = 0.0
var is_active = false  # Don't check collisions until fully spawned

func _ready():
	add_to_group("bullet")
	# Set collision layer to 2 (bullets) and mask to 1 (world/characters but not player initially)
	collision_layer = 2
	collision_mask = 1 | 4 | 8  # World, NPCs, Vehicles - NOT player layer
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	_build_tracer()
	spawn_timer = spawn_immunity_time

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
	is_active = true

func _physics_process(delta):
	# Spawn immunity period - don't check collisions yet
	if spawn_timer > 0:
		spawn_timer -= delta
		# Still move the bullet but don't check collisions
		global_position += velocity * delta
		return
	
	if not is_active:
		return
		
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		# Never damage the entity that fired this bullet or its children
		if shooter:
			if collider == shooter:
				return
			if shooter.is_ancestor_of(collider):
				return
			if collider.is_ancestor_of(shooter):
				return
			# Also check if collider is part of the player's model
			if collider.is_in_group("player"):
				return
			# Check if collider has same parent as shooter (siblings)
			if collider.get_parent() == shooter or (shooter.get_parent() and collider.get_parent() == shooter.get_parent()):
				return
				
		# Never damage other bullets
		if collider and collider.is_in_group("bullet"):
			return
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage)
			_spawn_hit_effect(collision.get_position(), collider)
		else:
			_spawn_hit_effect(collision.get_position(), collider)
		queue_free()

func _spawn_hit_effect(pos: Vector3, collider: Node = null):
	# Use VFX manager for enhanced effects
	if VFX:
		var surface_type = "concrete"
		# Determine surface type based on collider
		if collider:
			if collider.is_in_group("npc") or collider.is_in_group("pedestrian") or collider.is_in_group("enemy"):
				surface_type = "flesh"
			elif collider.is_in_group("vehicle"):
				surface_type = "metal"
			elif collider.name.to_lower().contains("wood"):
				surface_type = "wood"
		VFX.create_bullet_impact(pos, Vector3.UP, surface_type)
	else:
		# Fallback basic effect
		var scene = get_tree().current_scene
		if not scene:
			return
		var flash = OmniLight3D.new()
		scene.add_child(flash)
		flash.global_position = pos
		flash.omni_range = 3.5
		flash.light_energy = 3.0
		flash.light_color = Color(1.0, 0.6, 0.1)
		get_tree().create_timer(0.08).timeout.connect(flash.queue_free)
