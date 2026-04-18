extends Node
# Visual Effects Manager — Procedural VFX for Gangster Town Adventures
# Handles explosions, muzzle flashes, sparks, smoke, blood, and more

class_name VFXManager

# ═══════════════════════ MUZZLE FLASH ═══════════════════════
func create_muzzle_flash(pos: Vector3, direction: Vector3, weapon_type: String = "pistol"):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	# Main flash light
	var flash = OmniLight3D.new()
	flash.omni_range = 6.0 if weapon_type == "shotgun" else 4.0
	flash.light_energy = 4.5
	flash.light_color = Color(1.0, 0.85, 0.4)
	parent.add_child(flash)
	flash.global_position = pos
	
	# Flash core (bright center)
	var core = _create_emissive_sphere(0.06, Color(1.0, 0.95, 0.7), 5.0)
	parent.add_child(core)
	core.global_position = pos
	
	# Flash burst rays
	for i in range(4):
		var ray = _create_flash_ray(direction)
		parent.add_child(ray)
		ray.global_position = pos
		ray.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		_fade_and_free(ray, 0.04)
	
	# Muzzle smoke puff
	var smoke = _create_smoke_puff(pos + direction * 0.3, 0.15)
	parent.add_child(smoke)
	
	_fade_and_free(flash, 0.07)
	_fade_and_free(core, 0.05)

# ═══════════════════════ EXPLOSION ═══════════════════════
func create_explosion(pos: Vector3, size: float = 1.0, with_shockwave: bool = true):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	# Explosion light (bright orange flash)
	var light = OmniLight3D.new()
	light.omni_range = 15.0 * size
	light.light_energy = 8.0
	light.light_color = Color(1.0, 0.6, 0.1)
	parent.add_child(light)
	light.global_position = pos
	
	# Fireball core
	var fireball = _create_fireball(size)
	parent.add_child(fireball)
	fireball.global_position = pos
	
	# Secondary fireballs
	for i in range(5):
		var offset = Vector3(
			randf_range(-size, size) * 0.5,
			randf_range(0, size) * 0.8,
			randf_range(-size, size) * 0.5
		)
		var fb = _create_fireball(size * randf_range(0.3, 0.6))
		parent.add_child(fb)
		fb.global_position = pos + offset
		_animate_fireball(fb, 0.2 + randf() * 0.3)
	
	# Flying debris
	for i in range(8):
		var debris = _create_debris()
		parent.add_child(debris)
		debris.global_position = pos
		_launch_debris(debris, size * 3.0)
	
	# Smoke cloud
	for i in range(6):
		var delay = randf() * 0.2
		get_tree().create_timer(delay).timeout.connect(func():
			var smoke_pos = pos + Vector3(
				randf_range(-size, size),
				randf_range(0.5, 2.0) * size,
				randf_range(-size, size)
			)
			var smoke = _create_explosion_smoke(smoke_pos, size * randf_range(0.5, 1.2))
			if parent:
				parent.add_child(smoke)
		)
	
	# Shockwave ring (optional)
	if with_shockwave:
		var ring = _create_shockwave_ring(size)
		parent.add_child(ring)
		ring.global_position = pos + Vector3(0, 0.1, 0)
		_animate_shockwave(ring, size * 8.0)
	
	# Sparks
	for i in range(12):
		var spark = _create_spark()
		parent.add_child(spark)
		spark.global_position = pos
		_launch_spark(spark, size * 5.0)
	
	# Cleanup
	_animate_fireball(fireball, 0.5)
	_fade_light(light, 0.8)

# ═══════════════════════ SPARKS ═══════════════════════
func create_sparks(pos: Vector3, normal: Vector3, count: int = 5):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	for i in range(count):
		var spark = _create_spark()
		parent.add_child(spark)
		spark.global_position = pos
		
		var dir = normal + Vector3(
			randf_range(-0.5, 0.5),
			randf_range(0, 0.5),
			randf_range(-0.5, 0.5)
		).normalized()
		_launch_spark_dir(spark, dir, 3.0 + randf() * 2.0)
	
	# Quick flash at impact
	var flash = OmniLight3D.new()
	flash.omni_range = 1.5
	flash.light_energy = 2.0
	flash.light_color = Color(1.0, 0.9, 0.5)
	parent.add_child(flash)
	flash.global_position = pos
	_fade_and_free(flash, 0.08)

