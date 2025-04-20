# Optimierte Version der base_npc.gd mit zuverlässiger Sprechblasen-Positionierung

class_name NPCBase
extends CharacterBody2D

# Physics constants
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
var jump_points = []  # Array of x positions where NPC should jump
var wait_points = {}  # Dictionary of x positions and wait times {position: time}
var wait_timer = 0.0

# Speech system variables
var speech_bubble = null
var continue_button = null
var is_speaking = false
var speech_queue = []
var waiting_for_input = false
var speech_auto_continue_timer = 0.0  # Time remaining for auto-continue
var use_auto_continue = false  # Flag to track if auto-continue is enabled

# Speech bubble properties
var speech_bubble_duration = 3.0
var speech_font_size = 18  # Größerer Font wie im Popup-Dialog
var speech_bubble_margin = 60  # Distance of bubble from NPC
var bubble_is_below = false    # Tracks current bubble position
var speech_bubble_max_width = 280  # Maximum width of the speech bubble
var speech_bubble_padding = 20   # Padding inside the speech bubble
var bubble_bg_color = Color(0.12, 0.12, 0.15, 0.85)  # Background color with transparency

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
	
	# Set up detection area
	setup_detection_area()
	
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
	
	# Update outfit and animation
	update_outfit_sprites()
	
	# Move the character
	move_and_slide()

func _process(delta):
	# Check if speech bubble is active and player exists
	if speech_bubble != null and player_reference != null and is_speaking:
		# Check if player is below NPC (in Godot, higher Y value means lower on screen)
		var player_below = player_reference.global_position.y > global_position.y
		# If position changed, update bubble
		if player_below != bubble_is_below:
			bubble_is_below = player_below
			update_speech_bubble_position()
			if debug_mode:
				print("Player position changed, updating bubble position. Player is below: ", bubble_is_below)
	
	# Handle auto-continue timer if active
	if is_speaking and use_auto_continue and speech_auto_continue_timer > 0:
		speech_auto_continue_timer -= delta
		
		if speech_auto_continue_timer <= 0:
			# Time's up, continue dialogue
			if debug_mode:
				print("Auto-continue timer expired")
			
			# If waiting for input, simulate button press, otherwise just end speech
			if waiting_for_input:
				_on_continue_button_pressed()
			else:
				end_speech()
			
			# Reset timer
			speech_auto_continue_timer = 0.0
			use_auto_continue = false

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
	if debug_mode and Engine.get_frames_drawn() % 60 == 0:
		print("NPC at position: ", global_position.x, " target: ", target_x)
	
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
				print("Waiting at position: ", global_position.x)
			return
	
	# Move towards target
	if abs(distance_to_target) < 5:  # Close enough to target
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		velocity.x = direction * SPEED
		movement_direction = direction

# Reset auto-continue timer
func reset_auto_continue():
	speech_auto_continue_timer = 0.0
	use_auto_continue = false
	
	if debug_mode:
		print("Auto-continue timer reset")

# ---- Speech Bubble System ----

# Delayed say function (called via timer to prevent rapid progression)
func _delayed_say(text: String, show_continue_button: bool, duration: float):
	say(text, show_continue_button, duration)

