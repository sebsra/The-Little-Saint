class_name SaveData
extends Resource

## Data structure for saved games in The Little Saint
## Stores player stats, game progress, and settings

# Version for compatibility checks
@export var save_version: int = 1

# Save metadata
@export var save_date: String = ""
@export var playtime_seconds: int = 0

# Player position and level
@export var player_position: Vector2 = Vector2.ZERO
@export var current_level: String = ""
@export var active_scene_state: Dictionary = {}

# Player stats
@export var health: float = 3.0
@export var coins: int = 0
@export var heaven_coins: int = 0
@export var player_speed: float = Constants.PLAYER_DEFAULT_SPEED
@export var player_jump_velocity: float = Constants.PLAYER_DEFAULT_JUMP_VELOCITY
@export var player_fly_velocity: float = Constants.PLAYER_DEFAULT_FLY_VELOCITY
@export var player_gravity: float = Constants.PLAYER_DEFAULT_GRAVITY

# Player state
@export var player_mode: String = "normal"
@export var player_passed_fly_time: float = 0.0
@export var player_jump_counter: int = 0
@export var player_ready_for_jump: bool = true
@export var player_allowed_jumps: int = 1

# Game settings
@export var difficulty: int = 1  # Default to NORMAL
@export var coin_type: int = 0   # Default to NORMAL coins

# Player appearance
@export var player_outfit: Dictionary = {}

# Game progress
@export var collected_coins: int = 0
@export var collected_heaven_coins: int = 0
@export var unlocked_levels: Array = []
@export var completed_quests: Array = []

# Message history
@export var message_history: Array = []

# Initialize with default values
func _init():
	save_date = Time.get_datetime_string_from_system(false, true)
	
	# Set default player outfit if none exists
	if player_outfit.is_empty():
		# Create a default outfit
		player_outfit = {
			"beard": "none",
			"lipstick": "none",
			"eyes": "1",
			"shoes": "1",
			"earrings": "none",
			"hats": "none",
			"glasses": "none",
			"clothes_down": "1",
			"clothes_up": "1",
			"clothes_complete": "none",
			"bodies": "1",
			"hair": "1"
		}

# Validate the save data to ensure it's not corrupted
func validate() -> bool:
	# Basic validation to ensure critical fields are present
	if player_speed <= 0 or player_gravity <= 0:
		return false
	
	# Check that outfit dictionary has expected keys
	var required_outfit_keys = [
		"beard", "lipstick", "eyes", "shoes", "earrings", 
		"hats", "glasses", "clothes_down", "clothes_up", 
		"clothes_complete", "bodies", "hair"
	]
	
	for key in required_outfit_keys:
		if not player_outfit.has(key):
			return false
	
	return true

# Create a dictionary representation of the save data for debug purposes
func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"save_date": save_date,
		"playtime_seconds": playtime_seconds,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"current_level": current_level,
		"active_scene_state": active_scene_state,
		"health": health,
		"coins": coins,
		"heaven_coins": heaven_coins,
		"player_speed": player_speed,
		"player_jump_velocity": player_jump_velocity,
		"player_fly_velocity": player_fly_velocity,
		"player_gravity": player_gravity,
		"player_mode": player_mode,
		"player_passed_fly_time": player_passed_fly_time,
		"player_jump_counter": player_jump_counter,
		"player_ready_for_jump": player_ready_for_jump,
		"player_allowed_jumps": player_allowed_jumps,
		"difficulty": difficulty,
		"coin_type": coin_type,
		"player_outfit": player_outfit,
		"collected_coins": collected_coins,
		"collected_heaven_coins": collected_heaven_coins,
		"unlocked_levels": unlocked_levels,
		"completed_quests": completed_quests,
		"message_history": message_history
	}

# Return a string representation for debugging
func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t")

# Update playtime
func update_playtime(seconds_to_add: int) -> void:
	playtime_seconds += seconds_to_add

# Get formatted playtime as string
func get_playtime_string() -> String:
	var hours = playtime_seconds / 3600
	var minutes = (playtime_seconds % 3600) / 60
	var seconds = playtime_seconds % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# Create a deep copy of this save data
func duplicate_data() -> SaveData:
	var new_data = SaveData.new()
	
	new_data.save_version = save_version
	new_data.save_date = save_date
	new_data.playtime_seconds = playtime_seconds
	new_data.player_position = player_position
	new_data.current_level = current_level
	new_data.active_scene_state = active_scene_state.duplicate(true)
	new_data.health = health
	new_data.coins = coins
	new_data.heaven_coins = heaven_coins
	new_data.player_speed = player_speed
	new_data.player_jump_velocity = player_jump_velocity
	new_data.player_fly_velocity = player_fly_velocity
	new_data.player_gravity = player_gravity
	new_data.player_mode = player_mode
	new_data.player_passed_fly_time = player_passed_fly_time
	new_data.player_jump_counter = player_jump_counter
	new_data.player_ready_for_jump = player_ready_for_jump
	new_data.player_allowed_jumps = player_allowed_jumps
	new_data.difficulty = difficulty
	new_data.coin_type = coin_type
	new_data.player_outfit = player_outfit.duplicate(true)
	new_data.collected_coins = collected_coins
	new_data.collected_heaven_coins = collected_heaven_coins
	new_data.unlocked_levels = unlocked_levels.duplicate()
	new_data.completed_quests = completed_quests.duplicate()
	new_data.message_history = message_history.duplicate(true)
	
	return new_data

# Create a new save with default values
static func create_new_save() -> SaveData:
	var save = SaveData.new()
	save.save_date = Time.get_datetime_string_from_system(false, true)
	return save