# ═══════════════════════ BULLET IMPACT ═══════════════════════
func create_bullet_impact(pos: Vector3, normal: Vector3, surface_type: String = "concrete"):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	match surface_type:
		"concrete", "stone":
			create_sparks(pos, normal, 3)
			_create_dust_puff(parent, pos, Color(0.6, 0.55, 0.5, 0.7))
		"metal":
			create_sparks(pos, normal, 8)
			var flash = OmniLight3D.new()
			flash.omni_range = 2.0
			flash.light_energy = 2.5
			flash.light_color = Color(1.0, 0.8, 0.4)
			parent.add_child(flash)
			flash.global_position = pos
			_fade_and_free(flash, 0.05)
		"wood":
			_create_dust_puff(parent, pos, Color(0.55, 0.40, 0.25, 0.6))
			_create_splinters(parent, pos, normal)
		"flesh":
			_create_blood_splatter(parent, pos, normal)
		_:
			_create_dust_puff(parent, pos, Color(0.5, 0.5, 0.5, 0.5))

# ═══════════════════════ BLOOD EFFECTS ═══════════════════════
func _create_blood_splatter(parent: Node, pos: Vector3, normal: Vector3):
	# Blood droplets
	for i in range(6):
		var drop = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = randf_range(0.02, 0.05)
		sm.height = sm.radius * 2.0
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.02, 0.02)
		mat.roughness = 0.8
		sm.material = mat
		drop.mesh = sm
		parent.add_child(drop)
		drop.global_position = pos
		
		var dir = normal + Vector3(
			randf_range(-0.6, 0.6),
			randf_range(0.1, 0.5),
			randf_range(-0.6, 0.6)
		).normalized()
		_launch_blood_drop(drop, dir, 2.0 + randf() * 2.0)
	
	# Blood mist
	var mist = _create_emissive_sphere(0.15, Color(0.4, 0.0, 0.0, 0.5), 0.2)
	parent.add_child(mist)
	mist.global_position = pos
	_scale_and_fade(mist, 0.25, 0.3)

# ═══════════════════════ SMOKE EFFECTS ═══════════════════════
func _create_smoke_puff(pos: Vector3, size: float) -> MeshInstance3D:
	var smoke = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = size
	sm.height = size * 1.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	smoke.mesh = sm
	smoke.global_position = pos
	
	_rise_and_fade(smoke, 0.5)
	return smoke

func _create_explosion_smoke(pos: Vector3, size: float) -> MeshInstance3D:
	var smoke = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = size
	sm.height = size * 1.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.15, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	smoke.mesh = sm
	smoke.global_position = pos
	
	_rise_and_expand_fade(smoke, 2.0 + randf() * 1.0)
	return smoke

# ═══════════════════════ FIRE EFFECTS ═══════════════════════
func _create_fireball(size: float) -> MeshInstance3D:
	var fb = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = size * 0.8
	sm.height = size * 1.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = mat
	fb.mesh = sm
	return fb

func _animate_fireball(fb: MeshInstance3D, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fb, "scale", Vector3(1.8, 2.5, 1.8), duration * 0.3)
	tween.tween_property(fb, "position:y", fb.position.y + 1.5, duration)
	
	var mesh = fb.mesh as SphereMesh
	if mesh and mesh.material:
		var mat = mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	
	tween.chain().tween_callback(fb.queue_free)

# ═══════════════════════ SHOCKWAVE ═══════════════════════
func _create_shockwave_ring(size: float) -> MeshInstance3D:
	var ring = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.1
	tm.outer_radius = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.7, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.material = mat
	ring.mesh = tm
	ring.rotation.x = PI / 2
	return ring

