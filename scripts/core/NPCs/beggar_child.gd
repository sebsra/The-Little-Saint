class_name BeggarChild
extends NPCBase

# Donation tracking
var has_been_helped = false
var required_donation = 5 # Coins required to help
var donation_requested = false
var dialog_active = false

# Input detection for U+I combination
var u_pressed = false
var i_pressed = false
var dialog_sequence = 0
var current_dialog_id = ""

# Animation control
var animation_timer = 0.0
var animation_duration = 2.0  # Seconds between animation switches
var current_custom_animation = "idle"

func _ready():
	# Call parent ready
	super._ready()
	
	# Set default NPC values
	SPEED = 60.0
	
	# Disable movement - stay in one place
	SPEED = 0.0  # Setze Geschwindigkeit auf 0 um Bewegung zu verhindern
	
	# Set up detection area if it doesn't exist
	if not has_node("DetectionArea"):
		create_detection_area()
	
	# Connect to PopupManager signals once at initialization
	if get_node_or_null("/root/PopupManager"):
		PopupManager.dialog_confirmed.connect(_on_dialog_confirmed)
		PopupManager.dialog_canceled.connect(_on_dialog_canceled)
	
	if debug_mode:
		print("Beggar Child initialized, helped status: ", has_been_helped)

func _process(delta):
	# Process input for donation (U+I key combination)
	if not dialog_active:
		check_donation_input()

# Override physics process to prevent movement and force our animation
func _physics_process(delta):
	# Apply proper gravity (much higher than default)
	if not is_on_floor():
		velocity.y += 2500.0 * delta  # Using higher gravity value than the parent class
	else:
		velocity.y = 0  # Reset Y velocity when on floor
	
	# Keep X velocity at zero to prevent horizontal movement
	velocity.x = 0
	
	# Update animation timer
	animation_timer += delta
	
	# Switch animation every 2 seconds
	if animation_timer >= animation_duration:
		animation_timer = 0.0
		if current_custom_animation == "idle":
			current_custom_animation = "frontal_hands_up"  # Updated to correct animation name
		else:
			current_custom_animation = "idle"
	
	# Force our custom animation
	current_animation = current_custom_animation
	
	# Apply movement with proper gravity
	move_and_slide()
	
	# Handle animation ourselves
	if character_sprites:
		# Handle direction for all child sprite nodes
		for child in character_sprites.get_children():
			if child.has_method("set_flip_h") or "flip_h" in child:
				child.flip_h = flip_h
		
		# Update the outfit animations with our forced animation
		character_sprites.update_outfit(npc_outfit, current_animation)
		
		# Set animation speed based on the current animation
		# Slower for begging, normal for idle
		for child in character_sprites.get_children():
			if "speed_scale" in child:
				if current_custom_animation == "frontal_hands_up":
					child.speed_scale = 0.5  # Half speed for begging
				else:
					child.speed_scale = 1.0  # Normal speed for idle

# Check for U+I key combination
func check_donation_input():
	if Input.is_key_pressed(KEY_U) and not u_pressed:
		u_pressed = true
	
	if Input.is_key_pressed(KEY_I) and not i_pressed:
		i_pressed = true
	
	# If both are pressed simultaneously and player is in range
	if u_pressed and i_pressed and player_in_range and not has_been_helped and not dialog_active:
		prompt_donation()
		
		# Reset keys to prevent repeated triggering
		u_pressed = false
		i_pressed = false
	
	# Reset when keys are released
	if not Input.is_key_pressed(KEY_U):
		u_pressed = false
	
	if not Input.is_key_pressed(KEY_I):
		i_pressed = false

# Override continue_dialog to handle dialog sequence
func continue_dialog():
	if has_been_helped:
		say("Danke für die Münzen! Jetzt kann ich mir bald was zu essen holen.", 3.0)
		return
		
	match dialog_sequence:
		0:
			say("Hallo... hast du vielleicht ein paar Münzen für mich? Mein Bauch tut so weh vor Hunger...", 3.5)
			dialog_sequence = 1
		1:
			say("Ich kann nicht laufen und hab seit Tagen nichts mehr gegessen. Bitte hilf mir.", 3.0)
			dialog_sequence = 2
		2:
			say("Mit " + str(required_donation) + " Münzen könnte ich mir was zu essen kaufen. Drück einfach U+I wenn du mir helfen willst.", 3.5)
			dialog_sequence = 0
			donation_requested = true
		_:
			end_speech()

