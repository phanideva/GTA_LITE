extends Node3D
# Procedural Humanoid Character Model — GTA-style detailed human
# Feet sit at EXACTLY Y=0 local space.
# Spawn CharacterBody3D at world Y=1.0 so feet touch the ground.

class_name CharacterModel

# ─── Colour slots ────────────────────────────────────
var skin_color  := Color(0.87, 0.72, 0.58)
var shirt_color := Color(0.3, 0.3, 0.8)
var pants_color := Color(0.15, 0.15, 0.3)
var shoe_color  := Color(0.12, 0.08, 0.04)
var hair_color  := Color(0.12, 0.08, 0.05)
var hat_color   := Color.TRANSPARENT
var accessory_type := ""   # "gun" | "badge" | "rifle"
var is_female := false  # For body shape variation
var body_type := 0  # 0=average, 1=athletic, 2=heavy

# ─── Animation state ─────────────────────────────────
var walk_phase   := 0.0
var body_node    : Node3D   # root that bobs up/down
var head_node    : Node3D
var arm_l        : Node3D
var arm_r        : Node3D
var leg_l        : Node3D
var leg_r        : Node3D
var hand_l       : Node3D
var hand_r       : Node3D

# ─── Y-axis constants (ground = 0) — GTA-style proportions ───
const LEG_H   = 0.88   # hip Y = 0.88, feet Y = 0.00
const TORSO_Y = 0.90   # bottom of torso block
const TORSO_H = 0.55   # torso height
const TORSO_MID := TORSO_Y + TORSO_H * 0.5  # ~1.175
const SHOULDER_Y = TORSO_Y + TORSO_H - 0.02  # ~1.43
const NECK_Y  = TORSO_Y + TORSO_H + 0.02     # ~1.47
const HEAD_Y  = NECK_Y + 0.14                 # ~1.61

# ─────────────────────────────────────────────────────
static func _mat(color: Color, rough: float = 0.75,
		metal: float = 0.0, emit: Color = Color.BLACK) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = rough
	m.metallic     = metal
	if emit != Color.BLACK:
		m.emission_enabled           = true
		m.emission                   = emit
		m.emission_energy_multiplier = 0.35
	return m

# Skin material with subtle subsurface effect
static func _skin_mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.65
	m.metallic = 0.0
	# Subtle warm tint for skin realism
	m.emission_enabled = true
	m.emission = color.lightened(0.2)
	m.emission_energy_multiplier = 0.08
	return m

# Cloth material with slight texture feel
static func _cloth_mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	return m

# Legacy alias used by older code
static func create_material(color: Color, emission: Color = Color.BLACK) -> StandardMaterial3D:
	return _mat(color, 0.75, 0.0, emission)