func _animate_shockwave(ring: MeshInstance3D, max_size: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(max_size, max_size, 1.0), 0.4).set_ease(Tween.EASE_OUT)
	
	var mesh = ring.mesh as TorusMesh
	if mesh and mesh.material:
		var mat = mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	
	tween.chain().tween_callback(ring.queue_free)

# ═══════════════════════ DEBRIS ═══════════════════════
func _create_debris() -> MeshInstance3D:
	var debris = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(
		randf_range(0.05, 0.15),
		randf_range(0.05, 0.15),
		randf_range(0.05, 0.15)
	)
	var mat = StandardMaterial3D.new()
	var gray = randf_range(0.2, 0.5)
	mat.albedo_color = Color(gray, gray * 0.95, gray * 0.9)
	mat.roughness = 0.9
	bm.material = mat
	debris.mesh = bm
	return debris

func _launch_debris(debris: MeshInstance3D, force: float):
	var dir = Vector3(
		randf_range(-1, 1),
		randf_range(0.5, 1.5),
		randf_range(-1, 1)
	).normalized()
	
	var tween = create_tween()
	var end_pos = debris.global_position + dir * force
	end_pos.y = max(0.1, end_pos.y - force * 0.5)
	
	tween.tween_property(debris, "global_position", debris.global_position + dir * force * 0.5, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(debris, "global_position", end_pos, 0.5).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(debris, "rotation", Vector3(randf() * TAU * 2, randf() * TAU * 2, randf() * TAU * 2), 0.8)
	tween.tween_callback(debris.queue_free)

# ═══════════════════════ SPARKS/PARTICLES ═══════════════════════
func _create_spark() -> MeshInstance3D:
	var spark = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = randf_range(0.015, 0.035)
	sm.height = sm.radius * 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 3.0
	sm.material = mat
	spark.mesh = sm
	return spark

func _launch_spark(spark: MeshInstance3D, force: float):
	var dir = Vector3(
		randf_range(-1, 1),
		randf_range(0.3, 1.2),
		randf_range(-1, 1)
	).normalized()
	_launch_spark_dir(spark, dir, force)

func _launch_spark_dir(spark: MeshInstance3D, dir: Vector3, force: float):
	var tween = create_tween()
	var mid_pos = spark.global_position + dir * force * 0.6
	var end_pos = mid_pos + Vector3(0, -force * 0.4, 0)
	
	tween.tween_property(spark, "global_position", mid_pos, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(spark, "global_position", end_pos, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(spark.queue_free)

# ═══════════════════════ HELPER FUNCTIONS ═══════════════════════
func _create_emissive_sphere(radius: float, color: Color, energy: float) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	sm.material = mat
	mi.mesh = sm
	return mi

func _create_flash_ray(direction: Vector3) -> MeshInstance3D:
	var ray = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.02, 0.02, 0.15)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.3)
	mat.emission_energy_multiplier = 4.0
	bm.material = mat
	ray.mesh = bm
	return ray

func _create_dust_puff(parent: Node, pos: Vector3, color: Color):
	var dust = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	dust.mesh = sm
	parent.add_child(dust)
	dust.global_position = pos
	_scale_and_fade(dust, 0.4, 0.5)

func _create_splinters(parent: Node, pos: Vector3, normal: Vector3):
	for i in range(4):
		var splinter = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.01, 0.01, randf_range(0.03, 0.08))
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.40, 0.25)
		bm.material = mat
		splinter.mesh = bm
		parent.add_child(splinter)
		splinter.global_position = pos
		
		var dir = normal + Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 0.6), randf_range(-0.5, 0.5)).normalized()
		var tween = create_tween()
		tween.tween_property(splinter, "global_position", pos + dir * 0.5, 0.3)
		tween.parallel().tween_property(splinter, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), 0.3)
		tween.tween_callback(splinter.queue_free)

