# mission_manager.gd
# GTA-style mission system with story progression, side missions, and dynamic events
extends Node

class_name MissionManager

# Mission types
enum MissionType { STORY, SIDE, STRANGER, ACTIVITY, RANDOM_EVENT }
enum MissionStatus { LOCKED, AVAILABLE, ACTIVE, COMPLETED, FAILED }
enum ObjectiveType { GO_TO, KILL, COLLECT, ESCORT, CHASE, FLEE, DEFEND, TALK, DRIVE, SURVIVE }

# Mission data structure
class Mission:
	var id: String
	var name: String
	var description: String
	var type: MissionType
	var status: MissionStatus = MissionStatus.LOCKED
	
	var giver: String  # NPC who gives the mission
	var giver_position: Vector3
	var chapter: int = 1
	var required_missions: Array[String] = []  # Prerequisites
	
	var objectives: Array[Objective] = []
	var current_objective := 0
	
	var rewards: Dictionary = {
		"money": 0,
		"respect": 0,
		"weapon": "",
		"unlocks": []
	}
	
	var time_limit := 0.0  # 0 = no limit
	var fail_on_death := true
	var fail_on_arrest := true
	
	var intro_dialogue: Array[String] = []
	var outro_dialogue: Array[String] = []

class Objective:
	var type: ObjectiveType
	var description: String
	var target_position: Vector3
	var target_radius: float = 5.0
	var target_entity: String = ""  # Entity ID
	var count: int = 1
	var current_count: int = 0
	var is_optional: bool = false
	var time_limit: float = 0.0
	
	func is_complete() -> bool:
		return current_count >= count

# State
var all_missions: Dictionary = {}  # id -> Mission
var active_mission: Mission = null
var current_chapter := 1
var total_chapters := 6

# Stats
var missions_completed := 0
var missions_failed := 0
var total_money_earned := 0

# UI references
var mission_marker: Node3D = null
var objective_markers: Array[Node3D] = []

# Signals
signal mission_available(mission: Mission)
signal mission_started(mission: Mission)
signal mission_completed(mission: Mission)
signal mission_failed(mission: Mission, reason: String)
signal objective_updated(mission: Mission, objective: Objective)
signal objective_completed(mission: Mission, objective: Objective)
signal chapter_unlocked(chapter: int)

func _ready() -> void:
	_create_story_missions()
	_create_side_missions()
	_update_available_missions()

func _process(delta: float) -> void:
	if active_mission:
		_check_mission_objectives(delta)
		_update_mission_markers()

# ============= Mission Creation =============

