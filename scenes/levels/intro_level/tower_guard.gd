class_name TowerGuard
extends NPCBase

# Tower Guard specific properties
var has_player_helped_thomas = false
var gate_node = null
var dialog_initiated = false
var dialog_stage = 0
var is_gate_open = false
var player_entered_area = false
var has_completed_dialog = false  # Flag to track if dialog was completed

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

# Flag to track if we need to move to center
var should_move_to_center = false


func _ready():
	# Call parent ready function
	super._ready()
	npc_outfit = { "beard": "none", "bodies": "6", "clothes_complete": "none", "clothes_down": "11", "clothes_up": "74", "earrings": "none", "eyes": "18", "glasses": "1", "hair": "6", "hats": "1", "lipstick": "none", "shoes": "3" }

	
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
			print("Coming to tower position: " + str(center_position_x))
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
	# Apply gravity even when moving to center
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Check if we need to move to center after initial dialog
	if should_move_to_center:
		move_to_center_for_dialog(delta)
		# Move the character with gravity
		move_and_slide()
	else:
		# Call parent physics process for normal behavior
		super._physics_process(delta)

# Move to center position for dialog
func move_to_center_for_dialog(delta):
	var distance_to_center = center_position_x - global_position.x
	
	if abs(distance_to_center) < center_position_tolerance and is_on_floor():
		# We're at the center and on the ground, continue dialog
		should_move_to_center = false
		dialog_stage = 2
		continue_dialog()
		return
	
	# Move towards center
	var direction = sign(distance_to_center)
	velocity.x = direction * APPROACH_SPEED  # Use increased speed here too
	movement_direction = direction
	current_animation = "walking"
	
	# Note: We don't call move_and_slide() here anymore, it's handled in _physics_process
	
	if debug_mode:
		print("Moving to center: current=" + str(global_position.x) + 
			  ", target=" + str(center_position_x) + ", distance=" + str(distance_to_center))

# Start dialog with player
func start_dialog():
	dialog_initiated = true
	dialog_stage = 1
	
	# Initial greeting - CORRECTED ORDER OF PARAMETERS
	say("Halt! Wer begehrt Einlass?", true, 1.5)
	
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
			# After initial dialog, start moving to center
			should_move_to_center = true
			# Allow dialog to continue only when NPC reaches center and is on floor
			# dialog_stage will be set to 2 when we reach center
			
		2:
			# Dialog based on whether Thomas was helped
			if has_player_helped_thomas:
				say("Ich bin der Wächter dieses Tores. Ich sehe, du hast ein gutes Herz bewiesen. Das spricht für dich.", true, 0)
			else:
				say("Ich bin der Wächter dieses Tores. Ich konnte von hier aus sehen, dass du kein Mitgefühl hattest.", true, 0)
			dialog_stage = 3
		
		3:
			# Bible quote - more cryptic
			if has_player_helped_thomas:
				say("Die Barmherzigen finden selbst Barmherzigkeit. Du hast es verstanden.", true, 0)
			else:
				say("Wer den Geringsten nicht hilft, hat den Weg nicht erkannt. Kehre zurück und öffne deine Augen.", true, 3.0)
			dialog_stage = 4
		
		4:
			# Final response
			if has_player_helped_thomas:
				say("Der Weg ist nun für dich geöffnet.", false, 2.0)
				# Schedule gate opening
				get_tree().create_timer(2.5).connect("timeout", Callable(self, "open_gate"))
			else:
				say("Geh zurück und finde den wahren Weg der Nächstenliebe. Er liegt direkt vor dir.", true, 3.0)
			dialog_stage = 5
		
		5:
			# End dialog
			dialog_initiated = false
			dialog_stage = 0
			has_completed_dialog = true  # Mark dialog as completed

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

# Handler for when player enters the Burgturm's DetectionArea or any other area
func _on_area_body_entered(body):
	if debug_mode:
		print("Detection area body entered: " + str(body.name))
		
	if body.is_in_group("player") and not has_completed_dialog:
		player_entered_area = true
		player_reference = body
		player_in_range = true
		
		# Reset flags to ensure proper flow
		should_move_to_center = false
		
		if debug_mode:
			print("Player entered gate area, starting dialog immediately")
		
		# Immediately start dialog
		start_dialog()

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
		
		# Reset dialog completion status so it can be triggered again
		has_completed_dialog = false
		should_move_to_center = false
			
		# Return to patrol
		set_state(State.WALKING)
		
		if debug_mode:
			print("Player left area, resetting dialog state and completion status")

# Set the status of Thomas being helped (for testing)
func set_thomas_helped(helped: bool):
	has_player_helped_thomas = helped
	
	if debug_mode:
		print("Thomas helped status set to: ", helped)

# Reset dialog completion status (for testing or when needed)
func reset_dialog_status():
	has_completed_dialog = false
	dialog_initiated = false
	dialog_stage = 0
	if debug_mode:
		print("Dialog status reset, can be triggered again")
