class_name NPCBase
extends CharacterBody2D

# Physics constants - similar to player
var SPEED = 100.0
var JUMP_VELOCITY = -400.0
var GRAVITY = 980.0

# NPC State enum
enum State {IDLE, WALKING, JUMPING, TALKING, WAITING}

# Movement variables
var current_state = State.IDLE
var movement_direction = 1  # 1 = right, -1 = left
var patrol_points = []
var current_patrol_index = 0
var target_position = Vector2.ZERO
var jump_points = []  # Array of x positions where NPC should jump
var wait_points = {}  # Dictionary of x positions and wait times {position: time}
var wait_timer = 0.0

# Speech bubble variables
var active_speech_bubble = null
var continue_button = null  # Reference to the continue button
var speech_bubble_offset = Vector2(0, -100)
var speech_bubble_duration = 3.0
var speech_font_size = 16
var is_speaking = false
var speech_queue = []
var waiting_for_input = false  # Flag to indicate waiting for button click

# Animation variables
var current_animation = "idle"
var character_sprites
var npc_outfit = {}
var flip_h = false

# Debug mode
@export var debug_mode: bool = true


# NPC behavior variables
var player_in_range = false
var player_reference = null
var interaction_distance = 100.0

func _ready():
	# Initialize character_sprites if it exists
	character_sprites = get_node_or_null("character_sprites")
	
	# Set up outfit if character_sprites is available
	if character_sprites:
		npc_outfit = character_sprites.default_outfit.duplicate(true)
	
	# Initialize patrol points if not set
	if patrol_points.is_empty() and has_node("PatrolPoints"):
		var patrol_node = get_node("PatrolPoints")
		for child in patrol_node.get_children():
			patrol_points.append(child.global_position.x)
	
	if debug_mode:
		print("NPC initialized with ", patrol_points.size(), " patrol points")
		print("Jump points: ", jump_points)
		print("Wait points: ", wait_points)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	match current_state:
		State.IDLE:
			velocity.x = 0
			current_animation = "idle"
		
		State.WALKING:
			follow_patrol_path(delta)
			current_animation = "walking"
		
		State.JUMPING:
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				current_animation = "jumping"
		
		State.TALKING:
			velocity.x = 0
			current_animation = "idle"
		
		State.WAITING:
			velocity.x = 0
			current_animation = "idle"
			wait_timer -= delta
			if wait_timer <= 0:
				set_state(State.WALKING)
	
	# Update animation based on movement direction
	if velocity.x > 0:
		flip_h = true  # Flipped when moving right
	elif velocity.x < 0:
		flip_h = false  # Not flipped when moving left
	
	# Apply outfit and animation
	update_outfit_sprites()
	
	# Move the character
	move_and_slide()

# Set NPC state
func set_state(new_state):
	current_state = new_state
	
	if debug_mode:
		print("NPC state changed to: ", State.keys()[new_state])

# Follow patrol path logic
func follow_patrol_path(delta):
	if patrol_points.is_empty():
		return
	
	var target_x = patrol_points[current_patrol_index]
	var distance_to_target = target_x - global_position.x
	var direction = sign(distance_to_target)
	
	# Debug output for patrol movement
	if debug_mode and Engine.get_frames_drawn() % 60 == 0:  # Only print once per second
		print("NPC at position: ", global_position.x, " target: ", target_x, " distance: ", distance_to_target)
	
	# Check if we need to jump at this position
	for jump_pos in jump_points:
		if abs(global_position.x - jump_pos) < 5 and is_on_floor():
			velocity.y = JUMP_VELOCITY
			if debug_mode:
				print("Jumping at position: ", global_position.x)
			break
	
	# Check if we need to wait at this position
	for wait_pos in wait_points.keys():
		if abs(global_position.x - wait_pos) < 5:
			wait_timer = wait_points[wait_pos]
			set_state(State.WAITING)
			if debug_mode:
				print("Waiting at position: ", global_position.x, " for ", wait_timer, " seconds")
			return
	
	# Move towards target
	if abs(distance_to_target) < 5:  # Close enough to target
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()  # Cycle through points
		if debug_mode:
			print("Reached patrol point, moving to index: ", current_patrol_index)
	else:
		velocity.x = direction * SPEED
		movement_direction = direction

# Display speech bubble
func say(text: String, duration: float = 0.0):
	if duration > 0:
		speech_bubble_duration = duration
	
	if is_speaking:
		# Queue message for later
		speech_queue.append({"text": text, "duration": speech_bubble_duration})
		return
	
	# Create and display speech bubble
	if active_speech_bubble:
		active_speech_bubble.queue_free()
	
	active_speech_bubble = create_speech_bubble(text)
	add_child(active_speech_bubble)
	active_speech_bubble.position = speech_bubble_offset
	
	set_state(State.TALKING)
	is_speaking = true
	waiting_for_input = true
	
	# Create continue button
	create_continue_button()
	
	if debug_mode:
		print("Speech started, waiting for button click")

# Continue dialog - should be overridden by child classes
func continue_dialog():
	end_speech()