func _create_story_missions() -> void:
	# Chapter 1: Introduction
	_add_mission({
		"id": "story_1_1",
		"name": "Welcome to the Streets",
		"description": "Meet your contact and learn the basics of survival in this city.",
		"type": MissionType.STORY,
		"chapter": 1,
		"giver": "Vinnie",
		"giver_position": Vector3(50, 0, 50),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Go to Vinnie's bar", "position": Vector3(50, 0, 50), "radius": 5.0},
			{"type": ObjectiveType.TALK, "description": "Talk to Vinnie", "target": "vinnie"},
			{"type": ObjectiveType.GO_TO, "description": "Get to the safehouse", "position": Vector3(100, 0, -50), "radius": 10.0}
		],
		"rewards": {"money": 500, "respect": 10},
		"intro_dialogue": ["Hey kid, you new around here?", "I could use someone who knows how to keep their head down.", "Let me show you around..."],
		"outro_dialogue": ["Not bad, not bad at all.", "Come see me when you want some real work."]
	})
	
	_add_mission({
		"id": "story_1_2",
		"name": "First Score",
		"description": "Prove your worth by completing a simple collection job.",
		"type": MissionType.STORY,
		"chapter": 1,
		"required_missions": ["story_1_1"],
		"giver": "Vinnie",
		"giver_position": Vector3(50, 0, 50),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Drive to the warehouse", "position": Vector3(-100, 0, 100), "radius": 15.0},
			{"type": ObjectiveType.COLLECT, "description": "Collect the package", "target": "package_1", "count": 1},
			{"type": ObjectiveType.GO_TO, "description": "Deliver to the drop-off", "position": Vector3(0, 0, -150), "radius": 10.0}
		],
		"rewards": {"money": 1000, "respect": 25},
		"time_limit": 300.0  # 5 minutes
	})
	
	_add_mission({
		"id": "story_1_3",
		"name": "Turf War",
		"description": "The Eastside Boys are moving in on our territory. Send them a message.",
		"type": MissionType.STORY,
		"chapter": 1,
		"required_missions": ["story_1_2"],
		"giver": "Vinnie",
		"giver_position": Vector3(50, 0, 50),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Head to contested territory", "position": Vector3(-80, 0, -80), "radius": 20.0},
			{"type": ObjectiveType.KILL, "description": "Eliminate Eastside gang members", "target": "eastside_gang", "count": 5},
			{"type": ObjectiveType.FLEE, "description": "Lose the heat", "target": "police"}
		],
		"rewards": {"money": 2500, "respect": 50, "weapon": "pistol"}
	})
	
	# Chapter 2: Rising Through the Ranks
	_add_mission({
		"id": "story_2_1",
		"name": "The Big Time",
		"description": "Vinnie introduces you to the real players in town.",
		"type": MissionType.STORY,
		"chapter": 2,
		"required_missions": ["story_1_3"],
		"giver": "Vinnie",
		"giver_position": Vector3(50, 0, 50),
		"objectives": [
			{"type": ObjectiveType.DRIVE, "description": "Drive Vinnie to the meeting", "target": "vinnie_escort"},
			{"type": ObjectiveType.GO_TO, "description": "Arrive at the restaurant", "position": Vector3(20, 0, 180), "radius": 10.0},
			{"type": ObjectiveType.TALK, "description": "Meet the Boss", "target": "boss_don"}
		],
		"rewards": {"money": 5000, "respect": 100, "unlocks": ["downtown_safehouse"]}
	})
	
	_add_mission({
		"id": "story_2_2",
		"name": "Protection Racket",
		"description": "Collect payments from local businesses. Make sure they understand the importance of cooperation.",
		"type": MissionType.STORY,
		"chapter": 2,
		"required_missions": ["story_2_1"],
		"giver": "Boss",
		"giver_position": Vector3(20, 0, 180),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Visit the first store", "position": Vector3(60, 0, 120), "radius": 5.0},
			{"type": ObjectiveType.COLLECT, "description": "Collect first payment", "target": "payment_1"},
			{"type": ObjectiveType.GO_TO, "description": "Visit the second store", "position": Vector3(-40, 0, 90), "radius": 5.0},
			{"type": ObjectiveType.COLLECT, "description": "Collect second payment", "target": "payment_2"},
			{"type": ObjectiveType.GO_TO, "description": "Deal with the stubborn owner", "position": Vector3(10, 0, 60), "radius": 5.0},
			{"type": ObjectiveType.KILL, "description": "Convince the owner", "target": "stubborn_owner", "count": 1}
		],
		"rewards": {"money": 7500, "respect": 75}
	})
	
	# Chapter 3: Complications
	_add_mission({
		"id": "story_3_1",
		"name": "Betrayal",
		"description": "Someone's been talking to the feds. Find the rat.",
		"type": MissionType.STORY,
		"chapter": 3,
		"required_missions": ["story_2_2"],
		"giver": "Boss",
		"giver_position": Vector3(20, 0, 180),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Stake out the meeting point", "position": Vector3(-150, 0, 50), "radius": 30.0},
			{"type": ObjectiveType.SURVIVE, "description": "Wait for the contact", "time": 60.0},
			{"type": ObjectiveType.CHASE, "description": "Follow the informant", "target": "informant"},
			{"type": ObjectiveType.KILL, "description": "Eliminate the rat", "target": "rat", "count": 1}
		],
		"rewards": {"money": 10000, "respect": 150}
	})
	
	# Continue adding more story missions for chapters 4-6...