# ─── Helper: add mesh instance as child ──────────────
func _add_mesh(parent: Node3D, mesh: Mesh,
		pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh     = mesh
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

# ─────────────────────────────────────────────────────
func build():
	# Apply body shape based on gender/type
	if is_female:
		# Slightly different proportions
		shirt_color = shirt_color if shirt_color != Color(0.3, 0.3, 0.8) else [Color(0.8, 0.2, 0.4), Color(0.9, 0.7, 0.2), Color(0.3, 0.7, 0.6), Color(0.7, 0.3, 0.7), Color(0.2, 0.5, 0.8)][randi() % 5]

	# Wrapper node that bobs during walk
	body_node = Node3D.new()
	body_node.name = "Body"
	if is_female:
		body_node.scale = Vector3(0.88, 0.92, 0.88)
	elif body_type == 1:
		# Athletic / heroic build — wider shoulders, thicker
		body_node.scale = Vector3(1.15, 1.0, 1.1)
	add_child(body_node)

	_build_legs()
	_build_torso()
	_build_arms()
	_build_neck_and_head()
	if accessory_type == "gun":    _add_gun()
	elif accessory_type == "badge": _add_badge()
	elif accessory_type == "rifle": _add_rifle()

# ─────────────────────────────────────────────────────
func _build_legs():
	var pm = _cloth_mat(pants_color)
	var sm = _mat(shoe_color, 0.9, 0.1)
	var skin = _skin_mat(skin_color)

	for side in [-1, 1]:
		var leg = Node3D.new()
		leg.name = "LegL" if side == -1 else "LegR"
		leg.position = Vector3(side * 0.095, LEG_H, 0)
		body_node.add_child(leg)

		# ── Hip joint (rounded) ──
		var hip_m = SphereMesh.new()
		hip_m.radius = 0.085
		hip_m.height = 0.17
		hip_m.material = pm
		_add_mesh(leg, hip_m, Vector3(0, 0, 0))

		# ── Thigh (upper leg - tapered) ──
		var thigh_m = CylinderMesh.new()
		thigh_m.top_radius = 0.075
		thigh_m.bottom_radius = 0.065
		thigh_m.height = LEG_H * 0.50
		thigh_m.material = pm
		_add_mesh(leg, thigh_m, Vector3(0, -(LEG_H * 0.50) * 0.5, 0))

		# ── Knee cap (subtle bulge) ──
		var knee_m = SphereMesh.new()
		knee_m.radius = 0.055
		knee_m.height = 0.08
		knee_m.material = pm
		_add_mesh(leg, knee_m, Vector3(0, -LEG_H * 0.50 - 0.02, 0.02))

		# ── Shin (lower leg) ──
		var shin_m = CylinderMesh.new()
		shin_m.top_radius = 0.058
		shin_m.bottom_radius = 0.048
		shin_m.height = LEG_H * 0.42
		shin_m.material = pm
		_add_mesh(leg, shin_m, Vector3(0, -LEG_H * 0.50 - (LEG_H * 0.42) * 0.5 - 0.03, 0))

		# ── Ankle ──
		var ankle_m = SphereMesh.new()
		ankle_m.radius = 0.04
		ankle_m.height = 0.05
		ankle_m.material = pm
		_add_mesh(leg, ankle_m, Vector3(0, -(LEG_H - 0.08), 0))

		# ── Shoe (detailed) ──
		var shoe_base = BoxMesh.new()
		shoe_base.size = Vector3(0.10, 0.06, 0.22)
		shoe_base.material = sm
		_add_mesh(leg, shoe_base, Vector3(0, -(LEG_H - 0.03), 0.04))
		
		# Shoe sole
		var sole = BoxMesh.new()
		sole.size = Vector3(0.105, 0.02, 0.24)
		sole.material = _mat(Color(0.08, 0.08, 0.08), 0.95)
		_add_mesh(leg, sole, Vector3(0, -(LEG_H - 0.01), 0.04))
		
		# Shoe toe cap
		var toe_cap = SphereMesh.new()
		toe_cap.radius = 0.05
		toe_cap.height = 0.06
		toe_cap.material = sm
		_add_mesh(leg, toe_cap, Vector3(0, -(LEG_H - 0.03), 0.14))

		if side == -1:
			leg_l = leg
		else:
			leg_r = leg

# ─────────────────────────────────────────────────────
func _build_torso():
	var tm = _cloth_mat(shirt_color)
	var skin = _skin_mat(skin_color)

	# ── Pelvis/Hips (rounded capsule for a smoother silhouette) ──
	var pelvis = CapsuleMesh.new()
	pelvis.radius = 0.155
	pelvis.height = 0.24
	pelvis.material = _cloth_mat(pants_color)
	_add_mesh(body_node, pelvis, Vector3(0, TORSO_Y - 0.02, 0), Vector3(0, 0, PI / 2.0))

	# ── Lower torso (waist) — slightly narrower cylinder ──
	var waist = CylinderMesh.new()
	waist.top_radius = 0.16
	waist.bottom_radius = 0.15
	waist.height = 0.16
	waist.material = tm
	_add_mesh(body_node, waist, Vector3(0, TORSO_Y + 0.09, 0))

	# ── Main chest (capsule for smooth Tommy Vercetti-style chest) ──
	var chest = CapsuleMesh.new()
	chest.radius = 0.20
	chest.height = TORSO_H * 0.70
	chest.material = tm
	_add_mesh(body_node, chest, Vector3(0, TORSO_MID + 0.06, 0))

	# ── Shoulder area — broad capsule for natural shoulders ──
	var shoulders = CapsuleMesh.new()
	shoulders.radius = 0.10
	shoulders.height = 0.46
	shoulders.material = tm
	_add_mesh(body_node, shoulders, Vector3(0, SHOULDER_Y - 0.02, 0), Vector3(0, 0, PI / 2.0))

	# ── Shoulder caps ──
	for side in [-1, 1]:
		var scap = SphereMesh.new()
		scap.radius = 0.075
		scap.height = 0.12
		scap.material = tm
		_add_mesh(body_node, scap, Vector3(side * 0.21, SHOULDER_Y, 0))

	# ── Collar / V-neck detail ──
	var collar = BoxMesh.new()
	collar.size = Vector3(0.22, 0.05, 0.08)
	collar.material = _cloth_mat(shirt_color.lightened(0.05))
	_add_mesh(body_node, collar, Vector3(0, NECK_Y - 0.02, 0.09))

	# ── Visible neck skin at collar ──
	var neck_skin = CylinderMesh.new()
	neck_skin.top_radius = 0.05
	neck_skin.bottom_radius = 0.06
	neck_skin.height = 0.04
	neck_skin.material = skin
	_add_mesh(body_node, neck_skin, Vector3(0, NECK_Y - 0.01, 0.05))

	# ── Belt ──
	var belt = BoxMesh.new()
	belt.size = Vector3(0.36, 0.055, 0.23)
	belt.material = _mat(Color(0.15, 0.10, 0.05), 0.85, 0.1)
	_add_mesh(body_node, belt, Vector3(0, TORSO_Y + 0.02, 0))

	# ── Belt Buckle ──
	var bk = BoxMesh.new()
	bk.size = Vector3(0.055, 0.045, 0.015)
	bk.material = _mat(Color(0.75, 0.70, 0.45), 0.25, 0.75)
	_add_mesh(body_node, bk, Vector3(0, TORSO_Y + 0.02, 0.12))

# ─────────────────────────────────────────────────────
func _build_arms():
	var am = _cloth_mat(shirt_color)
	var skm = _skin_mat(skin_color)

	for side in [-1, 1]:
		var arm = Node3D.new()
		arm.name = "ArmL" if side == -1 else "ArmR"
		arm.position = Vector3(side * 0.24, SHOULDER_Y, 0)
		body_node.add_child(arm)

		# ── Shoulder joint ──
		var shoulder_joint = SphereMesh.new()
		shoulder_joint.radius = 0.055
		shoulder_joint.height = 0.09
		shoulder_joint.material = am
		_add_mesh(arm, shoulder_joint, Vector3(0, -0.02, 0))

		# ── Upper arm (sleeve) ──
		var ua = CylinderMesh.new()
		ua.top_radius = 0.055
		ua.bottom_radius = 0.048
		ua.height = 0.22
		ua.material = am
		_add_mesh(arm, ua, Vector3(0, -0.13, 0))

		# ── Elbow (skin showing for short sleeves) ──
		var elbow = SphereMesh.new()
		elbow.radius = 0.042
		elbow.height = 0.06
		elbow.material = skm
		_add_mesh(arm, elbow, Vector3(0, -0.25, 0))

		# ── Forearm (skin) ──
		var fa = CylinderMesh.new()
		fa.top_radius = 0.042
		fa.bottom_radius = 0.035
		fa.height = 0.20
		fa.material = skm
		_add_mesh(arm, fa, Vector3(0, -0.36, 0))

		# ── Wrist ──
		var wrist = SphereMesh.new()
		wrist.radius = 0.032
		wrist.height = 0.04
		wrist.material = skm
		_add_mesh(arm, wrist, Vector3(0, -0.47, 0))

		# ── Hand (more detailed) ──
		var hand_node = Node3D.new()
		hand_node.name = "HandL" if side == -1 else "HandR"
		hand_node.position = Vector3(0, -0.52, 0)
		arm.add_child(hand_node)
		
		# Palm
		var palm = BoxMesh.new()
		palm.size = Vector3(0.065, 0.08, 0.035)
		palm.material = skm
		_add_mesh(hand_node, palm, Vector3(0, 0, 0))
		
		# Fingers (simplified but visible)
		for fi in range(4):
			var finger = CylinderMesh.new()
			finger.top_radius = 0.012
			finger.bottom_radius = 0.014
			finger.height = 0.055
			finger.material = skm
			var fx = -0.022 + fi * 0.015
			_add_mesh(hand_node, finger, Vector3(fx, -0.065, 0), Vector3(0.15, 0, 0))
		
		# Thumb
		var thumb = CylinderMesh.new()
		thumb.top_radius = 0.014
		thumb.bottom_radius = 0.016
		thumb.height = 0.04
		thumb.material = skm
		_add_mesh(hand_node, thumb, Vector3(side * 0.04, -0.02, 0.015), Vector3(0, 0, side * 0.8))

		if side == -1:
			arm_l = arm
			hand_l = hand_node
		else:
			arm_r = arm
			hand_r = hand_node

# ─────────────────────────────────────────────────────
func _build_neck_and_head():
	var skm = _skin_mat(skin_color)
	var hm = _mat(hair_color)

	# ── Neck (muscular, slightly tapered) ──
	var neck_cy = CylinderMesh.new()
	neck_cy.top_radius = 0.055
	neck_cy.bottom_radius = 0.065
	neck_cy.height = 0.12
	neck_cy.material = skm
	_add_mesh(body_node, neck_cy, Vector3(0, NECK_Y + 0.06, 0))

	# ── Head node (pivot for nod animations) ──
	head_node = Node3D.new()
	head_node.name = "Head"
	head_node.position = Vector3(0, HEAD_Y, 0)
	body_node.add_child(head_node)

	# ── Skull (base shape) ──
	var skull = SphereMesh.new()
	skull.radius = 0.105
	skull.height = 0.22
	skull.material = skm
	_add_mesh(head_node, skull, Vector3(0, 0.02, 0))

	# ── Face front (slightly elongated forward) ──
	var face = SphereMesh.new()
	face.radius = 0.095
	face.height = 0.20
	face.material = skm
	_add_mesh(head_node, face, Vector3(0, -0.01, 0.04))

	# ── Cheekbones ──
	for side in [-1, 1]:
		var cheek = SphereMesh.new()
		cheek.radius = 0.045
		cheek.height = 0.06
		cheek.material = _skin_mat(skin_color.darkened(0.02))
		_add_mesh(head_node, cheek, Vector3(side * 0.065, -0.02, 0.06))

	# ── Jaw / Chin ──
	var jaw = BoxMesh.new()
	jaw.size = Vector3(0.12, 0.06, 0.08)
	jaw.material = skm
	_add_mesh(head_node, jaw, Vector3(0, -0.08, 0.04))

	var chin = SphereMesh.new()
	chin.radius = 0.035
	chin.height = 0.04
	chin.material = skm
	_add_mesh(head_node, chin, Vector3(0, -0.10, 0.07))

	# ── Forehead ──
	var forehead = SphereMesh.new()
	forehead.radius = 0.085
	forehead.height = 0.08
	forehead.material = skm
	_add_mesh(head_node, forehead, Vector3(0, 0.08, 0.05))

	# ── Nose ──
	var nose_bridge = CylinderMesh.new()
	nose_bridge.top_radius = 0.015
	nose_bridge.bottom_radius = 0.020
	nose_bridge.height = 0.04
	nose_bridge.material = skm
	_add_mesh(head_node, nose_bridge, Vector3(0, 0.01, 0.095), Vector3(0.3, 0, 0))

	var nose_tip = SphereMesh.new()
	nose_tip.radius = 0.022
	nose_tip.height = 0.025
	nose_tip.material = _skin_mat(skin_color.lightened(0.02))
	_add_mesh(head_node, nose_tip, Vector3(0, -0.015, 0.11))

	# ── Ears ──
	for side in [-1, 1]:
		var ear = SphereMesh.new()
		ear.radius = 0.025
		ear.height = 0.05
		ear.material = skm
		_add_mesh(head_node, ear, Vector3(side * 0.095, 0.01, -0.01))

	# ── Hair (GTA style - short/cropped options) ──
	if hair_color.a > 0:
		var hair_base = SphereMesh.new()
		hair_base.radius = 0.11
		hair_base.height = 0.14
		hair_base.material = hm
		_add_mesh(head_node, hair_base, Vector3(0, 0.06, -0.01))
		
		# Front hairline
		var hairline = BoxMesh.new()
		hairline.size = Vector3(0.14, 0.03, 0.06)
		hairline.material = hm
		_add_mesh(head_node, hairline, Vector3(0, 0.10, 0.04))

	# ── Hat (if specified) ──
	if hat_color.a > 0:
		var brim = CylinderMesh.new()
		brim.top_radius = 0.14
		brim.bottom_radius = 0.15
		brim.height = 0.015
		brim.material = _mat(hat_color)
		_add_mesh(head_node, brim, Vector3(0, 0.11, 0.02))
		
		var crown = CylinderMesh.new()
		crown.top_radius = 0.10
		crown.bottom_radius = 0.11
		crown.height = 0.08
		crown.material = _mat(hat_color)
		_add_mesh(head_node, crown, Vector3(0, 0.15, 0))

	# ── Eyes (detailed) ──
	var eye_colors = [
		Color(0.35, 0.22, 0.10),  # Brown
		Color(0.25, 0.45, 0.25),  # Green
		Color(0.25, 0.40, 0.65),  # Blue
		Color(0.45, 0.35, 0.20),  # Hazel
	]
	var iris_color = eye_colors[randi() % eye_colors.size()]

	for side in [-1, 1]:
		# ── Eye socket shadow ──
		var socket = SphereMesh.new()
		socket.radius = 0.028
		socket.height = 0.02
		socket.material = _mat(skin_color.darkened(0.15))
		_add_mesh(head_node, socket, Vector3(side * 0.038, 0.015, 0.08))

		# ── Sclera (white of eye) ──
		var sclera = SphereMesh.new()
		sclera.radius = 0.022
		sclera.height = 0.018
		sclera.material = _mat(Color(0.95, 0.95, 0.95))
		_add_mesh(head_node, sclera, Vector3(side * 0.038, 0.015, 0.092))

		# ── Iris ──
		var iris = SphereMesh.new()
		iris.radius = 0.013
		iris.height = 0.008
		iris.material = _mat(iris_color)
		_add_mesh(head_node, iris, Vector3(side * 0.038, 0.015, 0.102))

		# ── Pupil ──
		var pupil = SphereMesh.new()
		pupil.radius = 0.007
		pupil.height = 0.004
		pupil.material = _mat(Color(0.02, 0.02, 0.02))
		_add_mesh(head_node, pupil, Vector3(side * 0.038, 0.015, 0.106))

		# ── Eyelid ──
		var lid = BoxMesh.new()
		lid.size = Vector3(0.03, 0.008, 0.015)
		lid.material = skm
		_add_mesh(head_node, lid, Vector3(side * 0.038, 0.028, 0.088))

	# ── Eyebrows ──
	var brow_mat = _mat(hair_color.darkened(0.1))
	for side in [-1, 1]:
		var brow = BoxMesh.new()
		brow.size = Vector3(0.035, 0.008, 0.012)
		brow.material = brow_mat
		_add_mesh(head_node, brow, Vector3(side * 0.038, 0.042, 0.085))

	# ── Mouth ──
	var mouth = BoxMesh.new()
	mouth.size = Vector3(0.045, 0.012, 0.015)
	mouth.material = _mat(Color(0.65, 0.35, 0.35))
	_add_mesh(head_node, mouth, Vector3(0, -0.055, 0.085))

# ─────────────────────────────────────────────────────
func _add_gun():
	if not arm_r:
		return
	var g_root = Node3D.new()
	g_root.name = "Gun"
	g_root.position = Vector3(0, -0.56, 0.08)

	# Slide/receiver
	var slide = BoxMesh.new()
	slide.size = Vector3(0.032, 0.045, 0.16)
	slide.material = _mat(Color(0.12, 0.12, 0.12), 0.25, 0.65)
	var s_mi = MeshInstance3D.new()
	s_mi.mesh = slide
	s_mi.position = Vector3(0, 0.02, 0.06)
	g_root.add_child(s_mi)

	# Barrel
	var barrel = CylinderMesh.new()
	barrel.top_radius = 0.008
	barrel.bottom_radius = 0.010
	barrel.height = 0.10
	barrel.material = _mat(Color(0.10, 0.10, 0.10), 0.20, 0.7)
	var b_mi = MeshInstance3D.new()
	b_mi.mesh = barrel
	b_mi.position = Vector3(0, 0.015, 0.16)
	b_mi.rotation = Vector3(PI / 2, 0, 0)
	g_root.add_child(b_mi)

	# Grip
	var grip = BoxMesh.new()
	grip.size = Vector3(0.028, 0.09, 0.045)
	grip.material = _mat(Color(0.20, 0.12, 0.05), 0.85)
	var gr_mi = MeshInstance3D.new()
	gr_mi.mesh = grip
	gr_mi.position = Vector3(0, -0.045, -0.01)
	gr_mi.rotation = Vector3(-0.15, 0, 0)
	g_root.add_child(gr_mi)

	# Trigger guard
	var tg = TorusMesh.new()
	tg.inner_radius = 0.012
	tg.outer_radius = 0.018
	tg.material = _mat(Color(0.12, 0.12, 0.12), 0.30, 0.6)
	var tg_mi = MeshInstance3D.new()
	tg_mi.mesh = tg
	tg_mi.position = Vector3(0, -0.01, 0.02)
	tg_mi.rotation = Vector3(PI / 2, 0, 0)
	g_root.add_child(tg_mi)

	arm_r.add_child(g_root)

func _add_badge():
	var badge = CylinderMesh.new()
	badge.top_radius = 0.035
	badge.bottom_radius = 0.038
	badge.height = 0.008
	badge.material = _mat(Color(1.0, 0.84, 0.0), 0.25, 0.75, Color(1.0, 0.84, 0.0))
	_add_mesh(body_node, badge, Vector3(-0.12, TORSO_MID + 0.10, 0.12))
	
	# Badge star detail
	var star = SphereMesh.new()
	star.radius = 0.015
	star.height = 0.008
	star.material = _mat(Color(0.9, 0.75, 0.0), 0.30, 0.8)
	_add_mesh(body_node, star, Vector3(-0.12, TORSO_MID + 0.10, 0.125))

func _add_rifle():
	if not arm_r:
		return
	var r_root = Node3D.new()
	r_root.name = "Rifle"
	r_root.position = Vector3(0, -0.50, 0.12)

	# Barrel
	var barrel = CylinderMesh.new()
	barrel.top_radius = 0.012
	barrel.bottom_radius = 0.014
	barrel.height = 0.45
	barrel.material = _mat(Color(0.10, 0.10, 0.10), 0.25, 0.6)
	var b_mi = MeshInstance3D.new()
	b_mi.mesh = barrel
	b_mi.position = Vector3(0, 0, 0.32)
	b_mi.rotation = Vector3(PI / 2, 0, 0)
	r_root.add_child(b_mi)

	# Receiver
	var receiver = BoxMesh.new()
	receiver.size = Vector3(0.035, 0.055, 0.18)
	receiver.material = _mat(Color(0.12, 0.12, 0.12), 0.30, 0.55)
	var rec_mi = MeshInstance3D.new()
	rec_mi.mesh = receiver
	rec_mi.position = Vector3(0, 0, 0.06)
	r_root.add_child(rec_mi)

	# Magazine
	var mag = BoxMesh.new()
	mag.size = Vector3(0.025, 0.10, 0.04)
	mag.material = _mat(Color(0.15, 0.15, 0.15), 0.35, 0.5)
	var mag_mi = MeshInstance3D.new()
	mag_mi.mesh = mag
	mag_mi.position = Vector3(0, -0.06, 0.04)
	r_root.add_child(mag_mi)

	# Stock
	var stock = BoxMesh.new()
	stock.size = Vector3(0.030, 0.075, 0.20)
	stock.material = _mat(Color(0.28, 0.16, 0.06), 0.85)
	var st_mi = MeshInstance3D.new()
	st_mi.mesh = stock
	st_mi.position = Vector3(0, -0.01, -0.12)
	r_root.add_child(st_mi)

	# Stock butt
	var butt = BoxMesh.new()
	butt.size = Vector3(0.028, 0.10, 0.04)
	butt.material = _mat(Color(0.25, 0.14, 0.05), 0.90)
	var butt_mi = MeshInstance3D.new()
	butt_mi.mesh = butt
	butt_mi.position = Vector3(0, -0.02, -0.23)
	r_root.add_child(butt_mi)

	arm_r.add_child(r_root)

# ─────────────────────────────────────────────────────
func animate_walk(delta: float, speed: float = 5.0):
	if not leg_l or not leg_r:
		return
	walk_phase += delta * speed

	var swing = sin(walk_phase)
	var bob = abs(sin(walk_phase))

	# Leg swing ±30 degrees (natural gait)
	leg_l.rotation.x = swing * 0.52
	leg_r.rotation.x = -swing * 0.52

	# Arm counter-swing ±25 degrees
	if arm_l:
		arm_l.rotation.x = -swing * 0.44
	if arm_r:
		arm_r.rotation.x = swing * 0.44

	# Body bob — slight up/down motion
	if body_node:
		body_node.position.y = bob * 0.022

	# Body sway (subtle side-to-side)
	if body_node:
		body_node.rotation.z = sin(walk_phase) * 0.015

	# Head slight nod and look direction
	if head_node:
		head_node.rotation.x = sin(walk_phase * 2.0) * 0.015
		head_node.rotation.y = sin(walk_phase * 0.5) * 0.025

func reset_pose():
	if leg_l:
		leg_l.rotation.x = 0
	if leg_r:
		leg_r.rotation.x = 0
	if arm_l:
		arm_l.rotation.x = 0
	if arm_r:
		arm_r.rotation.x = 0
	if body_node:
		body_node.position.y = 0
		body_node.rotation.z = 0
	if head_node:
		head_node.rotation.x = 0
		head_node.rotation.y = 0
	walk_phase = 0.0

# ─────────────────────────────────────────────────────
# Static factory for creating diverse NPC appearances
static func create_random_civilian() -> CharacterModel:
	var model = CharacterModel.new()
	
	# 45% chance female
	model.is_female = randf() < 0.45
	model.body_type = randi() % 3  # 0=average, 1=athletic, 2=heavy
	
	# Random skin tones (LA diverse population)
	var skin_tones = [
		Color(0.95, 0.80, 0.68),   # Light
		Color(0.87, 0.72, 0.58),   # Medium light
		Color(0.75, 0.58, 0.42),   # Tan
		Color(0.55, 0.38, 0.28),   # Medium brown
		Color(0.40, 0.28, 0.20),   # Dark brown
		Color(0.82, 0.68, 0.55),   # Olive
		Color(0.92, 0.78, 0.62),   # Peach
		Color(0.65, 0.48, 0.35),   # Warm brown
		Color(0.88, 0.75, 0.60),   # Golden
	]
	model.skin_color = skin_tones[randi() % skin_tones.size()]
	
	# LA outfit styles — distinct fashion categories
	var outfit_style = randi() % 8
	match outfit_style:
		0:  # Beach/surfer — bright tank top, board shorts
			var beach_shirts = [Color(0.95, 0.85, 0.2), Color(0.1, 0.8, 0.8), Color(0.95, 0.45, 0.1), Color(0.9, 0.3, 0.5), Color(0.4, 0.85, 0.4)]
			model.shirt_color = beach_shirts[randi() % beach_shirts.size()]
			var beach_pants = [Color(0.2, 0.4, 0.7), Color(0.7, 0.3, 0.2), Color(0.3, 0.6, 0.3), Color(0.5, 0.4, 0.3)]
			model.pants_color = beach_pants[randi() % beach_pants.size()]
			model.shoe_color = Color(0.6, 0.55, 0.4)  # Sandals
		1:  # Hollywood/trendy — designer look
			var trendy_shirts = [Color(0.05, 0.05, 0.05), Color(0.92, 0.92, 0.92), Color(0.7, 0.15, 0.15), Color(0.55, 0.35, 0.6)]
			model.shirt_color = trendy_shirts[randi() % trendy_shirts.size()]
			model.pants_color = Color(0.08, 0.08, 0.08) if randf() < 0.6 else Color(0.2, 0.2, 0.25)
			model.shoe_color = Color(0.1, 0.1, 0.1)  # Designer shoes
		2:  # Business/corporate — suit colors
			var suit_colors = [Color(0.12, 0.12, 0.15), Color(0.2, 0.22, 0.28), Color(0.35, 0.33, 0.30), Color(0.15, 0.15, 0.25)]
			model.shirt_color = Color(0.9, 0.88, 0.85) if randf() < 0.5 else Color(0.6, 0.7, 0.85)
			model.pants_color = suit_colors[randi() % suit_colors.size()]
			model.shoe_color = Color(0.12, 0.08, 0.05)
		3:  # Street/hip-hop — oversized, bold colors
			var street_shirts = [Color(0.85, 0.1, 0.1), Color(0.1, 0.1, 0.8), Color(0.8, 0.75, 0.1), Color(0.1, 0.6, 0.1), Color(0.5, 0.1, 0.5)]
			model.shirt_color = street_shirts[randi() % street_shirts.size()]
			var street_pants = [Color(0.2, 0.2, 0.35), Color(0.08, 0.08, 0.08), Color(0.25, 0.22, 0.18)]
			model.pants_color = street_pants[randi() % street_pants.size()]
			model.shoe_color = Color(0.9, 0.9, 0.9)  # White sneakers
			model.hat_color = model.shirt_color if randf() < 0.4 else Color.TRANSPARENT
		4:  # Tourist — Hawaiian shirt, cargo shorts
			var tourist_shirts = [Color(0.9, 0.5, 0.2), Color(0.2, 0.7, 0.5), Color(0.8, 0.3, 0.6), Color(0.3, 0.5, 0.8)]
			model.shirt_color = tourist_shirts[randi() % tourist_shirts.size()]
			model.pants_color = Color(0.6, 0.55, 0.45)  # Khaki
			model.shoe_color = Color(0.5, 0.5, 0.5)
		5:  # Fitness/athletic — sportswear
			var gym_shirts = [Color(0.1, 0.1, 0.1), Color(0.8, 0.15, 0.15), Color(0.15, 0.5, 0.8), Color(0.6, 0.1, 0.6)]
			model.shirt_color = gym_shirts[randi() % gym_shirts.size()]
			model.pants_color = Color(0.12, 0.12, 0.12)
			model.shoe_color = Color(0.85, 0.85, 0.85)
		6:  # Latino/Chicano — flannel, white tee, baggy
			model.shirt_color = Color(0.95, 0.95, 0.95) if randf() < 0.5 else Color(0.5, 0.2, 0.2)
			model.pants_color = Color(0.2, 0.2, 0.25) if randf() < 0.6 else Color(0.25, 0.22, 0.18)
			model.shoe_color = Color(0.1, 0.1, 0.1)
		7:  # Skater/punk — graphic tee, ripped jeans
			var punk_shirts = [Color(0.08, 0.08, 0.08), Color(0.7, 0.0, 0.0), Color(0.6, 0.3, 0.0), Color(0.0, 0.5, 0.0)]
			model.shirt_color = punk_shirts[randi() % punk_shirts.size()]
			model.pants_color = Color(0.25, 0.28, 0.35)  # Faded denim
			model.shoe_color = Color(0.15, 0.15, 0.15)
	
	# Random hair colors (more variety for LA)
	var hair_colors = [
		Color(0.12, 0.08, 0.05),  # Black
		Color(0.30, 0.18, 0.08),  # Dark brown
		Color(0.75, 0.55, 0.25),  # Blonde
		Color(0.45, 0.20, 0.10),  # Auburn
		Color(0.50, 0.50, 0.52),  # Gray
		Color(0.65, 0.40, 0.15),  # Light brown
		Color(0.85, 0.75, 0.55),  # Platinum blonde
		Color(0.15, 0.12, 0.08),  # Very dark
	]
	model.hair_color = hair_colors[randi() % hair_colors.size()]
	
	return model

static func create_police_officer() -> CharacterModel:
	var model = CharacterModel.new()
	model.shirt_color = Color(0.15, 0.20, 0.40)  # Navy blue
	model.pants_color = Color(0.12, 0.15, 0.30)  # Dark navy
	model.hat_color = Color(0.12, 0.15, 0.28)    # Police cap
	model.accessory_type = "badge"
	return model

static func create_gangster() -> CharacterModel:
	var model = CharacterModel.new()
	var gang_colors = [
		[Color(0.70, 0.10, 0.10), Color(0.10, 0.10, 0.10)],  # Red gang
		[Color(0.15, 0.25, 0.70), Color(0.08, 0.08, 0.08)],  # Blue gang
		[Color(0.12, 0.45, 0.12), Color(0.15, 0.15, 0.15)],  # Green gang
	]
	var gang = gang_colors[randi() % gang_colors.size()]
	model.shirt_color = gang[0]
	model.pants_color = gang[1]
	model.accessory_type = "gun" if randf() > 0.3 else ""
	return model
