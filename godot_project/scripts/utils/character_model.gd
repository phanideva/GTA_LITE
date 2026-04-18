extends Node3D
# Procedural Humanoid Character Model Builder
# Builds a human figure from primitive meshes: head, torso, arms, legs, accessories

class_name CharacterModel

# Body part colors
var skin_color := Color(0.87, 0.72, 0.58)
var shirt_color := Color(0.3, 0.3, 0.8)
var pants_color := Color(0.15, 0.15, 0.3)
var shoe_color := Color(0.15, 0.1, 0.05)
var hair_color := Color(0.12, 0.08, 0.05)
var hat_color := Color.TRANSPARENT  # No hat by default
var accessory_type := ""  # "gun", "badge", "backpack"

# Animation state
var walk_phase := 0.0
var is_walking := false
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var head_node: Node3D

static func create_material(color: Color, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 0.3
	return mat

func build():
	# NECK
	var neck = MeshInstance3D.new()
	var neck_m = CylinderMesh.new()
	neck_m.top_radius = 0.06
	neck_m.bottom_radius = 0.07
	neck_m.height = 0.12
	neck_m.material = create_material(skin_color)
	neck.mesh = neck_m
	neck.position = Vector3(0, 1.44, 0)
	add_child(neck)

	# HEAD
	head_node = Node3D.new()
	head_node.name = "Head"
	head_node.position = Vector3(0, 1.55, 0)
	add_child(head_node)

	var head_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.32
	sphere.material = create_material(skin_color)
	head_mesh.mesh = sphere
	head_node.add_child(head_mesh)

	# Hair
	if hair_color.a > 0:
		var hair = MeshInstance3D.new()
		var hair_m = SphereMesh.new()
		hair_m.radius = 0.16
		hair_m.height = 0.18
		hair_m.material = create_material(hair_color)
		hair.mesh = hair_m
		hair.position = Vector3(0, 0.08, -0.02)
		head_node.add_child(hair)

	# Eyes (2 small dark spheres)
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		var eye_m = SphereMesh.new()
		eye_m.radius = 0.025
		eye_m.height = 0.05
		eye_m.material = create_material(Color(0.1, 0.1, 0.1))
		eye.mesh = eye_m
		eye.position = Vector3(side * 0.055, 0.03, 0.12)
		head_node.add_child(eye)

	# Nose
	var nose = MeshInstance3D.new()
	var nose_m = SphereMesh.new()
	nose_m.radius = 0.025
	nose_m.height = 0.04
	nose_m.material = create_material(skin_color.darkened(0.05))
	nose.mesh = nose_m
	nose.position = Vector3(0, -0.01, 0.14)
	head_node.add_child(nose)

	# Mouth
	var mouth = MeshInstance3D.new()
	var mouth_m = BoxMesh.new()
	mouth_m.size = Vector3(0.06, 0.015, 0.01)
	mouth_m.material = create_material(Color(0.65, 0.35, 0.3))
	mouth.mesh = mouth_m
	mouth.position = Vector3(0, -0.05, 0.13)
	head_node.add_child(mouth)

	# Ears
	for side in [-1, 1]:
		var ear = MeshInstance3D.new()
		var ear_m = SphereMesh.new()
		ear_m.radius = 0.03
		ear_m.height = 0.04
		ear_m.material = create_material(skin_color)
		ear.mesh = ear_m
		ear.position = Vector3(side * 0.14, 0.02, 0)
		head_node.add_child(ear)

	# Hat (if set)
	if hat_color.a > 0:
		var hat = MeshInstance3D.new()
		var hat_m = CylinderMesh.new()
		hat_m.top_radius = 0.17
		hat_m.bottom_radius = 0.22
		hat_m.height = 0.1
		hat_m.material = create_material(hat_color)
		hat.mesh = hat_m
		hat.position = Vector3(0, 0.17, 0)
		head_node.add_child(hat)

	# TORSO
	var torso = MeshInstance3D.new()
	var torso_m = BoxMesh.new()
	torso_m.size = Vector3(0.4, 0.5, 0.22)
	torso_m.material = create_material(shirt_color)
	torso.mesh = torso_m
	torso.position = Vector3(0, 1.15, 0)
	add_child(torso)

	# Belt
	var belt = MeshInstance3D.new()
	var belt_m = BoxMesh.new()
	belt_m.size = Vector3(0.42, 0.06, 0.24)
	belt_m.material = create_material(Color(0.2, 0.15, 0.08))
	belt.mesh = belt_m
	belt.position = Vector3(0, 0.88, 0)
	add_child(belt)

	# Belt buckle
	var buckle = MeshInstance3D.new()
	var buckle_m = BoxMesh.new()
	buckle_m.size = Vector3(0.06, 0.05, 0.02)
	buckle_m.material = create_material(Color(0.8, 0.75, 0.5))
	buckle.mesh = buckle_m
	buckle.position = Vector3(0, 0.88, 0.13)
	add_child(buckle)

	# ARMS
	arm_l = Node3D.new()
	arm_l.name = "ArmL"
	arm_l.position = Vector3(-0.28, 1.35, 0)
	add_child(arm_l)

	var arm_mesh_l = MeshInstance3D.new()
	var arm_m = BoxMesh.new()
	arm_m.size = Vector3(0.12, 0.45, 0.12)
	arm_m.material = create_material(shirt_color)
	arm_mesh_l.mesh = arm_m
	arm_mesh_l.position = Vector3(0, -0.22, 0)
	arm_l.add_child(arm_mesh_l)

	# Left hand
	var hand_l = MeshInstance3D.new()
	var hand_m = SphereMesh.new()
	hand_m.radius = 0.055
	hand_m.height = 0.08
	hand_m.material = create_material(skin_color)
	hand_l.mesh = hand_m
	hand_l.position = Vector3(0, -0.48, 0)
	arm_l.add_child(hand_l)

	arm_r = Node3D.new()
	arm_r.name = "ArmR"
	arm_r.position = Vector3(0.28, 1.35, 0)
	add_child(arm_r)

	var arm_mesh_r = MeshInstance3D.new()
	arm_mesh_r.mesh = arm_m
	arm_mesh_r.position = Vector3(0, -0.22, 0)
	arm_r.add_child(arm_mesh_r)

	var hand_r = MeshInstance3D.new()
	hand_r.mesh = hand_m
	hand_r.position = Vector3(0, -0.48, 0)
	arm_r.add_child(hand_r)

	# LEGS
	leg_l = Node3D.new()
	leg_l.name = "LegL"
	leg_l.position = Vector3(-0.1, 0.87, 0)
	add_child(leg_l)

	var leg_mesh_l = MeshInstance3D.new()
	var leg_m = BoxMesh.new()
	leg_m.size = Vector3(0.15, 0.5, 0.15)
	leg_m.material = create_material(pants_color)
	leg_mesh_l.mesh = leg_m
	leg_mesh_l.position = Vector3(0, -0.25, 0)
	leg_l.add_child(leg_mesh_l)

	# Left shoe
	var shoe_l = MeshInstance3D.new()
	var shoe_m = BoxMesh.new()
	shoe_m.size = Vector3(0.14, 0.08, 0.22)
	shoe_m.material = create_material(shoe_color)
	shoe_l.mesh = shoe_m
	shoe_l.position = Vector3(0, -0.52, 0.04)
	leg_l.add_child(shoe_l)

	leg_r = Node3D.new()
	leg_r.name = "LegR"
	leg_r.position = Vector3(0.1, 0.87, 0)
	add_child(leg_r)

	var leg_mesh_r = MeshInstance3D.new()
	leg_mesh_r.mesh = leg_m
	leg_mesh_r.position = Vector3(0, -0.25, 0)
	leg_r.add_child(leg_mesh_r)

	var shoe_r = MeshInstance3D.new()
	shoe_r.mesh = shoe_m
	shoe_r.position = Vector3(0, -0.52, 0.04)
	leg_r.add_child(shoe_r)

	# ACCESSORY
	if accessory_type == "gun":
		_add_gun()
	elif accessory_type == "badge":
		_add_badge()

func _add_gun():
	if not arm_r:
		return
	var gun = Node3D.new()
	gun.name = "Gun"
	var barrel = MeshInstance3D.new()
	var b_m = BoxMesh.new()
	b_m.size = Vector3(0.04, 0.04, 0.3)
	b_m.material = create_material(Color(0.15, 0.15, 0.15))
	barrel.mesh = b_m
	barrel.position = Vector3(0, 0, 0.18)
	gun.add_child(barrel)

	var grip = MeshInstance3D.new()
	var g_m = BoxMesh.new()
	g_m.size = Vector3(0.04, 0.12, 0.06)
	g_m.material = create_material(Color(0.25, 0.15, 0.08))
	grip.mesh = g_m
	grip.position = Vector3(0, -0.06, 0)
	gun.add_child(grip)

	gun.position = Vector3(0, -0.48, 0.1)
	arm_r.add_child(gun)

func _add_badge():
	var badge = MeshInstance3D.new()
	var b_m = BoxMesh.new()
	b_m.size = Vector3(0.08, 0.08, 0.02)
	b_m.material = create_material(Color(1.0, 0.84, 0.0), Color(1.0, 0.84, 0.0))
	badge.mesh = b_m
	badge.position = Vector3(-0.12, 1.3, 0.12)
	add_child(badge)

func animate_walk(delta: float, speed: float = 5.0):
	if not leg_l or not leg_r or not arm_l or not arm_r:
		return
	walk_phase += delta * speed
	var swing = sin(walk_phase) * 0.4
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	arm_l.rotation.x = -swing * 0.6
	arm_r.rotation.x = swing * 0.6

func reset_pose():
	if leg_l: leg_l.rotation.x = 0
	if leg_r: leg_r.rotation.x = 0
	if arm_l: arm_l.rotation.x = 0
	if arm_r: arm_r.rotation.x = 0
	walk_phase = 0.0
