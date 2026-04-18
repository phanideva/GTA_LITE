extends Node
# Story Mission System — Gangster Town Adventures
# Full narrative arc: From nobody to kingpin, with dialogue and progression

signal mission_started(title: String)
signal mission_completed(title: String, reward: int)
signal mission_failed(title: String)
signal story_complete

# Story chapters with sequential missions
var story_missions = [
	# --- CHAPTER 1: THE NEWCOMER ---
	{
		"id": 0, "chapter": 1, "title": "Welcome to Town",
		"description": "You just arrived in Gangster Town. Find your cousin Marco's apartment.",
		"type": "reach_zone", "target_count": 1, "reward": 100, "time_limit": 0,
		"marker": Vector3(20, 1, 20), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Rico (You)", "text": "So this is Gangster Town... Not much to look at. I need to find Marco's place before it gets dark."},
			{"speaker": "Rico (You)", "text": "He said it's near the park, northeast side of town. Let me head over there."},
		],
		"complete_dialogue": [
			{"speaker": "Marco", "text": "Rico! My cousin! Welcome to Gangster Town, brother!"},
			{"speaker": "Rico (You)", "text": "Good to see you, Marco. This city is... rougher than I expected."},
			{"speaker": "Marco", "text": "Ha! You haven't seen anything yet. Get some rest. Tomorrow, I'll show you how things work around here."},
		],
	},
	{
		"id": 1, "chapter": 1, "title": "Street Smarts",
		"description": "Marco wants you to prove yourself. Take out 2 gang thugs threatening the neighborhood.",
		"type": "kill", "target_count": 2, "reward": 300, "time_limit": 120,
		"marker": Vector3(40, 1, 10), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "Listen Rico, some punks from the Red Vipers have been shaking down our block."},
			{"speaker": "Marco", "text": "Go show them this neighborhood isn't easy prey. Take them out — there's two of them near the docks."},
			{"speaker": "Rico (You)", "text": "You got it. Nobody messes with our family."},
		],
		"complete_dialogue": [
			{"speaker": "Marco", "text": "Not bad, cousin! You've got some fight in you. Here's $300 for the trouble."},
			{"speaker": "Rico (You)", "text": "That felt... intense. But they had it coming."},
			{"speaker": "Marco", "text": "This is just the beginning. The big players in this city will notice you soon."},
		],
	},
	# --- CHAPTER 2: RISING HEAT ---
	{
		"id": 2, "chapter": 2, "title": "Grand Theft Auto",
		"description": "Marco needs a fast car for a job. Steal one and bring it to the chop shop.",
		"type": "vehicle_deliver", "target_count": 1, "reward": 700, "time_limit": 120,
		"marker": Vector3(-50, 1, -50), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "We've got a job lined up, but we need wheels. Fast ones."},
			{"speaker": "Marco", "text": "Find a nice car on the street and bring it to Tony's chop shop on the south side."},
			{"speaker": "Rico (You)", "text": "Steal a car? I guess that's how things work in this town..."},
			{"speaker": "Marco", "text": "Just don't get caught by the cops. Tony's shop is marked on your map."},
		],
		"complete_dialogue": [
			{"speaker": "Tony", "text": "Nice ride! This baby's worth at least two grand on the black market."},
			{"speaker": "Rico (You)", "text": "Glad I could help. That was a close call with the cops though."},
			{"speaker": "Marco", "text": "You're a natural, Rico. The boss wants to meet you."},
		],
	},
	{
		"id": 3, "chapter": 2, "title": "Heat Wave",
		"description": "The cops are onto you! Survive with a wanted level for 60 seconds without getting busted.",
		"type": "survive", "target_count": 60, "reward": 1000, "time_limit": 90,
		"marker": Vector3(0, 1, 70), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "Bad news, cousin. The cops have your description from that car job."},
			{"speaker": "Marco", "text": "They're setting up roadblocks. You need to lay low and stay alive until the heat dies down."},
			{"speaker": "Rico (You)", "text": "How long do I need to hide?"},
			{"speaker": "Marco", "text": "About a minute should do it. Stay moving, stay alive. Don't let them corner you!"},
		],
		"complete_dialogue": [
			{"speaker": "Rico (You)", "text": "That was too close. My heart's still pounding."},
			{"speaker": "Marco", "text": "You made it! The cops lost your trail. Here's a grand for your trouble."},
			{"speaker": "Marco", "text": "Now... it's time you met Don Vittorio. The real power in this city."},
		],
	},
	# --- CHAPTER 3: THE ORGANIZATION ---
	{
		"id": 4, "chapter": 3, "title": "Meeting the Don",
		"description": "Travel to the Don's mansion on the hill. Don't bring any heat.",
		"type": "reach_zone", "target_count": 1, "reward": 500, "time_limit": 0,
		"marker": Vector3(-70, 1, 60), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "Don Vittorio runs everything in this town. The gangs, the businesses, even some of the cops."},
			{"speaker": "Marco", "text": "He's heard about you. Wants to meet in person. His mansion is on the west hill."},
			{"speaker": "Rico (You)", "text": "Should I be worried?"},
			{"speaker": "Marco", "text": "Only if you say something stupid. Just be respectful. And make sure you're clean — no wanted level."},
		],
		"complete_dialogue": [
			{"speaker": "Don Vittorio", "text": "So you're Marco's cousin. The one causing trouble for the Red Vipers."},
			{"speaker": "Rico (You)", "text": "Yes sir. Just trying to make a living."},
			{"speaker": "Don Vittorio", "text": "I like ambition. I have a proposition for you. Work for me, and you'll never worry about money again."},
			{"speaker": "Don Vittorio", "text": "But cross me... and you'll wish the Vipers had gotten to you first."},
			{"speaker": "Rico (You)", "text": "I understand. What do you need me to do?"},
		],
	},
	{
		"id": 5, "chapter": 3, "title": "Cleaning House",
		"description": "The Don wants the Red Vipers cleared from the industrial district. Eliminate 5 gang members.",
		"type": "kill", "target_count": 5, "reward": 1200, "time_limit": 180,
		"marker": Vector3(60, 1, -40), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Don Vittorio", "text": "The Red Vipers have set up a base in the industrial district. This is unacceptable."},
			{"speaker": "Don Vittorio", "text": "Clear them out. All of them. Show this city who really runs things."},
			{"speaker": "Rico (You)", "text": "Consider it done, Don Vittorio."},
		],
		"complete_dialogue": [
			{"speaker": "Don Vittorio", "text": "Excellent work. The industrial district is ours again."},
			{"speaker": "Rico (You)", "text": "They put up a fight, but nothing I couldn't handle."},
			{"speaker": "Don Vittorio", "text": "You're proving yourself valuable, Rico. Very valuable indeed."},
		],
	},
	# --- CHAPTER 4: THE WAR ---
	{
		"id": 6, "chapter": 4, "title": "Bank Heist",
		"description": "The Don's biggest job yet. Reach the bank vault and grab the cash!",
		"type": "reach_zone", "target_count": 1, "reward": 3000, "time_limit": 180,
		"marker": Vector3(-70, 1, 30), "difficulty": "Hard",
		"intro_dialogue": [
			{"speaker": "Don Vittorio", "text": "I have a special assignment. The Central Bank has been laundering money for the Vipers."},
			{"speaker": "Don Vittorio", "text": "We're going to take their money. All of it. Marco has the plan."},
			{"speaker": "Marco", "text": "Here's the deal — get to the vault, grab what you can, and get out before the cops arrive."},
			{"speaker": "Marco", "text": "You've got three minutes. After that, the whole SWAT team shows up."},
			{"speaker": "Rico (You)", "text": "Three minutes. That's tight. Let's do this."},
		],
		"complete_dialogue": [
			{"speaker": "Rico (You)", "text": "I got the cash! There must be at least fifty grand in here!"},
			{"speaker": "Marco", "text": "Beautiful! The Don will be very pleased. Here's your cut — three grand."},
			{"speaker": "Rico (You)", "text": "Not bad for three minutes of work."},
			{"speaker": "Marco", "text": "But Rico... the Red Vipers know it was us. War is coming."},
		],
	},
	{
		"id": 7, "chapter": 4, "title": "Safehouse Defense",
		"description": "The Vipers are attacking! Defend the safehouse — eliminate 8 attackers!",
		"type": "kill", "target_count": 8, "reward": 2000, "time_limit": 200,
		"marker": Vector3(30, 1, -70), "difficulty": "Hard",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "Rico! They're here! The Vipers found our safehouse!"},
			{"speaker": "Rico (You)", "text": "How many?"},
			{"speaker": "Marco", "text": "A lot! At least eight, maybe more. They've got heavy weapons!"},
			{"speaker": "Rico (You)", "text": "Get behind me. I'll handle this."},
			{"speaker": "Marco", "text": "Be careful, cousin. These aren't street thugs — they're soldiers."},
		],
		"complete_dialogue": [
			{"speaker": "Marco", "text": "You did it! They're retreating! I can't believe we survived that."},
			{"speaker": "Rico (You)", "text": "That was the hardest fight of my life. But we held the line."},
			{"speaker": "Marco", "text": "The Vipers' leader — Snake Eye — he's going to come for you personally now."},
			{"speaker": "Rico (You)", "text": "Let him come. I'll be ready."},
		],
	},
	# --- CHAPTER 5: THE FINAL SHOWDOWN ---
	{
		"id": 8, "chapter": 5, "title": "Ghost Ride",
		"description": "Steal the armored car with evidence against the Don's enemies and escape a 5-star chase!",
		"type": "survive", "target_count": 90, "reward": 3500, "time_limit": 150,
		"marker": Vector3(0, 1, -90), "difficulty": "Very Hard",
		"intro_dialogue": [
			{"speaker": "Don Vittorio", "text": "This is it, Rico. The Police Chief has an armored car full of evidence that could destroy us all."},
			{"speaker": "Don Vittorio", "text": "Steal it and survive the chase. Every cop in the city will be after you."},
			{"speaker": "Rico (You)", "text": "How hot is this going to get?"},
			{"speaker": "Don Vittorio", "text": "Five stars. Maximum heat. But you're the only one who can pull this off."},
			{"speaker": "Rico (You)", "text": "For the family. Let's end this."},
		],
		"complete_dialogue": [
			{"speaker": "Rico (You)", "text": "I made it... barely. That was insane."},
			{"speaker": "Don Vittorio", "text": "You've secured our future, Rico. With this evidence destroyed, we're untouchable."},
			{"speaker": "Don Vittorio", "text": "But there's one more thing... Snake Eye is making his final move tonight."},
		],
	},
	{
		"id": 9, "chapter": 5, "title": "City Takeover",
		"description": "The final battle. Eliminate Snake Eye and all 12 of his elite soldiers to take control of the city!",
		"type": "kill", "target_count": 12, "reward": 10000, "time_limit": 300,
		"marker": Vector3(0, 1, 0), "difficulty": "BOSS",
		"intro_dialogue": [
			{"speaker": "Don Vittorio", "text": "Tonight, we end the Red Vipers once and for all."},
			{"speaker": "Marco", "text": "Snake Eye has brought his best men — twelve elite soldiers. They're spread across the city."},
			{"speaker": "Rico (You)", "text": "Twelve against one? Those are my kind of odds."},
			{"speaker": "Don Vittorio", "text": "After tonight, this city is OURS. Don't let me down, Rico."},
			{"speaker": "Marco", "text": "Be careful out there, cousin. Come back alive."},
			{"speaker": "Rico (You)", "text": "I always do. Let's finish this."},
		],
		"complete_dialogue": [
			{"speaker": "Rico (You)", "text": "It's done. Snake Eye and his men are finished."},
			{"speaker": "Don Vittorio", "text": "You've done the impossible, Rico. Gangster Town is ours."},
			{"speaker": "Marco", "text": "I can't believe it. My cousin... a legend!"},
			{"speaker": "Don Vittorio", "text": "From today, you're not just a soldier. You're my right hand. The new underboss of Gangster Town."},
			{"speaker": "Rico (You)", "text": "I came to this city with nothing. Now... I own it."},
			{"speaker": "Rico (You)", "text": "But I won't forget where I came from. Family first. Always."},
		],
	},
]

