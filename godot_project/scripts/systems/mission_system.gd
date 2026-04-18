extends Node
# Mission System — 10 missions with markers, timers, and fail conditions

signal mission_started(title: String)
signal mission_completed(title: String, reward: int)
signal mission_failed(title: String)

var missions = [
	{
		"id": 0, "title": "First Blood",
		"description": "Eliminate 3 gangsters near the docks.",
		"type": "kill", "target_count": 3, "reward": 400, "time_limit": 0,
		"marker": Vector3(40, 1, 40), "difficulty": "Easy"
	},
	{
		"id": 1, "title": "Grand Theft Auto",
		"description": "Steal a car and deliver it to the chop shop.",
		"type": "vehicle_deliver", "target_count": 1, "reward": 700, "time_limit": 90,
		"marker": Vector3(-50, 1, -50), "difficulty": "Easy"
	},
	{
		"id": 2, "title": "Street Sweep",
		"description": "Clear 5 enemy gangsters from the neighborhood.",
		"type": "kill", "target_count": 5, "reward": 900, "time_limit": 120,
		"marker": Vector3(60, 1, -30), "difficulty": "Medium"
	},
	{
		"id": 3, "title": "Heat",
		"description": "Escape the police — survive 60 seconds while wanted.",
		"type": "survive", "target_count": 1, "reward": 1000, "time_limit": 60,
		"marker": Vector3(0, 1, 70), "difficulty": "Medium"
	},
	{
		"id": 4, "title": "Bank Heist",
		"description": "Reach the bank, grab the cash, and escape.",
		"type": "reach_zone", "target_count": 1, "reward": 2500, "time_limit": 180,
		"marker": Vector3(-70, 1, 30), "difficulty": "Hard"
	},
	{
		"id": 5, "title": "Protect the Package",
		"description": "Eliminate 8 enemies attacking the safehouse.",
		"type": "kill", "target_count": 8, "reward": 1200, "time_limit": 150,
		"marker": Vector3(30, 1, -70), "difficulty": "Hard"
	},
	{
		"id": 6, "title": "Street Race",
		"description": "Race to the finish line in under 45 seconds.",
		"type": "reach_zone", "target_count": 1, "reward": 800, "time_limit": 45,
		"marker": Vector3(80, 1, 80), "difficulty": "Medium"
	},
	{
		"id": 7, "title": "Kingpin",
		"description": "Take out the gang leader and his 4 bodyguards.",
		"type": "kill", "target_count": 5, "reward": 2000, "time_limit": 200,
		"marker": Vector3(-80, 1, -80), "difficulty": "Hard"
	},
	{
		"id": 8, "title": "Ghost Ride",
		"description": "Steal the armored car and lose the 5-star wanted level.",
		"type": "survive", "target_count": 1, "reward": 3000, "time_limit": 120,
		"marker": Vector3(0, 1, -90), "difficulty": "Very Hard"
	},
	{
		"id": 9, "title": "City Takeover",
		"description": "Eliminate 12 enemies across the city.",
		"type": "kill", "target_count": 12, "reward": 5000, "time_limit": 300,
		"marker": Vector3(0, 1, 0), "difficulty": "Very Hard"
	},
]

var current_mission: Dictionary = {}
var is_mission_active = false
var mission_progress = 0
var mission_timer = 0.0
var mission_marker: Node3D = null

func _ready():
	add_to_group("mission_system")

func _process(delta):
	if not is_mission_active:
		return
	if current_mission.get("time_limit", 0) > 0:
		mission_timer -= delta
		if mission_timer <= 0:
			fail_mission()

func start_mission(mission_id: int) -> bool:
	if is_mission_active:
		return false
	if mission_id < 0 or mission_id >= missions.size():
		return false
	current_mission = missions[mission_id].duplicate()
	is_mission_active = true
	mission_progress = 0
	mission_timer = current_mission.get("time_limit", 0)
	_spawn_marker(current_mission["marker"])
	emit_signal("mission_started", current_mission["title"])
	print("▶ Mission: ", current_mission["title"])
	return true

func on_kill():
	if not is_mission_active:
		return
	if current_mission.get("type") == "kill":
		mission_progress += 1
		print("Kill %d / %d" % [mission_progress, current_mission["target_count"]])
		if mission_progress >= current_mission["target_count"]:
			complete_mission()

func on_reach_zone():
	if not is_mission_active:
		return
	if current_mission.get("type") in ["reach_zone", "vehicle_deliver"]:
		complete_mission()

func on_survive_tick():
	if not is_mission_active:
		return
	if current_mission.get("type") == "survive":
		mission_progress += 1
		if mission_progress >= current_mission["target_count"]:
			complete_mission()

func complete_mission():
	if not is_mission_active:
		return
	var reward = current_mission.get("reward", 500)
	Globals.add_money(reward)
	Globals.complete_mission()
	emit_signal("mission_completed", current_mission["title"], reward)
	print("✔ Mission Complete: %s — Reward: $%d" % [current_mission["title"], reward])
	_remove_marker()
	is_mission_active = false
	current_mission = {}

func fail_mission():
	if not is_mission_active:
		return
	emit_signal("mission_failed", current_mission.get("title", "Mission"))
	print("✘ Mission Failed: ", current_mission.get("title", "Mission"))
	_remove_marker()
	is_mission_active = false
	current_mission = {}

func _spawn_marker(pos: Vector3):
	_remove_marker()
	mission_marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 4.0
	mission_marker.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.6
	mission_marker.set_surface_override_material(0, mat)
	mission_marker.position = pos
	get_tree().root.get_child(0).add_child(mission_marker)

func _remove_marker():
	if mission_marker and is_instance_valid(mission_marker):
		mission_marker.queue_free()
	mission_marker = null

func get_all_missions() -> Array:
	return missions

func get_time_remaining() -> float:
	return mission_timer
