# Modified player.gd - Remove direct input handling and delegate to state machine

class_name Player
extends CharacterBody2D

@export var joystick_right: VirtualJoystick
@export var debug_mode: bool = false

# environment variables
var SPEED = 200.0
var JUMP_VELOCITY = -250.0
var FLY_VELOCITY = -150.0
var GRAVITY = 300

# character mode variables
var mode = "normal"
var passed_fly_time = 0.0
var jump_counter = 0
var ready_for_jump = true
var allowed_jumps = 1

# character health
var hud

# character design variables
var player_animations
var current_animation = "idle"
var player_outfit
var play_attack_animation = false
var attack_animation = "idle"

# Reference to the state machine
@onready var state_machine = $StateMachine

var config = ConfigFile.new() # Create a new ConfigFile instance

func _ready() -> void:
	# Initialize your global variables here
	hud = get_node("../../HUD")
	player_animations = get_node("character_sprites").animation_frames

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
		GRAVITY = config.get_value("settings", "GRAVITY", 300)
		passed_fly_time = config.get_value("settings", "passed_fly_time", 0.0)
		jump_counter = config.get_value("settings", "jump_counter", 0)
		ready_for_jump = config.get_value("settings", "ready_for_jump", true)
		player_outfit = config.get_value("settings", "outfit", default_player_outfit)

	if debug_mode:
		print("Player ready, State Machine initialized")

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
	config.set_value("settings", "outfit", player_outfit)

	# Save the ConfigFile to the disk
	config.save("user://settings.cfg")

# Helper method to play animations
func play_animation(anim_name: String):
	current_animation = anim_name

# Return gravity as a Vector2 to avoid conflicts with PhysicsBody2D
func calculate_gravity() -> Vector2:
	return Vector2(0, GRAVITY)

# Keep portal handlers and other methods
func _on_test_portal_entered(_body):
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
	mode = "fly"
	save_settings()

func _on_elias_portal_entered(_body):
	print("Elias")
	save_settings()

func _on_ardit_portal_entered(_body):
	get_tree().change_scene_to_file("res://Arrogance.tscn")
	save_settings()

func _on_sebastian_portal_entered(_body):
	mode = "normal"
	get_tree().change_scene_to_file("res://scenes/levels/sebastian_levels/level_1.tscn")
	save_settings()

func _on_prince_portal_entered(_body):
	get_tree().change_scene_to_file("res://scenes/levels/prince_levels/platform.tscn")
	save_settings()

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
