extends Node

# Global Game Manager
# Accessible from anywhere as Globals.variable_name

var player: Node3D
var game_state = "playing"  # playing, paused, menu
var player_money: int = 0
var wanted_level: int = 0
var mission_current: int = 0
var mission_active: bool = false

var audio_enabled: bool = true
var sfx_volume: float = 0.8
var music_volume: float = 0.6

# Game statistics
var kills: int = 0
var vehicles_stolen: int = 0
var missions_completed: int = 0
var playtime: float = 0.0

func _ready():
	add_to_group("global")

func _process(delta):
	if game_state == "playing":
		playtime += delta

func add_money(amount: int) -> void:
	player_money += amount
	print("Money: $", player_money)

func remove_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		return true
	return false

func add_wanted_level(amount: int) -> void:
	wanted_level = clampi(wanted_level + amount, 0, 6)
	print("Wanted Level: ", wanted_level)

func reset_wanted_level() -> void:
	wanted_level = 0

func complete_mission() -> void:
	missions_completed += 1
	mission_active = false
	print("Mission completed! Total: ", missions_completed)
