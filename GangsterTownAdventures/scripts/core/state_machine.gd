# state_machine.gd
# Generic Finite State Machine for GTA-style game
# Used by player, NPCs, and vehicles
class_name StateMachine
extends Node

signal state_changed(from_state: String, to_state: String)

@export var initial_state: String = ""
@export var debug_mode: bool = false

var current_state: Node = null  # Will be a State node
var states: Dictionary = {}
var state_history: Array[String] = []
var owner_node: Node = null

func _ready() -> void:
	owner_node = get_parent()
	
	# Collect all State children
	for child in get_children():
		if child.has_method("enter_state"):
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.actor = owner_node
			if debug_mode:
				print("[StateMachine] Registered state: ", child.name)
	
	# Enter initial state
	if initial_state.is_empty() and states.size() > 0:
		initial_state = states.keys()[0]
	
	if states.has(initial_state.to_lower()):
		_change_state(initial_state.to_lower())

func _process(delta: float) -> void:
	if current_state and current_state.has_method("state_process"):
		current_state.state_process(delta)

func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("state_physics_process"):
		current_state.state_physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("state_input"):
		current_state.state_input(event)

func change_state(new_state_name: String, params: Dictionary = {}) -> void:
	var state_key = new_state_name.to_lower()
	if not states.has(state_key):
		push_warning("[StateMachine] State not found: " + new_state_name)
		return
	
	if current_state and current_state.name.to_lower() == state_key:
		return  # Already in this state
	
	_change_state(state_key, params)

func _change_state(new_state_key: String, params: Dictionary = {}) -> void:
	var old_state_name = ""
	
	if current_state:
		old_state_name = current_state.name
		if current_state.has_method("exit_state"):
			current_state.exit_state()
		state_history.append(old_state_name)
		if state_history.size() > 10:
			state_history.pop_front()
	
	current_state = states[new_state_key]
	if current_state.has_method("enter_state"):
		current_state.enter_state(params)
	
	if debug_mode:
		print("[StateMachine] ", old_state_name, " -> ", current_state.name)
	
	state_changed.emit(old_state_name, current_state.name)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""

func get_previous_state_name() -> String:
	if state_history.size() > 0:
		return state_history.back()
	return ""

func has_state(state_name: String) -> bool:
	return states.has(state_name.to_lower())

func is_in_state(state_name: String) -> bool:
	if current_state:
		return current_state.name.to_lower() == state_name.to_lower()
	return false

func is_in_any_state(state_names: Array) -> bool:
	for state_name in state_names:
		if is_in_state(state_name):
			return true
	return false
