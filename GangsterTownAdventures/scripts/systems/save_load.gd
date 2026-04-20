extends Node
# Save/Load System
# Handles game saves and loading

var save_file_path = "user://gta_save.json"

func _ready():
	add_to_group("save_system")

func save_game() -> bool:
	if not Globals.player:
		return false
	var save_data = {
		"player": {
			"position": var_to_str(Globals.player.global_position),
			"health": Globals.player.health,
		},
		"globals": {
			"money": Globals.player_money,
			"wanted_level": Globals.wanted_level,
			"kills": Globals.kills,
			"missions_completed": Globals.missions_completed,
		},
		"story": {
			"progress": _get_story_progress(),
		}
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		print("Error saving game")
		return false
	
	file.store_string(json_string)
	print("Game saved!")
	return true

func load_game() -> bool:
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		print("No save file found")
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		print("Error loading game")
		return false
	
	var save_data = json.data
	
	# Load player data
	if Globals.player:
		var player_data = save_data.get("player", {})
		if player_data.has("health"):
			Globals.player.health = player_data["health"]
		if player_data.has("position"):
			var pos_str = player_data["position"]
			# Safe deserialization: only allow Vector3 types
			var parsed = str_to_var(pos_str)
			if parsed is Vector3:
				Globals.player.global_position = parsed
			else:
				print("Warning: Invalid position data in save file")
	
	# Load globals data
	var globals_data = save_data.get("globals", {})
	Globals.player_money = globals_data.get("money", 0)
	Globals.wanted_level = globals_data.get("wanted_level", 0)
	Globals.kills = globals_data.get("kills", 0)
	Globals.missions_completed = globals_data.get("missions_completed", 0)
	
	# Load story progress
	var story_data = save_data.get("story", {})
	_set_story_progress(story_data.get("progress", 0))
	
	print("Game loaded!")
	return true

func delete_save():
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)
		print("Save deleted!")

func _get_story_progress() -> int:
	var ms = get_tree().get_first_node_in_group("mission_system")
	if ms and ms.get("story_progress") != null:
		return ms.story_progress
	return 0

func _set_story_progress(progress: int):
	var ms = get_tree().get_first_node_in_group("mission_system")
	if ms and ms.get("story_progress") != null:
		ms.story_progress = progress