# Interaction override
func interact():
	if has_been_helped:
		say("Danke nochmal für die Münzen! Ich hoffe, ich kann mir bald was zu essen kaufen.", 3.0)
		return
	
	continue_dialog()

# Show donation confirmation dialog
func prompt_donation():
	if dialog_active:
		return
		
	dialog_active = true
	
	if get_node_or_null("/root/PopupManager"):
		current_dialog_id = PopupManager.confirm(
			"Spende bestätigen",
			"Möchtest du " + str(required_donation) + " Münzen an den kleinen Thomas geben?",
			"Leider nein", "Ja, gerne"
		)
		
		if debug_mode:
			print("Created donation dialog with ID: ", current_dialog_id)
	else:
		# Fallback if no PopupManager
		dialog_active = false
		print("ERROR: PopupManager not found")

# Signal handler for dialog confirmation
func _on_dialog_confirmed(dialog_id: String):
	if dialog_id == current_dialog_id:
		if debug_mode:
			print("Dialog confirmed: ", dialog_id)
			
		current_dialog_id = ""
		dialog_active = false
		process_donation()

# Signal handler for dialog cancellation
func _on_dialog_canceled(dialog_id: String):
	if dialog_id == current_dialog_id:
		if debug_mode:
			print("Dialog canceled: ", dialog_id)
			
		current_dialog_id = ""
		dialog_active = false
		
		# Express hunger when player declines
		say("Ich verstehe... Ich muss wohl weiter hungern.", 3.0)

# Process the donation if confirmed
func process_donation():
	# Check if player has enough coins
	if get_node_or_null("/root/GlobalHUD"):
		if GlobalHUD.coins < required_donation:
			# Player doesn't have enough coins
			say("Oh... du hast nicht genug Münzen. Aber trotzdem danke, dass du helfen wolltest.", 3.0)
			return
			
		# If we get here, player has enough coins
		# Deduct coins
		GlobalHUD.set_coins(GlobalHUD.coins - required_donation)
		
		# Mark as helped
		has_been_helped = true
		
		# Thank the player
		say("Vielen Dank! Jetzt kann ich mir bald was zu essen kaufen! Ich hab so einen Hunger!", 3.0)
		
		if debug_mode:
			print("Player donated to Thomas, helped status: true")
	else:
		# If GlobalHUD not found, just mark as helped for testing
		has_been_helped = true
		say("Vielen Dank! Jetzt kann ich mir bald was zu essen kaufen! Ich hab so einen Hunger!", 3.0)
		
		if debug_mode:
			print("GlobalHUD not found, simulating donation")

# Create a detection area for player interaction
func create_detection_area():
	var area = Area2D.new()
	area.name = "DetectionArea"
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 80.0  # Detection radius
	collision.shape = shape
	
	area.add_child(collision)
	add_child(area)
	
	# Connect signals
	area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	
	if debug_mode:
		print("Created detection area for Beggar Child")

# Override signal handler for player entering the detection area
func _on_detection_area_body_entered(body):
	super._on_detection_area_body_entered(body)
	
	# Auto-start dialog when player gets close enough
	if body.is_in_group("player") and not dialog_active:
		if not has_been_helped:
			dialog_sequence = 0
			continue_dialog()
		else:
			say("Danke nochmal für die Münzen! Bald kann ich mir was zu essen kaufen.", 3.0)

# Override signal handler for player exiting the detection area
func _on_detection_area_body_exited(body):
	super._on_detection_area_body_exited(body)

# Ensure signals are disconnected when node is removed
func _exit_tree():
	if get_node_or_null("/root/PopupManager"):
		if PopupManager.dialog_confirmed.is_connected(_on_dialog_confirmed):
			PopupManager.dialog_confirmed.disconnect(_on_dialog_confirmed)
		if PopupManager.dialog_canceled.is_connected(_on_dialog_canceled):
			PopupManager.dialog_canceled.disconnect(_on_dialog_canceled)