func _create_side_missions() -> void:
	# Taxi missions
	_add_mission({
		"id": "side_taxi_1",
		"name": "Taxi Driver",
		"description": "Pick up passengers and deliver them safely to their destination.",
		"type": MissionType.ACTIVITY,
		"chapter": 1,
		"giver": "Taxi Depot",
		"giver_position": Vector3(-80, 0, 20),
		"objectives": [
			{"type": ObjectiveType.GO_TO, "description": "Pick up passenger", "position": Vector3(-50, 0, 80), "radius": 5.0},
			{"type": ObjectiveType.DRIVE, "description": "Drive passenger to destination", "target": "taxi_passenger"},
			{"type": ObjectiveType.GO_TO, "description": "Drop off passenger", "position": Vector3(120, 0, -30), "radius": 5.0}
		],
		"rewards": {"money": 200}
	})
	
	# Vigilante missions
	_add_mission({
		"id": "side_vigilante_1",
		"name": "Vigilante",
		"description": "Hunt down criminals and bring them to justice... your way.",
		"type": MissionType.ACTIVITY,
		"chapter": 1,
		"giver": "Police Scanner",
		"giver_position": Vector3(0, 0, 0),  # In any police vehicle
		"objectives": [
			{"type": ObjectiveType.CHASE, "description": "Chase down the criminal", "target": "criminal_1"},
			{"type": ObjectiveType.KILL, "description": "Eliminate the threat", "target": "criminal_1", "count": 1}
		],
		"rewards": {"money": 500}
	})
	
	# Stranger mission
	_add_mission({
		"id": "stranger_1",
		"name": "Lost Soul",
		"description": "A mysterious woman needs help finding something... or someone.",
		"type": MissionType.STRANGER,
		"chapter": 1,
		"giver": "Mysterious Woman",
		"giver_position": Vector3(30, 0, -100),
		"objectives": [
			{"type": ObjectiveType.TALK, "description": "Listen to her story", "target": "mysterious_woman"},
			{"type": ObjectiveType.GO_TO, "description": "Search the old house", "position": Vector3(-120, 0, -180), "radius": 10.0},
			{"type": ObjectiveType.COLLECT, "description": "Find the locket", "target": "locket"}
		],
		"rewards": {"money": 1500, "respect": 30}
	})

func _add_mission(data: Dictionary) -> void:
	var mission = Mission.new()
	mission.id = data.get("id", "")
	mission.name = data.get("name", "Unknown")
	mission.description = data.get("description", "")
	mission.type = data.get("type", MissionType.STORY)
	mission.chapter = data.get("chapter", 1)
	mission.giver = data.get("giver", "")
	mission.giver_position = data.get("giver_position", Vector3.ZERO)
	mission.required_missions = data.get("required_missions", [])
	mission.rewards = data.get("rewards", {})
	mission.time_limit = data.get("time_limit", 0.0)
	mission.intro_dialogue = data.get("intro_dialogue", [])
	mission.outro_dialogue = data.get("outro_dialogue", [])
	
	# Add objectives
	for obj_data in data.get("objectives", []):
		var obj = Objective.new()
		obj.type = obj_data.get("type", ObjectiveType.GO_TO)
		obj.description = obj_data.get("description", "")
		obj.target_position = obj_data.get("position", Vector3.ZERO)
		obj.target_radius = obj_data.get("radius", 5.0)
		obj.target_entity = obj_data.get("target", "")
		obj.count = obj_data.get("count", 1)
		obj.is_optional = obj_data.get("optional", false)
		obj.time_limit = obj_data.get("time", 0.0)
		mission.objectives.append(obj)
	
	# Set initial status
	if mission.required_missions.is_empty() and mission.chapter <= current_chapter:
		mission.status = MissionStatus.AVAILABLE
	else:
		mission.status = MissionStatus.LOCKED
	
	all_missions[mission.id] = mission

# ============= Mission Flow =============

func start_mission(mission_id: String) -> bool:
	if active_mission:
		push_warning("Cannot start mission while another is active")
		return false
	
	var mission = all_missions.get(mission_id)
	if not mission:
		push_error("Mission not found: " + mission_id)
		return false
	
	if mission.status != MissionStatus.AVAILABLE:
		push_warning("Mission not available: " + mission_id)
		return false
	
	active_mission = mission
	active_mission.status = MissionStatus.ACTIVE
	active_mission.current_objective = 0
	
	# Reset objectives
	for obj in active_mission.objectives:
		obj.current_count = 0
	
	mission_started.emit(active_mission)
	
	# Show intro dialogue if any
	if not active_mission.intro_dialogue.is_empty():
		_show_dialogue(active_mission.intro_dialogue)
	
	return true

