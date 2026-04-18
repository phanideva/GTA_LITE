# event_bus.gd
# Global event bus for decoupled communication between game systems
# Autoload as "EventBus"
extends Node

# Player events
signal player_spawned(player: Node3D)
signal player_died(player: Node3D)
signal player_health_changed(current: float, maximum: float)
signal player_armor_changed(current: float, maximum: float)
signal player_money_changed(amount: int, total: int)
signal player_weapon_changed(weapon_name: String, ammo: int, reserve: int)
signal player_entered_vehicle(vehicle: Node3D)
signal player_exited_vehicle(vehicle: Node3D)

# Combat events
signal damage_dealt(attacker: Node3D, victim: Node3D, amount: float, weapon: String)
signal entity_killed(killer: Node3D, victim: Node3D)
signal explosion_occurred(position: Vector3, radius: float, damage: float)
signal shot_fired(shooter: Node3D, weapon: String, position: Vector3, direction: Vector3)

# Wanted system events
signal wanted_level_changed(level: int, previous_level: int)
signal police_chase_started()
signal police_chase_ended()
signal player_escaped()
signal player_arrested()
signal player_wasted()

# Mission events
signal mission_started(mission_id: String, mission_name: String)
signal mission_completed(mission_id: String, rewards: Dictionary)
signal mission_failed(mission_id: String, reason: String)
signal objective_updated(objective_text: String)
signal objective_completed(objective_id: String)
signal checkpoint_reached(checkpoint_id: String)

# World events
signal time_changed(hour: float, minute: float)
signal weather_changed(weather_type: String)
signal district_entered(district_name: String)
signal district_exited(district_name: String)

# UI events
signal show_notification(message: String, duration: float, type: String)
signal show_subtitle(text: String, speaker: String, duration: float)
signal toggle_pause_menu(paused: bool)
signal phone_call_received(caller: String)
signal radio_station_changed(station_name: String)

# Vehicle events
signal vehicle_entered(vehicle: Node3D, occupant: Node3D)
signal vehicle_exited(vehicle: Node3D, occupant: Node3D)
signal vehicle_destroyed(vehicle: Node3D)
signal vehicle_damaged(vehicle: Node3D, damage: float, damage_type: String)

# NPC events
signal npc_spawned(npc: Node3D, npc_type: String)
signal npc_killed(npc: Node3D, killer: Node3D)
signal npc_alerted(npc: Node3D, alert_source: Vector3)
signal npc_started_fleeing(npc: Node3D)

# Economy events
signal item_purchased(item_id: String, price: int)
signal property_acquired(property_id: String)

# Save/Load events
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal autosave_triggered()

# Debug utility
var _debug_mode: bool = false

func _ready() -> void:
	# Connect to log all signals in debug mode
	if OS.is_debug_build():
		_debug_mode = true

func emit_notification(message: String, duration: float = 3.0, type: String = "info") -> void:
	show_notification.emit(message, duration, type)

func emit_subtitle(text: String, speaker: String = "", duration: float = 4.0) -> void:
	show_subtitle.emit(text, speaker, duration)

func log_event(event_name: String, data: Dictionary = {}) -> void:
	if _debug_mode:
		print("[EventBus] ", event_name, ": ", data)