# Side missions (repeatable, always available)
var side_missions = [
	{
		"id": 100, "title": "Street Race",
		"description": "Race to the finish line in under 45 seconds!",
		"type": "reach_zone", "target_count": 1, "reward": 800, "time_limit": 45,
		"marker": Vector3(80, 1, 80), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Street Racer", "text": "Think you're fast? Let's see what you got! Race to the stadium before time runs out!"},
		],
	},
	{
		"id": 101, "title": "Bounty Hunter",
		"description": "Take out 3 wanted criminals for the police informant.",
		"type": "kill", "target_count": 3, "reward": 600, "time_limit": 90,
		"marker": Vector3(-30, 1, 40), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Informant", "text": "Three dangerous criminals are hiding in the city. Take them out and I'll make it worth your while."},
		],
	},
	{
		"id": 102, "title": "Taxi Service",
		"description": "Pick up a car and deliver it to the marked location.",
		"type": "reach_zone", "target_count": 1, "reward": 400, "time_limit": 60,
		"marker": Vector3(50, 1, -30), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Customer", "text": "Hey, I need a ride to the docks. Make it quick and there's a big tip for you!"},
		],
	},
	{
		"id": 103, "title": "Gang Turf War",
		"description": "Clear out 5 enemy gang members from the harbor district.",
		"type": "kill", "target_count": 5, "reward": 1000, "time_limit": 120,
		"marker": Vector3(-100, 1, -100), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "The Vipers are trying to take back the harbor. Show them who's boss!"},
		],
		"complete_dialogue": [
			{"speaker": "Marco", "text": "That'll teach them! The harbor stays ours."},
		],
	},
	{
		"id": 104, "title": "Escort Mission",
		"description": "Protect the Don's car for 60 seconds while it travels through hostile territory.",
		"type": "survive", "target_count": 60, "reward": 1500, "time_limit": 90,
		"marker": Vector3(100, 1, -80), "difficulty": "Hard",
		"intro_dialogue": [
			{"speaker": "Don Vittorio", "text": "I need to pass through enemy territory. Watch my back."},
		],
		"complete_dialogue": [
			{"speaker": "Don Vittorio", "text": "Good work. I knew I could count on you."},
		],
	},
	{
		"id": 105, "title": "Police Chase",
		"description": "Escape the police! Survive with maximum wanted level for 45 seconds.",
		"type": "survive", "target_count": 45, "reward": 1200, "time_limit": 75,
		"marker": Vector3(0, 1, 50), "difficulty": "Hard",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "The cops spotted you! You gotta shake them off or we're all going down!"},
		],
	},
	{
		"id": 106, "title": "Assassination Contract",
		"description": "Eliminate the high-value target before time runs out.",
		"type": "kill", "target_count": 1, "reward": 2000, "time_limit": 60,
		"marker": Vector3(-70, 1, 30), "difficulty": "Hard",
		"intro_dialogue": [
			{"speaker": "Mysterious Caller", "text": "There's a rat in our organization. Handle it quietly. You have 60 seconds."},
		],
	},
	{
		"id": 107, "title": "Beach Patrol",
		"description": "Deal with 4 troublemakers harassing tourists at the beach.",
		"type": "kill", "target_count": 4, "reward": 700, "time_limit": 100,
		"marker": Vector3(-120, 1, 80), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Lifeguard", "text": "Some thugs are causing trouble at the beach. Can you help?"},
		],
		"complete_dialogue": [
			{"speaker": "Lifeguard", "text": "Thanks! The beach is safe again."},
		],
	},
	{
		"id": 108, "title": "Stadium Showdown",
		"description": "Clear out 6 gang members who took over the stadium.",
		"type": "kill", "target_count": 6, "reward": 1100, "time_limit": 150,
		"marker": Vector3(100, 1, 100), "difficulty": "Medium",
		"intro_dialogue": [
			{"speaker": "Stadium Manager", "text": "Gang members are holding the stadium hostage! Please help!"},
		],
	},
	{
		"id": 109, "title": "Supply Run",
		"description": "Deliver supplies to the safehouse before time runs out.",
		"type": "reach_zone", "target_count": 1, "reward": 500, "time_limit": 40,
		"marker": Vector3(30, 1, -70), "difficulty": "Easy",
		"intro_dialogue": [
			{"speaker": "Marco", "text": "We need supplies at the safehouse, ASAP! Don't let us down!"},
		],
	},
]

