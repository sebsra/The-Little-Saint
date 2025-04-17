class_name TowerGuard
extends NPCBase

# Tower Guard specific properties
var has_player_helped_thomas = false
var gate_node = null
var dialog_initiated = false
var dialog_stage = 0
var is_gate_open = false
var player_entered_area = false

# Distance to move to center position for dialog
var center_position_x = 0
var center_position_tolerance = 10.0

# Gate animation parameters
var gate_animation_duration = 1.5
var gate_animation_distance = -100  # Negative value to move up
var gate_original_position = Vector2.ZERO

# Scene transition parameters
var scene_transition_delay = 3.0
var next_scene_path = "res://scenes/levels/heavenly_realm/heavenly_realm/heavenly_realm.tscn"

# Patrol limits and jump positions
var patrol_left_boundary = -207
var patrol_right_boundary = 207
var jump_left_position = -80
var jump_right_position = 85

# Bible quotes for dialog
var bible_quote_helped = "Gesegnet sind die Barmherzigen, denn sie werden Barmherzigkeit erlangen."
var bible_quote_not_helped = "Was ihr getan habt einem von diesen meinen geringsten Brüdern, das habt ihr mir getan."

# Approach speed when moving to player
var APPROACH_SPEED = 150.0

func _ready():
	# Call parent ready function
	super._ready()
	
	# Set patrol points
	patrol_points = [patrol_left_boundary, patrol_right_boundary]
	
	# Set jump points
	jump_points = [jump_left_position, jump_right_position]
	
	# Set default NPC values
	SPEED = 80.0  # Normal patrol speed
	
	# Force debug mode on temporarily to diagnose issues
	debug_mode = true
	
	# Find gate reference - now we're looking for the falltur node directly
	gate_node = get_node_or_null("../Falltür")
	
	if gate_node:
		print("Gate node found: " + str(gate_node.name))
		gate_original_position = gate_node.global_position
	else:
		print("Gate node NOT found!")
	
	# Use the position of the gate for center position, or default to 0
	if gate_node:
		center_position_x = gate_node.global_position.x
		print("Using gate position for center: " + str(center_position_x))
	else:
		center_position_x = 0
		print("Gate not found, using center position: 0")
	
	# Set up the detection area if it doesn't exist
	if not has_node("DetectionArea"):
		create_detection_area()
	
	# Connect to area signal in the scene
	connect_to_area_signal()
	
	# Start in walking state
	set_state(State.WALKING)
	
	print("Tower Guard initialized at position: " + str(global_position))
	print("Patrol from " + str(patrol_left_boundary) + " to " + str(patrol_right_boundary))
	print("Jump positions: " + str(jump_points))
	print("Center position for dialog: " + str(center_position_x))
	print("Starting in WALKING state")

func _physics_process(delta):
	# Handle player interaction immediately if player is at gate
	if player_in_range and not dialog_initiated and player_entered_area:
		# Move directly to player/gate position at faster speed
		go_to_player_immediately(delta)
	else:
		# Call parent physics process for normal behavior
		super._physics_process(delta)

# New function to immediately approach the player
func go_to_player_immediately(delta):
	if not player_reference:
		return
		
	# Calculate distance to player/gate position
	var target_x = center_position_x
	var distance_to_target = target_x - global_position.x
	
	# If close enough, start dialog
	if abs(distance_to_target) < center_position_tolerance:
		player_entered_area = false
		start_dialog()
		return
	
	# Move towards player at faster speed
	var direction = sign(distance_to_target)
	velocity.x = direction * APPROACH_SPEED  # Use increased speed
	movement_direction = direction
	
	# Update animation to show urgency
	current_animation = "walking"
	
	# Apply velocity
	move_and_slide()
	
	if debug_mode:
		print("Moving directly to player: current=" + str(global_position.x) + 
			  ", target=" + str(target_x) + ", distance=" + str(distance_to_target))

# Create a detection area for player interaction
func create_detection_area():
	var area = Area2D.new()
	area.name = "DetectionArea"
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 100.0  # Detection radius
	collision.shape = shape
	
	area.add_child(collision)
	add_child(area)
	
	# Connect signals
	area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	
	if debug_mode:
		print("Created detection area for Tower Guard")

# Move to center position for dialog
func move_to_center_for_dialog(delta):
	var distance_to_center = center_position_x - global_position.x
	
	if abs(distance_to_center) < center_position_tolerance:
		# We're at the center, continue dialog
		dialog_stage = 2
		continue_dialog()
		return
	
	# Move towards center
	var direction = sign(distance_to_center)
	velocity.x = direction * APPROACH_SPEED  # Use increased speed here too
	movement_direction = direction

# Check if Thomas has been helped - now gets data directly from beggar child
func check_thomas_helped():
	# Try to find the beggar child in the scene
	var beggar_child = get_node_or_null("../BeggarChild")
	if beggar_child and beggar_child.has_method("has_been_helped"):
		return beggar_child.has_been_helped
	else:
		# For testing purposes, assuming true if beggar child not found
		print("BeggarChild not found or has_been_helped method missing, defaulting to true")
		return true

# Start dialog with player
func start_dialog():
	dialog_initiated = true
	dialog_stage = 1
	
	# Initial greeting
	say("Halt! Wer begehrt Einlass?", 2.0)
	
	# Set state to talking
	set_state(State.TALKING)
	
	if debug_mode:
		print("Started dialog with player")

