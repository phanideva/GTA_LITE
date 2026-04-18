# behavior_tree.gd
# Simple behavior tree implementation for GTA-style NPC AI
class_name BehaviorTree
extends Node

# Behavior status
enum Status { SUCCESS, FAILURE, RUNNING }

var root_node: BTNode = null
var blackboard: Dictionary = {}
var actor: CharacterBody3D = null

func _ready() -> void:
	actor = get_parent() as CharacterBody3D
	_build_tree()

func _build_tree() -> void:
	# Override in subclasses to build specific behavior trees
	pass

func _process(delta: float) -> void:
	if root_node and actor:
		root_node.tick(delta, actor, blackboard)

func set_blackboard(key: String, value: Variant) -> void:
	blackboard[key] = value

func get_blackboard(key: String, default: Variant = null) -> Variant:
	return blackboard.get(key, default)


# Base Behavior Tree Node
class BTNode:
	var children: Array[BTNode] = []
	
	func tick(_delta: float, _actor: CharacterBody3D, _blackboard: Dictionary) -> int:
		return BehaviorTree.Status.SUCCESS
	
	func add_child(node: BTNode) -> BTNode:
		children.append(node)
		return self


# Composite Nodes

# Selector: Runs children until one succeeds
class BTSelector extends BTNode:
	var current_child := 0
	
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		while current_child < children.size():
			var status = children[current_child].tick(delta, actor, blackboard)
			
			if status == BehaviorTree.Status.RUNNING:
				return BehaviorTree.Status.RUNNING
			elif status == BehaviorTree.Status.SUCCESS:
				current_child = 0
				return BehaviorTree.Status.SUCCESS
			
			current_child += 1
		
		current_child = 0
		return BehaviorTree.Status.FAILURE


# Sequence: Runs all children in order, fails if any fails
class BTSequence extends BTNode:
	var current_child := 0
	
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		while current_child < children.size():
			var status = children[current_child].tick(delta, actor, blackboard)
			
			if status == BehaviorTree.Status.RUNNING:
				return BehaviorTree.Status.RUNNING
			elif status == BehaviorTree.Status.FAILURE:
				current_child = 0
				return BehaviorTree.Status.FAILURE
			
			current_child += 1
		
		current_child = 0
		return BehaviorTree.Status.SUCCESS


# Parallel: Runs all children simultaneously
class BTParallel extends BTNode:
	var success_threshold := 1  # How many need to succeed
	
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		var successes := 0
		var failures := 0
		
		for child in children:
			var status = child.tick(delta, actor, blackboard)
			if status == BehaviorTree.Status.SUCCESS:
				successes += 1
			elif status == BehaviorTree.Status.FAILURE:
				failures += 1
		
		if successes >= success_threshold:
			return BehaviorTree.Status.SUCCESS
		elif failures >= children.size() - success_threshold + 1:
			return BehaviorTree.Status.FAILURE
		
		return BehaviorTree.Status.RUNNING


# Decorator Nodes

# Inverter: Inverts the result of child
class BTInverter extends BTNode:
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if children.is_empty():
			return BehaviorTree.Status.FAILURE
		
		var status = children[0].tick(delta, actor, blackboard)
		match status:
			BehaviorTree.Status.SUCCESS:
				return BehaviorTree.Status.FAILURE
			BehaviorTree.Status.FAILURE:
				return BehaviorTree.Status.SUCCESS
		
		return status


# Repeater: Repeats child N times
class BTRepeater extends BTNode:
	var repeat_count := -1  # -1 = infinite
	var current_count := 0
	
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if children.is_empty():
			return BehaviorTree.Status.SUCCESS
		
		var status = children[0].tick(delta, actor, blackboard)
		
		if status == BehaviorTree.Status.RUNNING:
			return BehaviorTree.Status.RUNNING
		
		current_count += 1
		
		if repeat_count > 0 and current_count >= repeat_count:
			current_count = 0
			return BehaviorTree.Status.SUCCESS
		
		return BehaviorTree.Status.RUNNING


# Succeeder: Always returns success
class BTSucceeder extends BTNode:
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if not children.is_empty():
			children[0].tick(delta, actor, blackboard)
		return BehaviorTree.Status.SUCCESS


# Condition Nodes

# Check if a condition is true
class BTCondition extends BTNode:
	var condition_func: Callable
	
	func _init(check: Callable = Callable()) -> void:
		condition_func = check
	
	func tick(_delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if condition_func.is_valid() and condition_func.call(actor, blackboard):
			return BehaviorTree.Status.SUCCESS
		return BehaviorTree.Status.FAILURE


# Action Nodes

# Base action node
class BTAction extends BTNode:
	var action_func: Callable
	
	func _init(action: Callable = Callable()) -> void:
		action_func = action
	
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if action_func.is_valid():
			return action_func.call(delta, actor, blackboard)
		return BehaviorTree.Status.SUCCESS


# Wait for a duration
class BTWait extends BTNode:
	var duration: float
	var elapsed: float = 0.0
	
	func _init(wait_time: float = 1.0) -> void:
		duration = wait_time
	
	func tick(delta: float, _actor: CharacterBody3D, _blackboard: Dictionary) -> int:
		elapsed += delta
		if elapsed >= duration:
			elapsed = 0.0
			return BehaviorTree.Status.SUCCESS
		return BehaviorTree.Status.RUNNING


# Random selector - picks a random child to execute
class BTRandomSelector extends BTNode:
	func tick(delta: float, actor: CharacterBody3D, blackboard: Dictionary) -> int:
		if children.is_empty():
			return BehaviorTree.Status.FAILURE
		
		var random_child = children[randi() % children.size()]
		return random_child.tick(delta, actor, blackboard)
