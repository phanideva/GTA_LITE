# state.gd
# Base State class for the State Machine
class_name State
extends Node

var state_machine: Node = null  # StateMachine reference
var actor: Node = null  # The owner (player, NPC, vehicle)

# Called when entering this state
func enter_state(_params: Dictionary = {}) -> void:
	pass

# Called when exiting this state
func exit_state() -> void:
	pass

# Called every frame while in this state
func state_process(_delta: float) -> void:
	pass

# Called every physics frame while in this state
func state_physics_process(_delta: float) -> void:
	pass

# Called for unhandled input while in this state
func state_input(_event: InputEvent) -> void:
	pass

# Helper to transition to another state
func transition_to(state_name: String, params: Dictionary = {}) -> void:
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state(state_name, params)