func say(text: String, show_continue_button: bool = true, duration: float = 0.0):
	# Only display speech bubble if player is in range
	if not player_in_range:
		speech_queue.append({
			"text": text, 
			"show_continue_button": show_continue_button,
			"duration": duration
		})
		return
	
	# Only use an auto-continue timer if an explicit non-zero duration was provided
	use_auto_continue = duration > 0
	
	if is_speaking:
		speech_queue.append({
			"text": text, 
			"show_continue_button": show_continue_button,
			"duration": duration
		})
		return
	
	# IMPORTANT FIX: Only reset auto-continue timer if we're not using auto-continue
	# This prevents resetting the use_auto_continue flag that we just set above
	if not use_auto_continue:
		reset_auto_continue()
	
	# Create and display speech bubble
	if speech_bubble:
		speech_bubble.queue_free()
	
	# Check initial position - is player above or below NPC?
	bubble_is_below = player_reference.global_position.y > global_position.y
	
	# Create bubble
	speech_bubble = create_speech_bubble(text)
	add_child(speech_bubble)
	
	# Set initial position
	update_speech_bubble_position()
	
	set_state(State.TALKING)
	is_speaking = true
	
	if show_continue_button:
		waiting_for_input = true
		create_continue_button()
	
	# If a duration is specified and greater than zero, setup auto-continue
	if use_auto_continue:
		# Set the auto-continue timer
		speech_auto_continue_timer = duration
		
		if debug_mode:
			print("Auto-continue timer set for: ", duration, " seconds")
	else:
		if debug_mode:
			print("No auto-continue - waiting for player input or manual continue")
	
	if debug_mode:
		print("Speech bubble created with text: " + text)
		print("Initial bubble position: bubble_is_below = ", bubble_is_below)
		print("Show continue button: ", show_continue_button)
		print("Auto-continue: ", use_auto_continue)
		