func _launch_blood_drop(drop: MeshInstance3D, dir: Vector3, force: float):
	var tween = create_tween()
	var mid_pos = drop.global_position + dir * force * 0.5
	var end_pos = drop.global_position + dir * force
	end_pos.y = 0.02
	
	tween.tween_property(drop, "global_position", mid_pos, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(drop, "global_position", end_pos, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_interval(2.0)
	tween.tween_callback(drop.queue_free)

func _fade_and_free(node: Node, duration: float):
	get_tree().create_timer(duration).timeout.connect(node.queue_free)

func _fade_light(light: OmniLight3D, duration: float):
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(light.queue_free)

func _rise_and_fade(smoke: MeshInstance3D, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(smoke, "global_position:y", smoke.global_position.y + 0.5, duration)
	tween.tween_property(smoke, "scale", Vector3(1.5, 1.5, 1.5), duration)
	
	var mesh = smoke.mesh as SphereMesh
	if mesh and mesh.material:
		var mat = mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	
	tween.chain().tween_callback(smoke.queue_free)

func _rise_and_expand_fade(smoke: MeshInstance3D, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(smoke, "global_position:y", smoke.global_position.y + 3.0, duration)
	tween.tween_property(smoke, "scale", Vector3(3.0, 2.5, 3.0), duration)
	
	var mesh = smoke.mesh as SphereMesh
	if mesh and mesh.material:
		var mat = mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	
	tween.chain().tween_callback(smoke.queue_free)

func _scale_and_fade(node: MeshInstance3D, scale_to: float, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector3.ONE * scale_to, duration)
	
	var mesh = node.mesh
	if mesh and mesh.material:
		var mat = mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	
	tween.chain().tween_callback(node.queue_free)

# ═══════════════════════ VEHICLE EFFECTS ═══════════════════════
func create_tire_smoke(pos: Vector3, intensity: float = 1.0):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	for i in range(int(3 * intensity)):
		var smoke = _create_smoke_puff(pos + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2)), 0.3 * intensity)
		parent.add_child(smoke)

func create_exhaust_puff(pos: Vector3):
	var parent = get_tree().current_scene
	if not parent:
		return
	
	var puff = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	puff.mesh = sm
	parent.add_child(puff)
	puff.global_position = pos
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(puff, "global_position", pos + Vector3(randf_range(-0.1, 0.1), 0.3, randf_range(-0.2, 0.2)), 0.8)
	tween.tween_property(puff, "scale", Vector3(2.0, 2.0, 2.0), 0.8)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.8)
	tween.chain().tween_callback(puff.queue_free)

# ═══════════════════════ WEATHER EFFECTS ═══════════════════════
var rain_drops: Array = []
var rain_enabled = false

func toggle_rain(enabled: bool):
	rain_enabled = enabled
	if not enabled:
		for drop in rain_drops:
			if is_instance_valid(drop):
				drop.queue_free()
		rain_drops.clear()

func _process(delta):
	if rain_enabled:
		_update_rain()

func _update_rain():
	var parent = get_tree().current_scene
	var cam = get_viewport().get_camera_3d()
	if not parent or not cam:
		return
	
	# Spawn new drops
	if rain_drops.size() < 100:
		var drop = _create_rain_drop()
		var offset = Vector3(randf_range(-15, 15), 20, randf_range(-15, 15))
		drop.global_position = cam.global_position + offset
		parent.add_child(drop)
		rain_drops.append(drop)
	
	# Update existing drops
	for i in range(rain_drops.size() - 1, -1, -1):
		var drop = rain_drops[i]
		if not is_instance_valid(drop):
			rain_drops.remove_at(i)
			continue
		
		drop.global_position.y -= 0.8
		if drop.global_position.y < 0:
			drop.queue_free()
			rain_drops.remove_at(i)

func _create_rain_drop() -> MeshInstance3D:
	var drop = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.005
	cm.bottom_radius = 0.01
	cm.height = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.75, 0.8, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.material = mat
	drop.mesh = cm
	return drop