# Override continue_dialog from NPCBase
func continue_dialog():
	if not dialog_initiated:
		return
	
	match dialog_stage:
		2:
			# Check if player helped Thomas and update the variable
			has_player_helped_thomas = check_thomas_helped()
			
			# Dialog based on whether Thomas was helped
			if has_player_helped_thomas:
				say("Ich bin der Wächter dieses Tores. Ich sehe, du hast ein gutes Herz bewiesen. Das spricht für dich.", 4.0)
			else:
				say("Ich bin der Wächter dieses Tores. Ich konnte von hier aus sehen, dass du kein Mitgefühl hattest.", 4.0)
			dialog_stage = 3
		
		3:
			# Bible quote - more cryptic
			if has_player_helped_thomas:
				say("Die Barmherzigen finden selbst Barmherzigkeit. Du hast es verstanden.", 3.0)
			else:
				say("Wer den Geringsten nicht hilft, hat den Weg nicht erkannt. Kehre zurück und öffne deine Augen.", 3.0)
			dialog_stage = 4
		
		4:
			# Final response
			if has_player_helped_thomas:
				say("Der Weg ist nun für dich geöffnet.", 2.0)
				# Schedule gate opening
				get_tree().create_timer(2.5).connect("timeout", Callable(self, "open_gate"))
			else:
				say("Geh zurück und finde den wahren Weg der Nächstenliebe. Er liegt direkt vor dir.", 3.0)
			dialog_stage = 5
		
		5:
			# End dialog
			dialog_initiated = false
			dialog_stage = 0
			
			# Return to patrol if gate not opened
			if not is_gate_open:
				set_state(State.WALKING)
			
			if debug_mode:
				print("Dialog ended, returning to patrol")
		
		_:
			# End speech for any other stage
			end_speech()

# Open the gate by moving it upwards
func open_gate():
	if gate_node:
		is_gate_open = true
		
		if debug_mode:
			print("Opening gate...")
			print("Original position: ", gate_node.global_position)
		
		# Create a tween to animate the gate movement
		var tween = get_tree().create_tween()
		tween.tween_property(gate_node, "position:y", 
			gate_node.position.y + gate_animation_distance, 
			gate_animation_duration).set_ease(Tween.EASE_OUT)
		
		# Schedule scene transition after gate opens
		get_tree().create_timer(gate_animation_duration + scene_transition_delay).connect("timeout", 
			Callable(self, "transition_to_next_scene"))
		
		if debug_mode:
			print("Gate opening animation started")
			print("Scene transition scheduled in ", gate_animation_duration + scene_transition_delay, " seconds")
	else:
		print("ERROR: Gate node is null, cannot open gate!")

# Transition to the next scene
func transition_to_next_scene():
	if debug_mode:
		print("Transitioning to next scene: ", next_scene_path)
	
	# Change to the next scene
	get_tree().change_scene_to_file(next_scene_path)

# Override interaction method
func interact():
	if not dialog_initiated:
		start_dialog()
	else:
		continue_dialog()

# Override detection area signal for player interaction
func _on_detection_area_body_entered(body):
	super._on_detection_area_body_entered(body)
	
	# Auto-start dialog when player gets close enough
	if player_in_range and not dialog_initiated:
		start_dialog()

# Set the status of Thomas being helped (for testing)
func set_thomas_helped(helped: bool):
	has_player_helped_thomas = helped
	
	if debug_mode:
		print("Thomas helped status set to: ", helped)
		
# Connect to the Area2D in the scene (for compatibility, but we'll use our own logic now)
func connect_to_area_signal():
	# Create our own area for gate interaction if needed
	if gate_node and not gate_node.has_node("GateArea"):
		create_gate_area()
	
	# GEÄNDERT: Suche nach "GateArea" statt "Area2D"
	var area = get_node_or_null("../Falltür/GateArea")
	if area:
		# Connect to the body_entered signal
		if not area.is_connected("body_entered", Callable(self, "_on_area_body_entered")):
			area.connect("body_entered", Callable(self, "_on_area_body_entered"))
			print("Connected to GateArea signal")
	else:
		print("GateArea not found, using our own detection logic")

# Create an area for gate interaction if needed
func create_gate_area():
	if not gate_node:
		print("Cannot create gate area: gate_node is null")
		return
		
	var area = Area2D.new()
	area.name = "GateArea"
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 50)  # Adjust size as needed
	collision.shape = shape
	
	area.add_child(collision)
	gate_node.add_child(area)
	
	# Connect signals
	area.connect("body_entered", Callable(self, "_on_area_body_entered"))
	
	if debug_mode:
		print("Created gate area for interaction")

# Handler for when player enters the gate area
func _on_area_body_entered(body):
	if body.is_in_group("player") and not player_entered_area:
		player_entered_area = true
		player_reference = body
		
		# HINZUGEFÜGT: Sofort in go_to_player_immediately wechseln
		if not dialog_initiated:
			print("Player entered gate area, guard immediately stopping patrol to approach")
			go_to_player_immediately(0.016)  # Ungefähr ein Frame-Delta

# Handler for when player exits the detection area
func _on_detection_area_body_exited(body):
	super._on_detection_area_body_exited(body)
	
	# If player leaves during dialog, reset dialog state
	if body.is_in_group("player") and dialog_initiated:
		dialog_initiated = false
		dialog_stage = 0
		
		# Return to patrol
		set_state(State.WALKING)
		
		if debug_mode:
			print("Player left during dialog, resetting dialog state")

# Override to immediately respond when player is at gate
func follow_patrol_path(delta):
	# If player is at gate, immediately stop patrol and go to player
	if player_entered_area and player_in_range:
		go_to_player_immediately(delta)
	else:
		# Otherwise, follow normal patrol behavior
		super.follow_patrol_path(delta)
