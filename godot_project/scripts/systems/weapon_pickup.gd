extends Area3D
# Weapon Pickup — walk over to collect ammo/weapon

@export var weapon_type: int = 1  # 1=Pistol 2=Rifle 3=Shotgun
@export var ammo_amount: int = 30
@export var respawn_time: float = 30.0

var is_active = true
var mesh_instance: MeshInstance3D

const WEAPON_COLORS = {1: Color(1.0, 0.85, 0.0), 2: Color(0.2, 0.8, 0.2), 3: Color(1.0, 0.4, 0.1)}

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)

	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	mesh_instance.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = WEAPON_COLORS.get(weapon_type, Color.WHITE)
	mat.emission_enabled = true
	mat.emission = WEAPON_COLORS.get(weapon_type, Color.WHITE)
	mat.emission_energy_multiplier = 1.5
	mesh_instance.set_surface_override_material(0, mat)
	add_child(mesh_instance)

	var cs = CollisionShape3D.new()
	cs.shape = SphereShape3D.new()
	add_child(cs)

func _process(delta):
	if is_active and mesh_instance:
		mesh_instance.rotate_y(delta * 2.0)

func _on_body_entered(body):
	if not is_active:
		return
	if body.is_in_group("player") and body.has_method("add_ammo"):
		body.add_ammo(weapon_type, ammo_amount)
		body.current_weapon = weapon_type
		is_active = false
		mesh_instance.visible = false
		await get_tree().create_timer(respawn_time).timeout
		is_active = true
		mesh_instance.visible = true
