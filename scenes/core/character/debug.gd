# Add this as a new script called state_machine_diagnostic.gd in your project
# Then attach it to your Player node as a child to diagnose issues

extends Node

var check_timer: Timer

func _ready():
	print("\n=== STATE MACHINE DIAGNOSTIC STARTED ===")
	
	# Create timer to periodically check state
	check_timer = Timer.new()
	check_timer.wait_time = 1.0
	check_timer.one_shot = false
	check_timer.timeout.connect(_check_state_machine)
	add_child(check_timer)
	check_timer.start()
	
	# Do initial check
	_check_state_machine()
	
	# Check input map configuration
	_check_input_map()

func _check_state_machine():
	var player = get_parent()
	
	# Check if player is valid
	if !is_instance_valid(player):
		print("ERROR: Parent node is not valid")
		return
		
	print("\n--- State Machine Diagnostic ---")
	print("Player node: ", player.name)
	
	# Check for state machine
	var state_machine = player.get_node_or_null("StateMachine")
	if state_machine == null:
		print("ERROR: StateMachine node not found under player")
		return
		
	# Check current state
	print("Current state: ", state_machine.get_current_state())
	
	# Check registered states
	var states_found = 0
	for child in state_machine.get_children():
		if child is State:
			states_found += 1
			print("- Found state: ", child.name, " (", child.get_class(), ")")
	
	if states_found == 0:
		print("ERROR: No state nodes found under StateMachine!")
	else:
		print("Total states found: ", states_found)
	
	# Check player motion
	print("Player velocity: ", player.velocity)
	print("Player position: ", player.global_position)
	print("Is on floor: ", player.is_on_floor())
	
	# Check input state
	print("Left input: ", Input.is_action_pressed("left"))
	print("Right input: ", Input.is_action_pressed("right"))
	print("Up input: ", Input.is_action_pressed("up"))
	print("Down input: ", Input.is_action_pressed("down"))
	print("Jump counter: ", player.jump_counter)
	print("Player mode: ", player.mode)

func _check_input_map():
	print("\n--- Input Map Configuration ---")
	var required_actions = ["left", "right", "up", "down", "attack", "defend", "Menu"]
	
	for action in required_actions:
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			print("Action '", action, "' registered with ", events.size(), " events")
		else:
			print("ERROR: Action '", action, "' NOT FOUND in InputMap!")

func _input(event):
	# Log key presses for debugging
	if event is InputEventKey and event.pressed:
		var action_name = "None"
		
		if Input.is_action_just_pressed("left"):
			action_name = "left"
		elif Input.is_action_just_pressed("right"):
			action_name = "right"
		elif Input.is_action_just_pressed("up"):
			action_name = "up"
		elif Input.is_action_just_pressed("down"):
			action_name = "down"
		elif Input.is_action_just_pressed("attack"):
			action_name = "attack"
		elif Input.is_action_just_pressed("defend"):
			action_name = "defend"
		
		if action_name != "None":
			print("INPUT DETECTED: ", action_name, " (Key: ", OS.get_keycode_string(event.keycode), ")")
