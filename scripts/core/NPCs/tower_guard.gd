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

# Patrol limits and jump positions (now relative offsets from parent position)
var patrol_left_offset = -207
var patrol_right_offset = 207
var jump_left_offset = -80
var jump_right_offset = 85

# Calculated absolute positions
var patrol_left_boundary = 0
var patrol_right_boundary = 0
var jump_left_position = 0
var jump_right_position = 0

# Bible quotes for dialog
var bible_quote_helped = "Gesegnet sind die Barmherzigen, denn sie werden Barmherzigkeit erlangen."
var bible_quote_not_helped = "Was ihr getan habt einem von diesen meinen geringsten Brüdern, das habt ihr mir getan."

# Approach speed when moving to player
var APPROACH_SPEED = 150.0


func _ready():
	# Call parent ready function
	super._ready()
	
	# Calculate patrol boundaries based on parent position
	calculate_patrol_boundaries()
	
	# Set default NPC values
	SPEED = 80.0  # Normal patrol speed
	
	# Calculate center position for dialog
	calculate_center_position()
	
	# Start in walking state
	set_state(State.WALKING)
	
	print("Tower Guard initialized at position: " + str(global_position))
	print("Patrol from " + str(patrol_left_boundary) + " to " + str(patrol_right_boundary))
	print("Jump positions: " + str(jump_points))
	print("Center position for dialog: " + str(center_position_x))
	print("Starting in WALKING state")
	
	# Make sure to connect to detection area if not already done by parent
	connect_to_detection_area()

# Explicitly calculate patrol boundaries based on parent position
func calculate_patrol_boundaries():
	# Find parent burgturm node
	var parent_burgturm = get_parent()
	if parent_burgturm:
		# Calculate absolute positions based on parent's position
		var parent_position_x = parent_burgturm.global_position.x
		
		# Calculate patrol boundaries
		patrol_left_boundary = parent_position_x + patrol_left_offset
		patrol_right_boundary = parent_position_x + patrol_right_offset
		
		# Calculate jump positions
		jump_left_position = parent_position_x + jump_left_offset
		jump_right_position = parent_position_x + jump_right_offset
		
		# Update patrol and jump points
		patrol_points = [patrol_left_boundary, patrol_right_boundary]
		jump_points = [jump_left_position, jump_right_position]
		
		print("Recalculated boundaries based on parent at " + str(parent_position_x))
	else:
		print("WARNING: Could not find parent node!")

# Calculate center position for dialog
func calculate_center_position():
	# Find parent burgturm node
	var parent_burgturm = get_parent()
	
	if parent_burgturm:
		center_position_x = parent_burgturm.global_position.x
		if debug_mode:
			("coming to tower position: " + str(center_position_x))
	else:
		center_position_x = 0
		if debug_mode:
			print("Gate and parent not found, using center position: 0")

# Connect to detection area if needed
func connect_to_detection_area():
	var detection_area = get_node_or_null("../DetectionArea")
	if detection_area:
		# Connect to the detection area signals if they exist
		if not detection_area.is_connected("body_entered", Callable(self, "_on_area_body_entered")):
			detection_area.connect("body_entered", Callable(self, "_on_area_body_entered"))
			print("TowerGuard connected to DetectionArea body_entered")
		
		if not detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_body_exited")):
			detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
			print("TowerGuard connected to DetectionArea body_exited")

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
		1:
			# Add handling for stage 1 - transition to next dialogue
			dialog_stage = 2
			# Move to center for continuing dialogue
			calculate_center_position()
			move_to_center_for_dialog(0)  # Call with minimal delta
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

			# Only return to patrol if gate not opened and player helped Thomas
			if not is_gate_open and not has_player_helped_thomas:
				set_state(State.WALKING)
			else:
				# Stay in talking state if gate is being opened
				set_state(State.TALKING)

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

# Handler for when player enters the Burgturm's DetectionArea or any other area
func _on_area_body_entered(body):
	if debug_mode:
		print("Detection area body entered: " + str(body.name))
		
	if body.is_in_group("player") and not player_entered_area:
		player_entered_area = true
		player_reference = body
		player_in_range = true
		
		if debug_mode:
			print("Player entered gate area, guard immediately stopping patrol to approach")
		
		# Immediately switch to go_to_player_immediately
		if not dialog_initiated:
			# Stop current movement
			velocity = Vector2.ZERO
			# Set player_entered_area flag
			player_entered_area = true
			
			# Debug info
			print("Detection area triggered, player_entered_area set to true")

# Override detection area signal for when player leaves
func _on_detection_area_body_exited(body):
	super._on_detection_area_body_exited(body)
	
	# If player leaves during dialog, reset dialog state
	if body.is_in_group("player"):
		player_entered_area = false
		player_in_range = false
		
		# Speech ending is handled in the parent class now
		if dialog_initiated:
			dialog_initiated = false
			dialog_stage = 0
			
			# Return to patrol
			set_state(State.WALKING)
			
			if debug_mode:
				print("Player left during dialog, resetting dialog state")

# Set the status of Thomas being helped (for testing)
func set_thomas_helped(helped: bool):
	has_player_helped_thomas = helped
	
	if debug_mode:
		print("Thomas helped status set to: ", helped)

# Override to immediately respond when player is at gate
func follow_patrol_path(delta):
	# If player is at gate, immediately stop patrol and go to player
	if player_entered_area and player_in_range:
		go_to_player_immediately(delta)
	else:
		# Otherwise, follow normal patrol behavior
		super.follow_patrol_path(delta)