var current_mission: Dictionary = {}
var is_mission_active = false
var mission_progress = 0
var mission_timer = 0.0
var mission_marker: Node3D = null
var story_progress: int = 0  # Index of next story mission to play
var dialogue_system: Node = null
var waiting_for_dialogue = false
var survive_timer = 0.0

func _ready():
	add_to_group("mission_system")
	# Create dialogue system
	var DialogueScript = load("res://scripts/systems/dialogue_system.gd")
	dialogue_system = CanvasLayer.new()
	dialogue_system.set_script(DialogueScript)
	add_child(dialogue_system)
	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)

func _process(delta):
	if not is_mission_active:
		return
	if waiting_for_dialogue:
		return

	# Mission timer
	if current_mission.get("time_limit", 0) > 0:
		mission_timer -= delta
		if mission_timer <= 0:
			fail_mission()
			return

	# Survive missions — count elapsed seconds
	if current_mission.get("type") == "survive":
		survive_timer += delta
		if survive_timer >= current_mission.get("target_count", 60):
			complete_mission()

	# Update HUD mission text
	var text = current_mission.get("title", "")
	if current_mission.get("type") == "kill":
		text += " — Kills: %d/%d" % [mission_progress, current_mission["target_count"]]
	elif current_mission.get("type") == "survive":
		var remaining = current_mission.get("target_count", 60) - survive_timer
		text += " — Survive: %ds" % max(0, int(remaining))
	if current_mission.get("time_limit", 0) > 0:
		text += " | Time: %ds" % max(0, int(mission_timer))
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("update_mission"):
			hud.update_mission(text)

