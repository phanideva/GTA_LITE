extends RigidBody3D
# Traffic AI — NPC cars that drive around the city

@export var speed = 15.0
@export var max_speed = 30.0

var current_speed = 0.0
var direction = Vector3.ZERO
var waypoint_index = 0
var waypoints: Array = []

func _ready():
	add_to_group("traffic")
	set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	freeze = true
	# Remove old box mesh
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()
	_build_car_model()
	generate_path()

func _make_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	mat.metallic = 0.4
	return mat

func _build_car_model():
	var colors = [
		Color(0.7, 0.15, 0.15), Color(0.15, 0.15, 0.7), Color(0.85, 0.85, 0.85),
		Color(0.12, 0.12, 0.12), Color(0.15, 0.55, 0.15), Color(0.8, 0.65, 0.1),
		Color(0.6, 0.3, 0.1), Color(0.4, 0.1, 0.5),
	]
	var car_color = colors[randi() % colors.size()]

	# Body
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.0, 0.7, 4.0)
	bm.material = _make_mat(car_color)
	body.mesh = bm
	body.position = Vector3(0, 0.55, 0)
	add_child(body)

	# Cabin
	var cabin = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(1.8, 0.5, 2.0)
	cm.material = _make_mat(car_color.darkened(0.1))
	cabin.mesh = cm
	cabin.position = Vector3(0, 1.1, -0.2)
	add_child(cabin)

	# Wheels
	for x in [-0.95, 0.95]:
		for z in [-1.2, 1.2]:
			var wheel = MeshInstance3D.new()
			var wm = CylinderMesh.new()
			wm.top_radius = 0.25
			wm.bottom_radius = 0.25
			wm.height = 0.15
			wm.material = _make_mat(Color(0.1, 0.1, 0.1))
			wheel.mesh = wm
			wheel.position = Vector3(x, 0.2, z)
			wheel.rotation.z = PI / 2
			add_child(wheel)

func _physics_process(delta):
	if waypoints.is_empty():
		return
	
	var target_waypoint = waypoints[waypoint_index]
	direction = (target_waypoint - global_position).normalized()
	
	# Update speed
	var distance_to_waypoint = global_position.distance_to(target_waypoint)
	if distance_to_waypoint < 2.0:
		waypoint_index = (waypoint_index + 1) % waypoints.size()
	
	current_speed = speed
	
	# Move vehicle
	var forward = -global_transform.basis.z
	position += forward * current_speed * delta
	
	# Rotate towards waypoint
	rotation.y = atan2(direction.x, direction.z)

func generate_path():
	# Create simple patrol path
	waypoints = [
		Vector3(0, 0, 0),
		Vector3(50, 0, 0),
		Vector3(50, 0, 50),
		Vector3(0, 0, 50),
	]