func _check_mission_objectives(delta: float) -> void:
	if not active_mission:
		return
	
	if active_mission.current_objective >= active_mission.objectives.size():
		_complete_mission()
		return
	
	var current_obj = active_mission.objectives[active_mission.current_objective]
	
	# Check time limit
	if current_obj.time_limit > 0:
		current_obj.time_limit -= delta
		if current_obj.time_limit <= 0:
			fail_mission("Time ran out!")
			return
	
	# Check objective based on type
	var player = _get_player()
	if not player:
		return
	
	match current_obj.type:
		ObjectiveType.GO_TO:
			var distance = player.global_position.distance_to(current_obj.target_position)
			if distance <= current_obj.target_radius:
				_complete_objective()
		
		ObjectiveType.KILL:
			# Check through event bus or direct count
			if current_obj.current_count >= current_obj.count:
				_complete_objective()
		
		ObjectiveType.COLLECT:
			if current_obj.current_count >= current_obj.count:
				_complete_objective()
		
		ObjectiveType.SURVIVE:
			if current_obj.time_limit <= 0:
				_complete_objective()
		
		ObjectiveType.TALK:
			# Handled by dialogue system callback
			pass
		
		ObjectiveType.DRIVE:
			# Check if in vehicle near destination
			pass
		
		ObjectiveType.CHASE:
			# Check if target caught/reached
			pass
		
		ObjectiveType.FLEE:
			# Check if wanted level is 0
			pass

func _complete_objective() -> void:
	var obj = active_mission.objectives[active_mission.current_objective]
	objective_completed.emit(active_mission, obj)
	
	active_mission.current_objective += 1
	
	# Check if mission complete
	if active_mission.current_objective >= active_mission.objectives.size():
		_complete_mission()
	else:
		var next_obj = active_mission.objectives[active_mission.current_objective]
		objective_updated.emit(active_mission, next_obj)

func _complete_mission() -> void:
	if not active_mission:
		return
	
	active_mission.status = MissionStatus.COMPLETED
	missions_completed += 1
	
	# Apply rewards
	_apply_rewards(active_mission.rewards)
	
	# Show outro dialogue
	if not active_mission.outro_dialogue.is_empty():
		_show_dialogue(active_mission.outro_dialogue)
	
	mission_completed.emit(active_mission)
	
	var completed_id = active_mission.id
	active_mission = null
	
	# Update available missions
	_update_available_missions()
	
	# Check for chapter progression
	_check_chapter_progression()

func fail_mission(reason: String) -> void:
	if not active_mission:
		return
	
	active_mission.status = MissionStatus.AVAILABLE  # Can retry
	missions_failed += 1
	
	mission_failed.emit(active_mission, reason)
	active_mission = null

func abandon_mission() -> void:
	if active_mission:
		active_mission.status = MissionStatus.AVAILABLE
		active_mission = null

func _apply_rewards(rewards: Dictionary) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	
	if rewards.has("money"):
		var amount = rewards.money
		total_money_earned += amount
		if game_manager:
			game_manager.add_money(amount)
	
	if rewards.has("respect"):
		if game_manager:
			game_manager.add_respect(rewards.respect)
	
	if rewards.has("weapon") and rewards.weapon != "":
		# Unlock weapon
		pass
	
	if rewards.has("unlocks"):
		for unlock in rewards.unlocks:
			# Handle unlocks (safehouses, areas, etc.)
			pass

func _update_available_missions() -> void:
	for mission_id in all_missions:
		var mission = all_missions[mission_id]
		
		if mission.status != MissionStatus.LOCKED:
			continue
		
		# Check chapter requirement
		if mission.chapter > current_chapter:
			continue
		
		# Check prerequisites
		var all_complete = true
		for req_id in mission.required_missions:
			var req_mission = all_missions.get(req_id)
			if not req_mission or req_mission.status != MissionStatus.COMPLETED:
				all_complete = false
				break
		
		if all_complete:
			mission.status = MissionStatus.AVAILABLE
			mission_available.emit(mission)