# Create a speech bubble with more reliable sizing
func create_speech_bubble(text: String) -> Node2D:
	var bubble = Node2D.new()
	bubble.name = "SpeechBubble"
	bubble.z_index = 10
	
	# Vereinfachte und zuverlässigere Größenberechnung
	# Berechne Approximation der Textgröße basierend auf Zeichen und Zeilenumbrüchen
	var approx_chars_per_line = speech_bubble_max_width / (speech_font_size * 0.6)
	var lines = 1
	var current_line_chars = 0
	
	for char in text:
		if char == '\n':
			lines += 1
			current_line_chars = 0
		else:
			current_line_chars += 1
			if current_line_chars > approx_chars_per_line:
				lines += 1
				current_line_chars = 0
	
	# Minimale Größe garantieren
	var min_width = 220 
	var min_height = 100
	
	# Berechne Bubble-Größe basierend auf Text
	var text_width = max(min_width, min(text.length() * speech_font_size * 0.6, speech_bubble_max_width))
	var text_height = max(min_height, lines * (speech_font_size * 1.5) + speech_bubble_padding * 2)
	
	# Kleinere Breite für kurze Texte, größere für lange
	if text.length() < 50:
		text_width = min_width
	
	# Create properly sized background with better styling
	var background = Panel.new()
	background.name = "Background"
	background.size = Vector2(text_width, text_height)
	# Explizit centerieren auf x-Achse
	background.position = Vector2(-text_width/2, 0)
	
	# Panel-Design wie im Popup-Dialog
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bubble_bg_color
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.6, 0.6, 1.0, 0.7)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 4
	background.add_theme_stylebox_override("panel", panel_style)
	
	bubble.add_child(background)
	
	# Add text
	var label = RichTextLabel.new()
	label.name = "Label"
	label.bbcode_enabled = true
	label.text = text
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(text_width - speech_bubble_padding * 2, 0)
	label.size = Vector2(text_width - speech_bubble_padding * 2, text_height - speech_bubble_padding * 2)
	# Explizit x- und y-Position setzen
	label.position = Vector2(-text_width/2 + speech_bubble_padding, speech_bubble_padding)
	
	# Verbesserte Textdarstellung
	label.add_theme_font_size_override("normal_font_size", speech_font_size)
	label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9, 1))
	label.add_theme_constant_override("line_separation", 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Verhindere Überlauffehler bei langen Wörtern
	label.add_theme_constant_override("text_overrun_behavior", TextServer.OVERRUN_TRIM_ELLIPSIS)
	
	# Extra Pixel für Padding hinzufügen für Textumbruch-Sicherheit
	label.size.x += 4
	
	# Antialiasing für Text aktivieren
	if label.has_method("set_use_filter"):
		label.use_filter = true
	
	bubble.add_child(label)
	
	# Add a pointer triangle
	var point = Polygon2D.new()
	point.name = "Point"
	point.color = bubble_bg_color  # Gleiche Farbe wie der Hintergrund
	bubble.add_child(point)
	
	return bubble

# Update speech bubble position with expliziten Koordinaten in beiden Fällen
func update_speech_bubble_position():
	if not speech_bubble:
		return
		
	var background = speech_bubble.get_node("Background")
	var point = speech_bubble.get_node("Point")
	var label = speech_bubble.get_node("Label")
	
	if not background or not point or not label:
		return
	
	# Hole explizit die größe des Backgrounds für korrekte Positionierung
	var bg_width = background.size.x
	var bg_height = background.size.y
	
	# If bubble_is_below is true, position bubble below NPC
	if bubble_is_below:
		# Position bubble below NPC
		speech_bubble.position = Vector2(0, speech_bubble_margin)
		
		# Explizites Setzen von x und y für Background
		background.position = Vector2(-bg_width/2, 0)
		
		# Explizites Setzen von x und y für Label
		label.position = Vector2(-bg_width/2 + speech_bubble_padding, speech_bubble_padding)
		
		# Triangle pointing UP
		point.polygon = PackedVector2Array([Vector2(0, -10), Vector2(-10, 0), Vector2(10, 0)])
		point.position = Vector2(0, -10)
	else:
		# Position bubble above NPC
		speech_bubble.position = Vector2(0, -speech_bubble_margin)
		
		# Explizites Setzen von x und y für Background
		background.position = Vector2(-bg_width/2, -bg_height)
		
		# Explizites Setzen von x und y für Label
		label.position = Vector2(-bg_width/2 + speech_bubble_padding, -bg_height + speech_bubble_padding)
		
		# Triangle pointing DOWN
		point.polygon = PackedVector2Array([Vector2(0, 10), Vector2(-10, 0), Vector2(10, 0)])
		point.position = Vector2(0, 0)
	
	# Debug-Ausgabe für Positionierung
	if debug_mode:
		print("Speech bubble positioned, bubble_is_below: ", bubble_is_below)
		print("Background position: ", background.position)
		print("Label position: ", label.position)
	
	# Update continue button position
	position_continue_button()

# Create continue button
func create_continue_button():
	if continue_button:
		continue_button.queue_free()
	
	continue_button = Control.new()
	continue_button.name = "ContinueButton"
	
	# Add button with styled appearance
	var button = Button.new()
	button.text = "Weiter"
	button.size = Vector2(100, 30)
	
	# Button-Style vorbereiten
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.2, 0.2, 0.25, 0.85)  # Mit Transparenz
	button_style_normal.corner_radius_top_left = 8
	button_style_normal.corner_radius_top_right = 8
	button_style_normal.corner_radius_bottom_left = 8
	button_style_normal.corner_radius_bottom_right = 8
	
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.25, 0.25, 0.3, 0.85)  # Mit Transparenz
	button_style_hover.corner_radius_top_left = 8
	button_style_hover.corner_radius_top_right = 8
	button_style_hover.corner_radius_bottom_left = 8
	button_style_hover.corner_radius_bottom_right = 8
	
	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.15, 0.15, 0.2, 0.85)  # Mit Transparenz
	button_style_pressed.corner_radius_top_left = 8
	button_style_pressed.corner_radius_top_right = 8
	button_style_pressed.corner_radius_bottom_left = 8
	button_style_pressed.corner_radius_bottom_right = 8
	
	# Stile anwenden
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", button_style_normal)
	button.add_theme_stylebox_override("hover", button_style_hover)
	button.add_theme_stylebox_override("pressed", button_style_pressed)
	
	button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	continue_button.add_child(button)
	
	add_child(continue_button)
	continue_button.z_index = 11
	
	# Position the button
	position_continue_button()
	
	if debug_mode:
		print("Continue button created")

# Position continue button below the speech bubble - Verbesserte Version
func position_continue_button():
	if not continue_button or not speech_bubble:
		return
	
	var background = speech_bubble.get_node("Background")
	if not background:
		return
	
	# Hole explizit die größe des Buttons für korrekte Positionierung
	var button = continue_button.get_node("Button") if continue_button.has_node("Button") else continue_button.get_child(0)
	var button_width = button.size.x if button else 100
	
	# Explizites Positionieren in beiden Fällen
	if bubble_is_below:
		# Bubble is below NPC, so put button below bubble
		continue_button.position = Vector2(-button_width/2, speech_bubble.position.y + background.size.y + 10)
	else:
		# Bubble is above NPC, so put button below bubble
		# Korrigierte Positionierung unter der Blase, wenn sie über dem NPC ist
		continue_button.position = Vector2(-button_width/2, speech_bubble.position.y - background.size.y + background.size.y + 10)
		# Vereinfachte Berechnung für oben positionierte Blasen
		continue_button.position.y = speech_bubble.position.y + 10

