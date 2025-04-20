class_name BeggarChild
extends NPCBase

# Signal emitted when beggar is helped
signal helped

# Donation tracking
var has_been_helped = false
var required_donation = 5 # Coins required to help
var dialog_active = false

# Input detection for U+I combination
var u_pressed = false
var i_pressed = false
var dialog_sequence = 0

# Animation control
var animation_timer = 0.0
var animation_duration = 2.0
var current_custom_animation = "idle"

func _ready():
	# Call parent ready
	super._ready()
	npc_outfit = { "beard": "none", "bodies": "4", "clothes_complete": "none", "clothes_down": "7", "clothes_up": "10", "earrings": "none", "eyes": "5", "glasses": "none", "hair": "45", "hats": "none", "lipstick": "none", "shoes": "6" }
	
	# Disable movement - stay in one place
	SPEED = 0.0
	
	# Connect to PopupManager signals
	if get_node_or_null("/root/PopupManager"):
		PopupManager.dialog_confirmed.connect(_on_dialog_confirmed)
		PopupManager.dialog_canceled.connect(_on_dialog_canceled)

func _process(delta):
	super._process(delta)
	# Process input for donation (U+I key combination)
	if not dialog_active and player_in_range:
		check_donation_input()

# Override physics process to prevent movement and force our animation
func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += 2500.0 * delta
	else:
		velocity.y = 0
	
	# Keep X velocity at zero to prevent horizontal movement
	velocity.x = 0
	
	# Update animation timer
	animation_timer += delta
	
	# Switch animation every 2 seconds
	if animation_timer >= animation_duration:
		animation_timer = 0.0
		current_custom_animation = "frontal_hands_up" if current_custom_animation == "idle" else "idle"
	
	# Force our custom animation
	current_animation = current_custom_animation
	
	# Apply movement
	move_and_slide()
	
	# Update animations if sprites exist
	if character_sprites:
		character_sprites.update_outfit(npc_outfit, current_animation)

# Check for U+I key combination
func check_donation_input():
	if Input.is_key_pressed(KEY_U) and not u_pressed:
		u_pressed = true
	
	if Input.is_key_pressed(KEY_I) and not i_pressed:
		i_pressed = true
	
	# If both are pressed simultaneously and player is in range
	if u_pressed and i_pressed and player_in_range and not has_been_helped and not dialog_active:
		prompt_donation()
		
		# Reset keys
		u_pressed = false
		i_pressed = false
	
	# Reset when keys are released
	if not Input.is_key_pressed(KEY_U):
		u_pressed = false
	
	if not Input.is_key_pressed(KEY_I):
		i_pressed = false

# Override continue_dialog to handle dialog sequence without showing continue button for all except first
func continue_dialog():
	if has_been_helped:
		# Auto-progress, no continue button
		say("Danke für die Münzen! Jetzt kann ich mir bald was zu essen holen.", false)
		return
		
	match dialog_sequence:
		0:
			# Only first message needs a continue button
			say("Hallo... hast du vielleicht ein paar Münzen für mich? Mein Bauch tut so weh vor Hunger...", true)
			dialog_sequence = 1
		1:
			# Second message with auto-progress
			say("Ich kann nicht laufen und hab seit Tagen nichts mehr gegessen. Bitte hilf mir.", true)
			dialog_sequence = 2
		2:
			# Third message with auto-progress
			say("Mit " + str(required_donation) + " Münzen könnte ich mir was zu essen kaufen. Drück einfach U+I, wenn du mir helfen willst.", true)
			dialog_sequence = 0
		_:
			end_speech()
			
# Interaction override
func interact():
	if has_been_helped:
		# Auto-progress, no continue button
		say("Danke nochmal für die Münzen! Ich hoffe, ich kann mir bald was zu essen kaufen.", 3.0, false)
		return
	
	continue_dialog()

# Show donation confirmation dialog
func prompt_donation():
	if dialog_active:
		return
	dialog_active = true
	if get_node_or_null("/root/PopupManager"):
		PopupManager.confirm(
			"Spende bestätigen",
			"Wirklich " + str(required_donation) + " goldene Münzen verschenken?",
			"Behalten", "Spenden"
		)

# Signal handler for dialog confirmation
func _on_dialog_confirmed(_dialog_id: String):
	dialog_active = false
	process_donation()

# Signal handler for dialog cancellation
func _on_dialog_canceled(_dialog_id: String):
	dialog_active = false
	
	# Manuell den Sprechzustand zurücksetzen, damit die Nachricht sofort angezeigt wird
	end_speech()
	
	# Jetzt die neue Nachricht anzeigen
	say("Ich verstehe... Ich muss wohl weiter hungern.\n", false)

# Process the donation if confirmed
func process_donation():
	# Check if player has enough coins
	if get_node_or_null("/root/GlobalHUD"):
		if GlobalHUD.coins < required_donation:
			# Erst Sprechzustand zurücksetzen
			end_speech()
			# Auto-progress, no continue button
			say("Oh... du hast nicht genug Münzen. Aber trotzdem danke, dass du helfen wolltest.", false)
			return
			
		# Deduct coins
		GlobalHUD.set_coins(GlobalHUD.coins - required_donation)
		
	# Mark as helped
	has_been_helped = true
	
	# Erst Sprechzustand zurücksetzen
	end_speech()
	
	# Thank the player - Auto-progress, no continue button
	say("Vielen Dank! Jetzt kann ich mir bald was zu essen kaufen! Ich hab so einen Hunger!", false)
	# Emit helped signal
	helped.emit()

# Override detection area signal for player interaction
func _on_detection_area_body_entered(body):
	super._on_detection_area_body_entered(body)
	
	# Auto-start dialog when player gets close enough
	if body.is_in_group("player") and not dialog_active:
		# Sicherstellen, dass kein vorheriger Sprechzustand aktiv ist
		end_speech()
		
		if not has_been_helped:
			dialog_sequence = 0
			continue_dialog()
		else:
			# Auto-progress, no continue button
			say("Danke nochmal für die Münzen! Bald kann ich mir was zu essen kaufen.", 3.0, false)

# Ensure signals are disconnected when node is removed
func _exit_tree():
	if get_node_or_null("/root/PopupManager"):
		if PopupManager.dialog_confirmed.is_connected(_on_dialog_confirmed):
			PopupManager.dialog_confirmed.disconnect(_on_dialog_confirmed)
		if PopupManager.dialog_canceled.is_connected(_on_dialog_canceled):
			PopupManager.dialog_canceled.disconnect(_on_dialog_canceled)