# End current speech and check queue
func end_speech():
	is_speaking = false
	waiting_for_input = false
	
	remove_continue_button()
	
	if active_speech_bubble:
		active_speech_bubble.queue_free()
		active_speech_bubble = null
	
	# Check if there are more messages in queue
	if not speech_queue.is_empty():
		var next_speech = speech_queue.pop_front()
		say(next_speech.text, next_speech.duration)
	else:
		# Return to previous state (usually walking or idle)
		set_state(State.WALKING)
		
		if debug_mode:
			print("Speech ended, returning to WALKING state")

# Create a speech bubble
func create_speech_bubble(text: String) -> Node2D:
	# Root node
	var bubble = Node2D.new()
	bubble.name = "SpeechBubble"
	bubble.z_index = 3  # Ensure it's on top
	
	# RichTextLabel for text
	var label = RichTextLabel.new()
	label.name = "Label"
	label.text = text
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(220, 0)
	label.size = Vector2(220, 0)  # Will be expanded automatically
	label.position = Vector2(-110, -80)
	label.add_theme_font_size_override("normal_font_size", speech_font_size)
	label.add_theme_color_override("default_color", Color(1, 1, 1, 1))
	bubble.add_child(label)
	
	# Update background after text size is determined
	call_deferred("update_speech_bubble_background", bubble, label)
	
	return bubble

# Add background to speech bubble after text size is known
func update_speech_bubble_background(bubble: Node2D, label: RichTextLabel):
	await get_tree().process_frame
	
	# Get text size
	var text_height = label.size.y
	var text_width = label.size.x
	
	# Create background
	var background = ColorRect.new()
	background.name = "Background"
	background.size = Vector2(text_width + 20, text_height + 20)  # Add padding
	background.position = Vector2(label.position.x - 10, label.position.y - 10)  # Offset for padding
	background.color = Color(0.2, 0.2, 0.2, 0.8)
	
	# Add background behind label
	bubble.add_child(background)
	bubble.move_child(background, 0)
	
	# Add triangle pointer
	var point = Polygon2D.new()
	point.name = "Point"
	point.polygon = PackedVector2Array([Vector2(0, 0), Vector2(-10, -10), Vector2(10, -10)])
	point.color = Color(0.2, 0.2, 0.2, 0.8)
	point.position = Vector2(0, background.position.y + background.size.y)
	bubble.add_child(point)

# Create continue button
func create_continue_button():
	if continue_button != null:
		return
		
	continue_button = Control.new()
	continue_button.name = "ContinueButton"
	continue_button.position = Vector2(-50, 30) # Position below speech bubble
	continue_button.z_index = 5 # Make sure it's on top
	add_child(continue_button)
	
	# Add button
	var button = Button.new()
	button.text = "Weiter"
	button.size = Vector2(100, 30)
	button.add_theme_font_size_override("font_size", 14)
	
	# GEÄNDERT: Stellen Sie sicher, dass der Button korrekt verbunden ist
	if not button.is_connected("pressed", Callable(self, "_on_continue_button_pressed")):
		button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	
	continue_button.add_child(button)
	
	# HINZUGEFÜGT: Stellen Sie sicher, dass der Button sichtbar und bedienbar ist
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Make sure the button is visible and on top
	continue_button.show()
	
	if debug_mode:
		print("Continue button created")

# Remove continue button
func remove_continue_button():
	if continue_button:
		continue_button.queue_free()
		continue_button = null
		
		if debug_mode:
			print("Continue button removed")

# Button click handler
func _on_continue_button_pressed():
	if debug_mode:
		print("Continue button pressed, waiting_for_input=", waiting_for_input, ", is_speaking=", is_speaking)
	
	# GEÄNDERT: Stellen wir sicher, dass es immer den Dialog fortsetzt
	waiting_for_input = false
	continue_dialog()
	
	# HINZUGEFÜGT: Zusätzliches Debug-Logging
	if debug_mode:
		print("After button press - dialog state updated")

# Update outfit sprites
func update_outfit_sprites():
	if character_sprites:
		# Handle direction for all child sprite nodes
		for child in character_sprites.get_children():
			if child.has_method("set_flip_h") or "flip_h" in child:
				child.flip_h = flip_h
		
		# Update the outfit animations
		character_sprites.update_outfit(npc_outfit, current_animation)

# Check for player proximity
func check_player_interaction():
	if player_reference and player_in_range:
		var distance = global_position.distance_to(player_reference.global_position)
		if distance <= interaction_distance:
			return true
	return false

# Set the NPC's patrol path
func set_patrol_path(points: Array):
	patrol_points = points
	current_patrol_index = 0
	if debug_mode:
		print("New patrol path set with ", points.size(), " points")

# Set points where the NPC should jump
func set_jump_points(points: Array):
	jump_points = points
	if debug_mode:
		print("Jump points set: ", points)

# Set wait points and durations
func set_wait_points(points: Dictionary):
	wait_points = points
	if debug_mode:
		print("Wait points set: ", points)

# Handle player entering interaction range
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_reference = body
		if debug_mode:
			print("Player entered detection area")

# Handle player leaving interaction range
func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		waiting_for_input = false
		remove_continue_button()
		
		if debug_mode:
			print("Player exited detection area")

# Virtual method for interaction
func interact():
	# Override in child class
	pass
