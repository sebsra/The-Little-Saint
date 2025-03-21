class_name Player
extends CharacterBody2D

@export var joystick_right: VirtualJoystick

# envrionment variables
var SPEED
var JUMP_VELOCITY
var FLY_VELOCITY
var GRAVITY

# character mode variables
var mode
var passed_fly_time
var jump_counter
var ready_for_jump
var allowed_jumps

# character health
var hud

#character design variables
var player_animations
var current_animation
var player_outfit
var play_attack_animation 
var attack_animation

var config = ConfigFile.new() # Create a new ConfigFile instance

func _ready() -> void:
	# Initialize your global variables here
	hud = get_node("../../HUD")
	SPEED = 200.0
	JUMP_VELOCITY = -250.0
	FLY_VELOCITY = -150.0
	GRAVITY = 300
	mode = "normal"
	passed_fly_time = 0.0
	jump_counter = 0
	ready_for_jump = true
	player_animations = get_node("character_sprites").animation_frames
	current_animation = "idle"
	allowed_jumps = 1
	play_attack_animation = false
	attack_animation = "idle"
	
	var default_player_outfit = get_node("character_sprites").default_outfit
	get_node("character_sprites/masks").visible = false
	player_outfit = default_player_outfit

	# Load the ConfigFile if it exists
	var err = config.load("user://settings.cfg")
	if err == OK: # If the ConfigFile loaded successfully
		# Get the values from the ConfigFile
		SPEED = config.get_value("settings", "SPEED", 200.0)
		JUMP_VELOCITY = config.get_value("settings", "JUMP_VELOCITY", -250.0)
		FLY_VELOCITY = config.get_value("settings", "FLY_VELOCITY", -150.0)
		GRAVITY = config.get_value("settings", "GRAVITY", 500)
		# mode = config.get_value("settings", "mode", "normal")
		passed_fly_time = config.get_value("settings", "passed_fly_time", 0.0)
		jump_counter = config.get_value("settings", "jump_counter", 0)
		ready_for_jump = config.get_value("settings", "ready_for_jump", true)
		#allowed_jumps = config.get_value("settings", "allowed_jumps", 1)
		player_outfit = config.get_value("settings", "outfit", default_player_outfit)
		# TO-DO: load dict wheaether category is visible or not

func save_settings():
	# Set the values in the ConfigFile
	config.set_value("settings", "SPEED", SPEED)
	config.set_value("settings", "JUMP_VELOCITY", JUMP_VELOCITY)
	config.set_value("settings", "FLY_VELOCITY", FLY_VELOCITY)
	config.set_value("settings", "GRAVITY", GRAVITY)
	config.set_value("settings", "mode", mode)
	config.set_value("settings", "passed_fly_time", passed_fly_time)
	config.set_value("settings", "jump_counter", jump_counter)
	config.set_value("settings", "ready_for_jump", ready_for_jump)
	config.set_value("settings", "allowed_jumps", allowed_jumps)
	config.set_value("settings", "outfit", player_outfit, )

	# Save the ConfigFile to the disk
	config.save("user://settings.cfg")

func _process(delta):
	# Add the gravity.
	Engine.physics_ticks_per_second = 240
	# In case of Death
	if hud.lifes == 0:
		death()
	# Read the joystick input 
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	if Input.is_action_just_pressed("attack"):
		print("attack")
		play_attack_animation = true
	if Input.is_action_just_pressed("defend"):
		print("defend")
	if Input.is_action_just_pressed("Menu"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
	# All Modes.
	velocity.y += GRAVITY * delta

	if x_input != 0:
		velocity.x = x_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 30)

	if is_on_floor():
		jump_counter = 0
		ready_for_jump = true
		passed_fly_time = 0.0
		
	elif jump_counter == 0	:
		ready_for_jump = false
	
	if y_input > 0.4 && jump_counter < allowed_jumps:
		if ready_for_jump:
			velocity.y = JUMP_VELOCITY * y_input
			jump_counter += 1
			ready_for_jump = false
	elif y_input < 0.4:
		ready_for_jump = true
		

	if mode == "fly":
		allowed_jumps = 1

		# Check if elixir is available
		if hud.elixir_fill_level > 0.0:
			if passed_fly_time < 4:
				passed_fly_time += delta
				
				# Allow movement in the air while flying
				if y_input != 0:
					velocity.y = FLY_VELOCITY * y_input

			# Reduce elixir by 25% every time fly mode is triggered
			if passed_fly_time >= 4.0:  
				hud.use_softpower()  # Drain 25% elixir
				passed_fly_time = 0.0  # Reset flight time counter

		else:
			# If no elixir left, return to normal mode
			mode = "normal"
			print("Elixir empty! Returning to normal mode.")

	# Ensure the player can only fly again after landing
	if is_on_floor() and mode == "normal":
		allowed_jumps = 1  # Reset jumps when the player lands



	move_and_slide()

	# Set Animation
	if x_input == 0 && y_input == 0 && current_animation != "dead":
		current_animation = "idle"
	elif x_input != 0 && y_input <= 0.4:
		current_animation = "animation3"
	elif y_input > 0.4 or y_input < - 0.4:
		current_animation = "idle"
	
	if play_attack_animation:
		current_animation = attack_animation
		

	# Set Outfit
	for outfit in player_outfit:
		var animated_sprite = get_node("character_sprites/"+ outfit)
		var selected_outfit = player_outfit[outfit]
		
		if str(selected_outfit) == "none":
			animated_sprite.visible = false
		else:
			animated_sprite.play(str(selected_outfit))
			animated_sprite.speed_scale = 2.0
			animated_sprite.flip_h = x_input > 0
			if animated_sprite.frame >= player_animations[current_animation][-1]:
				play_attack_animation = false
				
			if (animated_sprite.frame < player_animations[current_animation][0] or
				animated_sprite.frame >= player_animations[current_animation][ - 1]):
					animated_sprite.frame = player_animations[current_animation][0]

func _on_test_portal_entered(_body):
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
	mode = "fly"
	save_settings()

func _on_elias_portal_entered(_body):
	print("Elias")
	save_settings() # Replace with function body.

func _on_ardit_portal_entered(_body):
	get_tree().change_scene_to_file("res://Arrogance.tscn")
	save_settings() # Replace with function body.

func _on_sebastian_portal_entered(_body):
	mode = "normal"
	get_tree().change_scene_to_file("res://scenes/levels/sebastian_levels/level_1.tscn")
	save_settings() # Replace with function body.

func _on_prince_portal_entered(_body):
	get_tree().change_scene_to_file("res://scenes/levels/prince_levels/platform.tscn")
	save_settings()

		#current_animation = "dead"
		#current_animation = "hurt"

func _on_fallzone_body_entered(_body):
	get_tree().change_scene_to_file("res://scenes/levels/ardit_levels/arrogance.tscn")

func _on_life_up_body_entered(_body):
	get_parent().get_node("HUD").change_life(0.25)

func _on_life_down_body_entered(_body):
		get_parent().get_node("HUD").change_life(-0.25)
		
func death():
	$CollisionShape2D.disabled = true
	current_animation = "death"
	self.queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
	


func _on_test_portal_body_entered(_body):
	get_tree().change_scene_to_file("res://scenes/levels/adventure_mode/adventure_level.tscn")