func _check_chapter_progression() -> void:
	# Check if all story missions in current chapter are complete
	var all_story_complete = true
	
	for mission_id in all_missions:
		var mission = all_missions[mission_id]
		if mission.type == MissionType.STORY and mission.chapter == current_chapter:
			if mission.status != MissionStatus.COMPLETED:
				all_story_complete = false
				break
	
	if all_story_complete and current_chapter < total_chapters:
		current_chapter += 1
		chapter_unlocked.emit(current_chapter)
		_update_available_missions()

# ============= UI and Markers =============

func _update_mission_markers() -> void:
	if not active_mission:
		return
	
	if active_mission.current_objective >= active_mission.objectives.size():
		return
	
	var obj = active_mission.objectives[active_mission.current_objective]
	
	# Update marker position
	if obj.target_position != Vector3.ZERO:
		_set_marker_position(obj.target_position)

func _set_marker_position(position: Vector3) -> void:
	# Create marker if needed
	if not mission_marker:
		mission_marker = _create_marker(Color(1, 0.8, 0))  # Yellow
	
	mission_marker.global_position = position + Vector3(0, 2, 0)
	mission_marker.visible = true

func _create_marker(color: Color) -> Node3D:
	var marker = Node3D.new()
	
	# Floating arrow or cone
	var mesh_instance = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.height = 2.0
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	mesh_instance.mesh = cone
	mesh_instance.rotation_degrees.x = 180  # Point down
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh_instance.material_override = mat
	
	marker.add_child(mesh_instance)
	
	# Add floating animation via script or tween
	get_tree().root.add_child(marker)
	
	return marker

func _show_dialogue(lines: Array) -> void:
	# Integrate with dialogue system
	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system:
		dialogue_system.show_dialogue(lines)

func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player")

# ============= External API =============

func report_kill(target_type: String) -> void:
	if not active_mission:
		return
	
	if active_mission.current_objective >= active_mission.objectives.size():
		return
	
	var obj = active_mission.objectives[active_mission.current_objective]
	
	if obj.type == ObjectiveType.KILL and obj.target_entity == target_type:
		obj.current_count += 1
		objective_updated.emit(active_mission, obj)

func report_collect(item_id: String) -> void:
	if not active_mission:
		return
	
	if active_mission.current_objective >= active_mission.objectives.size():
		return
	
	var obj = active_mission.objectives[active_mission.current_objective]
	
	if obj.type == ObjectiveType.COLLECT and obj.target_entity == item_id:
		obj.current_count += 1
		objective_updated.emit(active_mission, obj)

func report_dialogue_complete(npc_id: String) -> void:
	if not active_mission:
		return
	
	if active_mission.current_objective >= active_mission.objectives.size():
		return
	
	var obj = active_mission.objectives[active_mission.current_objective]
	
	if obj.type == ObjectiveType.TALK and obj.target_entity == npc_id:
		_complete_objective()

func get_available_missions() -> Array[Mission]:
	var available: Array[Mission] = []
	for mission_id in all_missions:
		var mission = all_missions[mission_id]
		if mission.status == MissionStatus.AVAILABLE:
			available.append(mission)
	return available

func get_current_objective_text() -> String:
	if not active_mission:
		return ""
	
	if active_mission.current_objective >= active_mission.objectives.size():
		return "Return to complete mission"
	
	return active_mission.objectives[active_mission.current_objective].description

func get_progress() -> Dictionary:
	var completed_story = 0
	var total_story = 0
	
	for mission_id in all_missions:
		var mission = all_missions[mission_id]
		if mission.type == MissionType.STORY:
			total_story += 1
			if mission.status == MissionStatus.COMPLETED:
				completed_story += 1
	
	return {
		"story_completed": completed_story,
		"story_total": total_story,
		"percentage": float(completed_story) / max(total_story, 1) * 100.0,
		"chapter": current_chapter,
		"total_chapters": total_chapters
	}
