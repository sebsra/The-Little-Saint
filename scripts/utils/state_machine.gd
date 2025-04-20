class_name StateMachine
extends Node

## A finite state machine implementation for Godot 4.x

# Current active state
var current_state: State = null

# Dictionary of available states
var states: Dictionary = {}

# The owner node that this state machine controls
var owner_node: Node = null

# Debug mode flag
@export var debug_mode: bool = true

# Signal emitted when state changes
signal state_changed(from_state, to_state)

func _ready():
	owner_node = get_parent()

	# Register all child states
	for child in get_children():
		if child is State:
			register_state(child)

	# Initialize the first state
	if states.size() > 0:
		var initial_state = states.values()[0]
		change_state(initial_state.name)

func _process(delta):
	if current_state != null:
		# Call the current state's process method
		current_state.process(delta)

		# Check for state transitions
		var next_state = current_state.get_next_state()
		if next_state != null and next_state != "" and states.has(next_state):
			change_state(next_state)

func _physics_process(delta):
	if current_state != null:
		# Call the current state's physics_process method
		current_state.physics_process(delta)

func _input(event):
	if current_state != null:
		# Call the current state's input method
		current_state.handle_input(event)

func register_state(state: State):
	# Add to states dictionary
	states[state.name] = state

	# Set the state machine reference
	state.state_machine = self

	# Set the owner reference
	state.owner_node = owner_node
	
	# Specifically initialize player references for PlayerState instances
	if state is PlayerState:
		state.player = owner_node
	
	if debug_mode:
		print("Registered state: ", state.name)

func change_state(new_state_name: String):
	if not states.has(new_state_name):
		push_error("State '" + new_state_name + "' not found in state machine!")
		return

	var from_state = current_state.name if current_state else "None"

	if current_state != null:
		if debug_mode:
			print("Exiting state: ", current_state.name)
		current_state.exit()

	var next_state = states[new_state_name]
	current_state = next_state
	
	# Make sure the player reference is properly set before entering the state
	if current_state is PlayerState and current_state.player == null:
		current_state.player = owner_node

	if debug_mode:
		print("Entering state: ", current_state.name)

	current_state.enter()

	# Emit state change signal
	emit_signal("state_changed", from_state, new_state_name)

func get_current_state() -> String:
	if current_state != null:
		return current_state.name
	return "None"

# Add a new state at runtime
func add_state(state: State):
	# Check if the state already has a parent
	var current_parent = state.get_parent()

	if current_parent != null and current_parent != self:
		push_error("Cannot add state that is already a child of another node: " + state.name)
		return
	elif current_parent != self:
		# If it doesn't have a parent, add it as a child
		add_child(state)
	# Register the state
	register_state(state)
	
	if debug_mode:
		print("Added state as child and registered: ", state.name)

# Remove a state at runtime
func remove_state(state_name: String):
	if states.has(state_name):
		states.erase(state_name)
	else:
		push_error("Tried to remove non-existent state: " + state_name)

# Hole einen Zustand nach Namen
func get_state(state_name: String) -> State:
	if states.has(state_name):
		return states[state_name]
	return null