func start_next_story_mission() -> bool:
	if is_mission_active:
		return false
	if story_progress >= story_missions.size():
		return false
	return start_mission_data(story_missions[story_progress], true)

func start_side_mission(index: int) -> bool:
	if is_mission_active:
		return false
	if index < 0 or index >= side_missions.size():
		return false
	return start_mission_data(side_missions[index], false)

func start_mission_data(mission_data: Dictionary, is_story: bool) -> bool:
	current_mission = mission_data.duplicate(true)
	current_mission["is_story"] = is_story
	is_mission_active = true
	mission_progress = 0
	survive_timer = 0.0
	mission_timer = current_mission.get("time_limit", 0)
	_spawn_marker(current_mission["marker"])

	# Show intro dialogue if present
	var intro = current_mission.get("intro_dialogue", [])
	if intro.size() > 0:
		waiting_for_dialogue = true
		dialogue_system.show_dialogue(intro)
	
	emit_signal("mission_started", current_mission["title"])
	print("▶ Mission: ", current_mission["title"], " — ", current_mission["description"])
	return true

# Legacy API — start mission by index (for M key)
func start_mission(mission_id: int) -> bool:
	# M key starts next story mission, or a random side mission if story is done
	if story_progress < story_missions.size():
		return start_next_story_mission()
	else:
		var idx = randi() % side_missions.size()
		return start_side_mission(idx)