# Button click handler
func _on_continue_button_pressed():
	if is_speaking:
		if debug_mode:
			print("Continue button pressed")
		waiting_for_input = false
		
		# Reset auto-continue timer 
		reset_auto_continue()
		
		# End current speech to reset state properly
		is_speaking = false
		
		if speech_bubble:
			speech_bubble.queue_free()
			speech_bubble = null
		
		if continue_button:
			continue_button.queue_free()
			continue_button = null
		
		# Keep the NPC in TALKING state
		set_state(State.TALKING)
		
		# Call continue_dialog to progress the conversation
		continue_dialog()

# Continue dialog - should be overridden by child classes
func continue_dialog():
	end_speech()

# End current speech and check queue
func end_speech():
	is_speaking = false
	waiting_for_input = false
	
	# Reset auto-continue timer
	reset_auto_continue()
	
	if continue_button:
		continue_button.queue_free()
		continue_button = null
	
	if speech_bubble:
		speech_bubble.queue_free()
		speech_bubble = null
	
	# Check if there are more messages in queue
	if not speech_queue.is_empty() and player_in_range:
		# Ensure proper timing gap between messages to prevent rapid auto-advancement
		var next_speech = speech_queue.pop_front()
		
		# Use a short timer to create a slight delay between messages
		# This prevents rapid auto-continuation cascades
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(Callable(self, "_delayed_say").bind(
			next_speech.text, next_speech.show_continue_button, next_speech.duration))
	else:
		# Return to previous state only if we're not in an ongoing dialogue
		# This can be determined by the current_state
		if current_state == State.TALKING:
			# Stay in talking state if there's more dialogue to come
			# Child classes can override this behavior
			pass
		else:
			# Return to walking state by default
			set_state(State.WALKING)

# Update outfit sprites
func update_outfit_sprites():
	if character_sprites:
		# Handle direction for all child sprite nodes
		for child in character_sprites.get_children():
			if child.has_method("set_flip_h") or "flip_h" in child:
				child.flip_h = flip_h
		
		# Update the outfit animations
		character_sprites.update_outfit(npc_outfit, current_animation)

# Set up the detection area
func setup_detection_area():
	if has_node("DetectionArea"):
		# Connect signals to existing detection area
		var area = get_node("DetectionArea")
		
		# Disconnect existing connections
		if area.is_connected("body_entered", Callable(self, "_on_detection_area_body_entered")):
			area.disconnect("body_entered", Callable(self, "_on_detection_area_body_entered"))
		if area.is_connected("body_exited", Callable(self, "_on_detection_area_body_exited")):
			area.disconnect("body_exited", Callable(self, "_on_detection_area_body_exited"))
		
		# Connect signals
		area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
		area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	else:
		create_detection_area()

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
		print("Created detection area for NPC")

# Handle player entering interaction range
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_reference = body
		
		# If there are queued messages, display them now
		if not speech_queue.is_empty() and not is_speaking:
			var next_speech = speech_queue.pop_front()
			say(next_speech.text, next_speech.duration, next_speech.show_continue_button)
			
		if debug_mode:
			print("Player entered detection area")

# Handle player leaving interaction range
func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		
		# End any active speech when player leaves
		if is_speaking:
			end_speech()
			
		if debug_mode:
			print("Player exited detection area")

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

# Set points where the NPC should jump
func set_jump_points(points: Array):
	jump_points = points

# Set wait points and durations
func set_wait_points(points: Dictionary):
	wait_points = points

# Virtual method for interaction - to be overridden by child classes
func interact():
	# Override in child class
	pass

# Ensure all resources are properly cleaned up
func _exit_tree():
	pass
