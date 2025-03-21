class_name Player
extends CharacterBody2D

@export var joystick_right: VirtualJoystick
@export var debug_mode: bool = false

# Environment variables - use constants from Constants singleton
var SPEED = Constants.PLAYER_DEFAULT_SPEED
var JUMP_VELOCITY = Constants.PLAYER_DEFAULT_JUMP_VELOCITY
var FLY_VELOCITY = Constants.PLAYER_DEFAULT_FLY_VELOCITY
var GRAVITY = Constants.PLAYER_DEFAULT_GRAVITY

# Character mode variables
var mode = "normal"
var passed_fly_time = 0.0
var jump_counter = 0
var ready_for_jump = true
var allowed_jumps = Constants.PLAYER_MAX_JUMPS

# Character health reference
var hud

# Character design variables
var player_animations
var current_animation = Constants.ANIMATION_IDLE
var player_outfit
var play_attack_animation = false
var attack_animation = Constants.ANIMATION_ATTACK

# Resource-based outfit system
var current_outfit: PlayerOutfitResource = null

# Reference to the state machine
@onready var state_machine = $StateMachine

func _ready() -> void:
	# Initialize your global variables here
	hud = get_node_or_null("../../HUD")
	player_animations = get_node("character_sprites").animation_frames

	# Initialize outfit with defaults
	var default_player_outfit = get_node("character_sprites").default_outfit
	get_node("character_sprites/masks").visible = false
	player_outfit = default_player_outfit.duplicate(true)

	# Create outfit resource
	current_outfit = PlayerOutfitResource.new()

	# Register with GameManager
	if get_node_or_null("/root/Global"):
		Global.register_player(self)

	# Connect to SaveManager signals
	if get_node_or_null("/root/SaveManager"):
		SaveManager.connect("load_completed", Callable(self, "_on_save_loaded"))
		SaveManager.connect("settings_loaded", Callable(self, "_on_settings_loaded"))
		
		# Load settings from SaveManager
		if SaveManager.current_save_data:
			update_from_save_data()
	
	if debug_mode:
		print("Player ready, State Machine initialized")
		print("Initial player stats: Speed=", SPEED, ", Jump=", JUMP_VELOCITY,
			  ", Fly=", FLY_VELOCITY, ", Gravity=", GRAVITY)

# Save current player settings
func save_settings():
	if get_node_or_null("/root/SaveManager"):
		SaveManager.save_settings()

# New methods for SaveManager integration
func _on_save_loaded(success, message):
	if success:
		update_from_save_data()

func _on_settings_loaded(success):
	if success:
		update_from_save_data()

func update_from_save_data():
	if not get_node_or_null("/root/SaveManager") or not SaveManager.current_save_data:
		print("No save data available to update from")
		return

	var save_data = SaveManager.current_save_data
	
	# Update movement parameters
	SPEED = save_data.player_speed
	JUMP_VELOCITY = save_data.player_jump_velocity
	FLY_VELOCITY = save_data.player_fly_velocity
	GRAVITY = save_data.player_gravity
	
	# Update state
	mode = save_data.player_mode
	passed_fly_time = save_data.player_passed_fly_time
	jump_counter = save_data.player_jump_counter
	ready_for_jump = save_data.player_ready_for_jump
	allowed_jumps = save_data.player_allowed_jumps

	# Apply outfit if available
	if save_data.player_outfit and not save_data.player_outfit.is_empty():
		# Update resource and dictionary
		if current_outfit:
			current_outfit.from_dictionary(save_data.player_outfit)
		else:
			current_outfit = PlayerOutfitResource.new().from_dictionary(save_data.player_outfit)

		# Apply current outfit to character
		player_outfit = save_data.player_outfit.duplicate(true)
		_update_outfit_visuals()
		
	if debug_mode:
		print("Updated player from save data: Speed=", SPEED, ", Jump=", JUMP_VELOCITY)
		print("Outfit loaded:", player_outfit)

# Update outfit sprite visibility and animations
func _update_outfit_visuals():
	for category in player_outfit:
		if has_node("character_sprites/" + category):
			var sprite = get_node("character_sprites/" + category)
			var value = str(player_outfit[category])
			
			if value == "none":
				sprite.visible = false
			else:
				sprite.visible = true
				sprite.animation = value
				sprite.frame = 1

# Helper method to play animations
func play_animation(anim_name: String):
	current_animation = anim_name

# Return gravity as a Vector2 to avoid conflicts with PhysicsBody2D
func calculate_gravity() -> Vector2:
	return Vector2(0, GRAVITY)

# Keep portal handlers and other methods
func _on_test_portal_entered(_body):
	if get_node_or_null("/root/Global"):
		Global.change_scene(Constants.MAIN_MENU_SCENE)
	mode = "fly"
	save_settings()

func _on_elias_portal_entered(_body):
	print("Elias")
	save_settings()

func _on_ardit_portal_entered(_body):
	if get_node_or_null("/root/Global"):
		Global.change_scene("res://Arrogance.tscn")
	save_settings()

func _on_sebastian_portal_entered(_body):
	mode = "normal"
	if get_node_or_null("/root/Global"):
		Global.change_scene("res://scenes/levels/sebastian_levels/level_1.tscn")
	save_settings()

func _on_prince_portal_entered(_body):
	if get_node_or_null("/root/Global"):
		Global.change_scene("res://scenes/levels/prince_levels/platform.tscn")
	save_settings()

func _on_fallzone_body_entered(_body):
	if get_node_or_null("/root/Global"):
		Global.change_scene("res://scenes/levels/ardit_levels/arrogance.tscn")

func _on_life_up_body_entered(_body):
	if hud:
		hud.change_life(0.25)

func _on_life_down_body_entered(_body):
	if hud:
		hud.change_life(-0.25)

func death():
	$CollisionShape2D.disabled = true
	current_animation = "dead"

	# Notify GameManager of player death
	if get_node_or_null("/root/Global"):
		Global.player_death()

	self.queue_free()
	
	if get_node_or_null("/root/Global"):
		Global.go_to_main_menu()

func _on_test_portal_body_entered(_body):
	if get_node_or_null("/root/Global"):
		Global.change_scene("res://scenes/levels/adventure_mode/adventure_level.tscn")

# New methods for gameplay enhancement
func set_movement_mode(new_mode: String) -> void:
	mode = new_mode

	if new_mode == "fly":
		passed_fly_time = 0.0

	if debug_mode:
		print("Movement mode changed to: ", new_mode)

func enable_attack(enable: bool) -> void:
	play_attack_animation = enable

func set_attack_animation(anim_name: String) -> void:
	attack_animation = anim_name

func add_extra_jumps(extra_jumps: int) -> void:
	allowed_jumps += extra_jumps

func take_damage(amount: float) -> void:
	if hud:
		hud.change_life(-amount / 100.0)

func bounce() -> void:
	velocity.y = JUMP_VELOCITY * 0.7 # Less powerful than a regular jump