func _on_dialogue_finished():
	waiting_for_dialogue = false

func on_kill():
	if not is_mission_active or waiting_for_dialogue:
		return
	if current_mission.get("type") == "kill":
		mission_progress += 1
		print("Kill %d / %d" % [mission_progress, current_mission["target_count"]])
		if mission_progress >= current_mission["target_count"]:
			complete_mission()

func on_reach_zone():
	if not is_mission_active or waiting_for_dialogue:
		return
	if current_mission.get("type") in ["reach_zone", "vehicle_deliver"]:
		complete_mission()

func on_survive_tick():
	pass  # Now handled by survive_timer in _process

func complete_mission():
	if not is_mission_active:
		return
	var reward = current_mission.get("reward", 500)
	Globals.add_money(reward)
	Globals.complete_mission()
	emit_signal("mission_completed", current_mission["title"], reward)
	print("✔ Mission Complete: %s — Reward: $%d" % [current_mission["title"], reward])

	# Show completion dialogue
	var complete_dlg = current_mission.get("complete_dialogue", [])
	if complete_dlg.size() > 0:
		waiting_for_dialogue = true
		dialogue_system.show_dialogue(complete_dlg)

	_remove_marker()
	
	# Advance story
	if current_mission.get("is_story", false):
		story_progress += 1
		if story_progress >= story_missions.size():
			# Story complete!
			await get_tree().create_timer(1.0).timeout
			_show_credits()

	is_mission_active = false
	current_mission = {}

	# Update HUD
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud.has_method("update_mission"):
			if story_progress < story_missions.size():
				hud.update_mission("Press M for next mission: " + story_missions[story_progress]["title"])
			else:
				hud.update_mission("STORY COMPLETE! Press M for side missions.")

