# game_manager.gd
# Central game state manager - Autoload as "GameManager"
extends Node

# Game states
enum GameState { LOADING, MENU, PLAYING, PAUSED, CUTSCENE, GAME_OVER }

# Current state
var current_state: GameState = GameState.LOADING
var previous_state: GameState = GameState.LOADING

# Player reference
var player: CharacterBody3D = null
var player_camera: Camera3D = null

# Game statistics
var stats: Dictionary = {
	"playtime": 0.0,
	"kills": 0,
	"headshots": 0,
	"vehicles_stolen": 0,
	"vehicles_destroyed": 0,
	"distance_traveled_foot": 0.0,
	"distance_traveled_vehicle": 0.0,
	"missions_completed": 0,
	"missions_failed": 0,
	"money_earned": 0,
	"money_spent": 0,
	"wanted_stars_accumulated": 0,
	"times_arrested": 0,
	"times_wasted": 0
}

# Player data
var player_data: Dictionary = {
	"money": 500,
	"max_health": 200.0,
	"max_armor": 100.0,
	"current_health": 200.0,
	"current_armor": 0.0,
	"wanted_level": 0,
	"current_weapon_index": 0,
	"weapons": {},
	"position": Vector3.ZERO,
	"rotation": 0.0
}

# World data
var world_data: Dictionary = {
	"time_hour": 12.0,
	"time_speed": 1.0,  # 1.0 = 1 minute real = 1 hour game
	"weather": "clear",
	"current_district": "downtown"
}

# Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"voice_volume": 1.0,
	"mouse_sensitivity": 0.3,
	"invert_y": false,
	"subtitles": true,
	"minimap_rotation": true
}

# Signals
signal state_changed(new_state: GameState, old_state: GameState)
signal player_registered(player_node: CharacterBody3D)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		stats["playtime"] += delta
		_update_world_time(delta)

func _update_world_time(delta: float) -> void:
	# Advance game time
	world_data["time_hour"] += delta * world_data["time_speed"] / 60.0
	if world_data["time_hour"] >= 24.0:
		world_data["time_hour"] -= 24.0

func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.PLAYING:
			Engine.time_scale = 1.0
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.CUTSCENE:
			get_tree().paused = false
		GameState.GAME_OVER:
			Engine.time_scale = 0.5  # Slow-mo death
	
	state_changed.emit(new_state, previous_state)
	print("[GameManager] State changed: ", GameState.keys()[previous_state], " -> ", GameState.keys()[new_state])

func register_player(player_node: CharacterBody3D) -> void:
	player = player_node
	player_registered.emit(player_node)
	print("[GameManager] Player registered")

func register_camera(camera: Camera3D) -> void:
	player_camera = camera

func get_player() -> CharacterBody3D:
	return player

func get_camera() -> Camera3D:
	return player_camera

# Money management
func add_money(amount: int) -> void:
	player_data["money"] += amount
	stats["money_earned"] += amount
	if EventBus:
		EventBus.player_money_changed.emit(amount, player_data["money"])

func remove_money(amount: int) -> bool:
	if player_data["money"] >= amount:
		player_data["money"] -= amount
		stats["money_spent"] += amount
		if EventBus:
			EventBus.player_money_changed.emit(-amount, player_data["money"])
		return true
	return false

func get_money() -> int:
	return player_data["money"]

# Wanted level management
func set_wanted_level(level: int) -> void:
	var old_level = player_data["wanted_level"]
	player_data["wanted_level"] = clamp(level, 0, 6)
	stats["wanted_stars_accumulated"] += max(0, level - old_level)
	if EventBus:
		EventBus.wanted_level_changed.emit(player_data["wanted_level"], old_level)

func add_wanted_level(amount: int = 1) -> void:
	set_wanted_level(player_data["wanted_level"] + amount)

func clear_wanted_level() -> void:
	set_wanted_level(0)

func get_wanted_level() -> int:
	return player_data["wanted_level"]

# Health management
func set_player_health(value: float) -> void:
	player_data["current_health"] = clamp(value, 0.0, player_data["max_health"])
	if EventBus:
		EventBus.player_health_changed.emit(player_data["current_health"], player_data["max_health"])
	
	if player_data["current_health"] <= 0:
		_on_player_died()

func damage_player(amount: float) -> void:
	# Armor absorbs damage first
	var armor_damage = min(player_data["current_armor"], amount)
	player_data["current_armor"] -= armor_damage
	var health_damage = amount - armor_damage
	
	if EventBus:
		EventBus.player_armor_changed.emit(player_data["current_armor"], player_data["max_armor"])
	
	set_player_health(player_data["current_health"] - health_damage)

func heal_player(amount: float) -> void:
	set_player_health(player_data["current_health"] + amount)

func add_armor(amount: float) -> void:
	player_data["current_armor"] = min(player_data["current_armor"] + amount, player_data["max_armor"])
	if EventBus:
		EventBus.player_armor_changed.emit(player_data["current_armor"], player_data["max_armor"])

func _on_player_died() -> void:
	stats["times_wasted"] += 1
	change_state(GameState.GAME_OVER)
	if EventBus:
		EventBus.player_wasted.emit()

# Time management
func get_game_time() -> Dictionary:
	var hour = int(world_data["time_hour"])
	var minute = int((world_data["time_hour"] - hour) * 60)
	return {"hour": hour, "minute": minute}

func set_game_time(hour: float) -> void:
	world_data["time_hour"] = fmod(hour, 24.0)
	if EventBus:
		var time = get_game_time()
		EventBus.time_changed.emit(time["hour"], time["minute"])

func is_night() -> bool:
	return world_data["time_hour"] < 6.0 or world_data["time_hour"] > 20.0

# Save/Load helpers
func get_save_data() -> Dictionary:
	return {
		"player_data": player_data.duplicate(true),
		"stats": stats.duplicate(true),
		"world_data": world_data.duplicate(true),
		"settings": settings.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("player_data"):
		player_data = data["player_data"]
	if data.has("stats"):
		stats = data["stats"]
	if data.has("world_data"):
		world_data = data["world_data"]
	if data.has("settings"):
		settings = data["settings"]