func fail_mission():
	if not is_mission_active:
		return
	emit_signal("mission_failed", current_mission.get("title", "Mission"))
	print("✘ Mission Failed: ", current_mission.get("title", "Mission"))
	
	# Show failure dialogue
	if dialogue_system:
		dialogue_system.show_dialogue([
			{"speaker": "Marco", "text": "That didn't go as planned... Don't worry, we can try again. Press M when you're ready."},
		])

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
	mission_marker.global_position = pos + Vector3(0, 2, 0)
	get_parent().add_child(mission_marker)

	# Add pulsing column of light
	var pillar = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 1.5
	cyl.height = 15.0
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(1.0, 0.8, 0.0, 0.15)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.emission_enabled = true
	pmat.emission = Color(1.0, 0.8, 0.0)
	pmat.emission_energy_multiplier = 0.5
	cyl.material = pmat
	pillar.mesh = cyl
	pillar.position = Vector3(0, 7.5, 0)
	mission_marker.add_child(pillar)

	# Trigger zone
	var area = Area3D.new()
	area.global_position = pos
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 5.0
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_marker_entered)
	area.name = "MissionZone"
	get_parent().add_child(area)

func _on_marker_entered(body):
	if body.is_in_group("player"):
		on_reach_zone()

func _remove_marker():
	if mission_marker:
		mission_marker.queue_free()
		mission_marker = null
	# Remove trigger zones
	for node in get_parent().get_children():
		if node.name == "MissionZone":
			node.queue_free()

func _show_credits():
	emit_signal("story_complete")
	if dialogue_system:
		dialogue_system.show_dialogue([
			{"speaker": "CONGRATULATIONS!", "text": "You have completed the story of Gangster Town Adventures!"},
			{"speaker": "Rico (You)", "text": "From a nobody fresh off the bus... to the underboss of the most powerful family in Gangster Town."},
			{"speaker": "CREDITS", "text": "Gangster Town Adventures — Created with Godot Engine 4"},
			{"speaker": "CREDITS", "text": "Thank you for playing! You can continue with side missions or explore the city freely."},
		])

func get_story_progress_text() -> String:
	if story_progress >= story_missions.size():
		return "STORY COMPLETE — Chapter 5/5"
	var chapter = story_missions[story_progress].get("chapter", 1)
	return "Chapter %d/5 — Mission %d/%d" % [chapter, story_progress + 1, story_missions.size()]
